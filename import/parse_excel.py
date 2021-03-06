# -*- coding: utf-8 -*-
import os
import time
import numpy as np
import numbers
import io
import logging

from utility import tidy_xml, setup_logger # pylint: disable=E0401

logger = logging.getLogger('Excel XML processor')
setup_logger(logger)

from specification import DataTableSpecification # pylint: disable=E0401
from model import ValueData, MetaData, DataImportError # pylint: disable=E0401

jj = os.path.join

class XmlProcessor:
    '''
    Main class that processes the Excel file and produces a corresponging XML-file.
    The format of the XML-file is conforms to clearinghouse specifications
    '''
    def __init__(self, outstream, level=logging.WARNING):
        self.outstream = outstream
        self.level = level
        self.specification = DataTableSpecification()
        self.ignore_columns = self.specification.ignore_columns

    def emit(self, data, indent=0):
        self.outstream.write('{}{}\n'.format('  ' * indent, data))

    def emit_tag(self, tag, attributes=None, indent=0, close=True):
        self.emit('<{} {}{}>'.format(tag, ' '.join([ '{}="{}"'.format(x, y) for (x, y) in (attributes or {}).items() ]), '/' if close else ''), indent)

    def emit_close_tag(self, tag, indent):
        self.emit('</{}>'.format(tag), indent)

    def camel_case_name(self, undescore_name):
        first, *rest = undescore_name.split('_')
        return first + ''.join(word.capitalize() for word in rest)

    def process_data(self, data, table_names, max_rows=0):
        '''
        Import assumes that all FK references points to a local "system_id" in referenced table
        All data tables MUST have a non null "system_id"
        All data tables MUST have a PK column with a name equal to that specified in "Tables" meta-data PK-name field
        '''
        date_updated = ''.format(time.strftime("%Y-%m-%d %H%M")) # pylint: disable=E1305
        for table_name in table_names:
            try:

                referenced_keyset = set(data.get_referenced_keyset(table_name))

                logger.info("Processing %s...", table_name)

                data_table = data.DataTables[table_name]
                table_definition = data.MetaData.get_table(table_name)
                pk_name = table_definition['pk_name']

                table_namespace = "com.sead.database.{}".format(table_definition['java_class'])

                if data_table is None:
                    continue

                self.emit('<{} length="{}">'.format(table_definition['java_class'], data_table.shape[0]), 1)  # data_table.length
                # self.emit_tag(table_definition['java_class'], dict(length=data_table.shape[0]), close=False, indent=1)

                fields = data.MetaData.table_fields(table_name)

                for index, item in data_table.iterrows():

                    try:

                        data_row = item.to_dict()
                        public_id = data_row[pk_name] if pk_name in data_row else np.NAN

                        if np.isnan(public_id) and np.isnan(data_row['system_id']):
                            logger.warning('Table %s: Skipping row since both CloneId and SystemID is NULL', table_name)
                            continue

                        system_id = int(data_row['system_id'] if not np.isnan(data_row['system_id']) else public_id)

                        referenced_keyset.discard(system_id)

                        assert not (np.isnan(public_id) and np.isnan(system_id))

                        if not np.isnan(public_id):
                            public_id = int(public_id)
                            self.emit('<{} id="{}" clonedId="{}"/>'.format(table_namespace, system_id, public_id), 2)
                        else:
                            self.emit('<{} id="{}">'.format(table_namespace, system_id), 2)

                            for _, item in fields.loc[(~fields.column_name.isin(self.ignore_columns))].iterrows():
                                column = item.to_dict()
                                column_name = column['column_name']
                                is_fk = data.MetaData.is_fk(table_name, column_name)
                                is_pk = data.MetaData.is_pk(table_name, column_name)
                                class_name = column['class']

                                # TODO Move to Specification
                                if column_name[-3:] == '_id' and not (is_fk or is_pk):
                                    logger.warning('Table %s, FK? column %s: Column ending with _id not marked as PK/FK', table_name, column_name)

                                # TODO Move to Specification
                                if column_name not in data_row.keys():
                                    logger.warning('Table %s, FK column %s: META field name not found in DATA', table_name, column_name)
                                    continue

                                camel_case_column_name = self.camel_case_name(column_name)
                                value = data_row[column_name]
                                if not is_fk:
                                    if is_pk:
                                        value = int(public_id) if not np.isnan(public_id) else system_id
                                    elif isinstance(value, numbers.Number) and np.isnan(value):
                                        value = 'NULL'
                                    self.emit('<{0} class="{1}">{2}</{0}>'.format(camel_case_column_name, class_name, value), 3)
                                else:  # value is a fk system_id
                                    try:

                                        fk_table_name = data.MetaData.get_tablename_by_classname(class_name)
                                        if fk_table_name is None:
                                            logger.warning('Table %s, FK column %s: unable to resolve FK class %s', table_name, column_name, class_name)
                                            continue

                                        fk_data_table = data.DataTables[fk_table_name]

                                        if np.isnan(value):
                                            # CHANGE: Cannot allow id="NULL" as foreign key
                                            # logger.error("Warning: table {}, id {} FK {} is NULL. Skipping property!".format(table_name, system_id, column_name))
                                            self.emit('<{} class="com.sead.database.{}" id="NULL"/>'.format(camel_case_column_name, class_name), 3)
                                            continue

                                        fk_system_id = int(value)
                                        if fk_data_table is None:
                                            fk_public_id = fk_system_id
                                        else:
                                            if column_name not in fk_data_table.columns:
                                                logger.warning('Table %s, FK column %s: FK column not found in %s, id=%s', table_name, column_name, fk_table_name, fk_system_id)
                                                continue
                                            #if 'system_id' not in fk_data_table.columns:
                                            #    logger.error('FATAL ERROR while processing {}. FK table {} has not "system_id" column'.format(table_name, fk_table_name))
                                            fk_data_row = fk_data_table.loc[(fk_data_table.system_id == fk_system_id)]
                                            if fk_data_row.empty or len(fk_data_row) != 1:
                                                fk_public_id = fk_system_id
                                            else:
                                                fk_public_id = fk_data_row[column_name].iloc[0]

                                        class_name = class_name.split('.')[-1]

                                        if np.isnan(fk_public_id):
                                            self.emit('<{} class="com.sead.database.{}" id="{}"/>'.format(camel_case_column_name, class_name, fk_system_id), 3)
                                        else:
                                            self.emit('<{} class="com.sead.database.{}" id="{}" clonedId="{}"/>'.format(camel_case_column_name, class_name, int(fk_system_id), int(fk_public_id)), 3)

                                    except:
                                        logger.error('Table %s, id=%s, process failed for column %s', table_name, system_id, column_name)
                                        raise

                            # ClonedId tag is always emitted (NULL id missing)
                            self.emit('<clonedId class="java.util.Integer">{}</clonedId>'.format('NULL' if np.isnan(public_id) else int(public_id)), 3)
                            self.emit('<dateUpdated class="java.util.Date">{}</dateUpdated>'.format(date_updated), 3)
                            self.emit('</{}>'.format(table_namespace), 2)

                            if max_rows > 0 and index > max_rows:
                                break

                    except Exception as x:
                        logger.error('CRITICAL FAILURE: Table %s %s', table_name, x)
                        raise

                if len(referenced_keyset) > 0 and max_rows == 0:
                    logger.warning('Warning: %s has %s referenced keys not found in data', table_name, len(referenced_keyset))
                    class_name = data.MetaData.get_classname_by_tablename(table_name)
                    for key in referenced_keyset:
                        self.emit('<com.sead.database.{} id="{}" clonedId="{}"/>'.format(class_name, int(key), int(key)), 2)
                self.emit('</{}>'.format(table_definition['java_class']), 1)

            except:
                logger.exception('CRITICAL ERROR')
                raise

    def process_lookups(self, data, table_names):

        for table_name in table_names:

            referenced_keyset = set(data.get_referenced_keyset(table_name))

            if len(referenced_keyset) == 0:
                logger.info("Skipping %s: not referenced", table_name)
                continue

            class_name = data.MetaData.get_classname_by_tablename(table_name)
            rows = list(map(lambda x: '<com.sead.database.{} id="{}" clonedId="{}"/>'.format(class_name, int(x), int(x)), referenced_keyset))
            xml = '<{} length="{}">\n    {}\n</{}>\n'.format(class_name, len(rows), "\n    ".join(rows), class_name)

            self.emit(xml)

    def process(self, data, table_names=None, extra_names=None):

        self.specification.is_satisfied_by(data)

        if len(self.specification.warnings) > 0:
            logger.info("\n".join(self.specification.warnings))

        if len(self.specification.errors) > 0:
            logger.error("\n".join(self.specification.errors))
            raise DataImportError("Process ABORTED since data does not conform to SPECIFICATION")

        data_tablenames = data.data_tablenames if table_names is None else table_names
        extra_names = set(data.MetaData.tablenames) - set(data.tablenames) if extra_names is None else extra_names

        self.emit('<?xml version="1.0" ?>')
        self.emit('<sead-data-upload>')
        self.process_lookups(data, extra_names)
        self.process_data(data, data_tablenames)
        self.emit('</sead-data-upload>')

def process_excel_to_xml(option, basename, timestamp):
    '''
    Reads Excel files and convert content to an CH XML-file.
    Stores data in output_filename and returns filename for a cleaned up version of the XML
    '''
    meta_filename = jj(option['input_folder'], option['meta_filename'])
    data_filename = jj(option['input_folder'], option['data_filename'])
    output_filename = jj(option['output_folder'], '{}_{}.xml'.format(basename, timestamp))

    meta_data = MetaData().load(meta_filename)

    data = ValueData(meta_data).load(data_filename)

    with io.open(output_filename, 'w', encoding='utf8') as outstream:
        service = XmlProcessor(outstream)
        service.process(data, option['table_names'])

    tidy_output_filename = tidy_xml(output_filename)

    if tidy_output_filename != output_filename:
        os.remove(output_filename)

    return tidy_output_filename

