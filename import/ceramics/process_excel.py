# -*- coding: utf-8 -*-
import os
import time
import pandas as pd
import numpy as np
import numbers
import io
import tidylib
import base64
import zlib
import logging
from functools import reduce

logger = logging.getLogger('Excel XML processor')

def setup_logger(filename):
    global logger
    '''
    Setup logging of import messages to both file and console
    '''
    logger.handlers = []

    logger.setLevel(logging.DEBUG)
    formatter = logging.Formatter('%(message)s')

    fh = logging.FileHandler(filename)
    fh.setLevel(logging.DEBUG)
    fh.setFormatter(formatter)
    logger.addHandler(fh)

    ch = logging.StreamHandler()
    ch.setLevel(logging.ERROR)
    ch.setFormatter(formatter)
    logger.addHandler(ch)

def flatten(l):
    '''
    Flattens a list of lists
    '''
    return [item for sublist in l for item in sublist]

def flatten_sets(x, y):
    '''
    Flattens a set of sets
    '''
    return set(list(x) + list(y))

'''
Import assumes that all FK references points to a local "system_id" in referenced table
All data tables MUST have a non null "system_id"
All data tables MUST have a PK column with a name equal to that specified in "Tables" meta-data PK-name field
'''
class MetaData:

    '''
    Logic related to meta-data read from Excel file
    '''
    def __init__(self):
        self.Tables = None
        self.Columns = None
        self.PrimaryKeys = None
        self.ForeignKeys = None
        self.ForeignKeyAliases = {
            'updated_dataset_id': 'dataset_id'
        }

    def load(self, filename):

        self.Tables = pd.read_excel(filename, 'Tables',
            dtype={
                'Table': 'str',
                'JavaClass': 'str',
                'Pk_NAME': 'str',
                'ExcelSheet': 'str',
                'OnlyNewData': 'str',
                'NewData': 'str',
                'Notes': 'str'
            })

        self.Columns = pd.read_excel(filename, 'Columns',
            dtype={
                'table_name': 'str',
                'column_name': 'str',
                # 'position': np.int32,
                'nullable': 'str',
                'type': 'str',
                # 'length': np.int32,
                # 'size': np.int32,
                'type2': 'str',
                'Class': 'str'
            })  # .set_index(['table_name', 'column_name'])

        self.Tables['table_name'] = self.Tables['Table']
        self.Tables = self.Tables.set_index('Table')
        self.Tables.loc[self.Tables.ExcelSheet == 'nan', 'ExcelSheet'] = self.Tables.loc[self.Tables.ExcelSheet == 'nan', 'table_name']
        self.Tables['OnlyNewData'] = self.Tables.OnlyNewData.str.upper()
        self.Tables['NewData'] = self.Tables.NewData.str.upper()

        self.PrimaryKeys = pd.merge(self.Tables, self.Columns, how='inner', left_on=['table_name', 'Pk_NAME'], right_on=['table_name', 'column_name'])[['table_name', 'column_name', 'JavaClass']]
        self.PrimaryKeys.columns = ['table_name', 'column_name', 'class_name']

        self.ForeignKeys = pd.merge(self.Columns, self.PrimaryKeys, how='inner', left_on=['column_name', 'Class'], right_on=['column_name', 'class_name'])[['table_name_x', 'table_name_y', 'column_name', 'class_name' ]]
        self.ForeignKeys = self.ForeignKeys[self.ForeignKeys.table_name_x != self.ForeignKeys.table_name_y]

        return self

    def tables_with_data(self):
        return self.Tables.loc[
            np.logical_or((self.Tables.OnlyNewData == 'YES'), (self.Tables.NewData == 'YES'))]['table_name'].values.tolist()

    def table_fields(self, table_name):
        return self.Columns[(self.Columns.table_name == table_name)]
#    def get_columns(self, table_name):
#        return self.Columns[(self.Columns.table_name == table_name)].to_dict()

    def table_exists(self, table_name):
        return table_name in self.Tables.table_name.values

    def get_table(self, table_name):
        return self.Tables.loc[table_name].to_dict()

    def get_tablename_by_classname(self, class_name):
        try:
            if '.' in class_name:
                class_name = class_name.split('.')[-1]
            return self.Tables.loc[(self.Tables.JavaClass == class_name)]['table_name'].iloc[0]
        except:
            return None

    def is_fk(self, table_name, column_name):
        return ((self.Tables.table_name != table_name) & (self.Tables.Pk_NAME == column_name)).any() \
            or (column_name in self.ForeignKeyAliases)

    def is_pk(self, table_name, column_name):
        return ((self.Tables.table_name == table_name) & (self.Tables.Pk_NAME == column_name)).any()

    def get_pk_name(self, table_name):
        try:
            return self.PrimaryKeys.loc[(self.PrimaryKeys.table_name == table_name)]['column_name'].iloc[0]
        except:
            return None

    def get_classname_by_tablename(self, table_name):
        return self.PrimaryKeys.loc[(self.PrimaryKeys.table_name == table_name)]['class_name'].iloc[0]

    def get_tablenames_referencing(self, table_name):
        return self.ForeignKeys.loc[(self.ForeignKeys.table_name_y == table_name)]['table_name_x'].tolist()

class DataImportError(Exception):
    '''
    Base class for other exceptions
    '''
    pass

class ValueData:

    '''
    Logic dealing with the data (load etc)
    '''
    def __init__(self, metaData):
        self.MetaData = metaData
        self.DataTables = None

    def load2(self, source):
        from openpyxl import load_workbook
        wb = load_workbook(source)  # , read_only=True)

        def load_sheet(sheet_name):
            df = None
            try:
                ws = wb.get_sheet_by_name(sheet_name)
                if ws is not None:
                    df = pd.DataFrame(ws.values)
                    logger.info('READ   ValueData: sheet={}'.format(sheet_name))
            except:
                pass
            return df

        self.DataTables = {
            x['table_name']: load_sheet(x['ExcelSheet']) for _, x in self.MetaData.Tables.iterrows()
        }
        self.update_system_id()
        return self

    def load(self, source):

        reader = pd.ExcelFile(source) if isinstance(source, str) else source

        def load_sheet(sheetname):
            df = None
            try:
                df = reader.parse(sheetname)
            except:
                pass
            logger.info('SHEET {}: {}'.format(sheetname, 'READ' if df is not None else 'FAILED'))
            return df

        self.DataTables = {
            x['table_name']: load_sheet(x['ExcelSheet']) for i, x in self.MetaData.Tables.iterrows()
        }
        reader.close()
        self.update_system_id()
        return self

    def store(self, filename):
        writer = pd.ExcelWriter(filename)
        for (table_name, df) in self.DataTables:
            df.to_excel(writer, table_name)  # , index=False)
        writer.save()
        return self

    def exists(self, table_name):
        return table_name in self.DataTables.keys()

    def has_data(self, table_name):
        return self.exists(table_name) and self.DataTables[table_name] is not None

    def has_system_id(self, table_name):
        return self.has_data(table_name) and 'system_id' in self.DataTables[table_name].columns

    def tables_with_data(self):
        return [ x for x in self.DataTables.keys() if self.has_data(x) ]

    def cast_table(self, table_name):
        data_table = self.ValueData.Tables[table_name]
        fields = self.MetaData.table_fields(table_name)
        for _, item in fields.iterrows():
            column = item.to_dict()
            if column['column_name'] in data_table.columns:
                if column['type'] in ['integer']:
                    self.ValueData.Tables[table_name].astype(np.int64)

    def update_system_id(self):

        for table_name in self.MetaData.tables_with_data():
            try:
                data_table = self.DataTables[table_name]
                table_definition = self.MetaData.get_table(table_name)

                pk_name = table_definition['Pk_NAME']

                if pk_name == 'ceramics_id':
                    pk_name = 'ceramic_id'

                if data_table is None or pk_name not in data_table.columns:
                    continue

                if 'system_id' not in data_table.columns:
                    raise DataImportError('CRITICAL ERROR Table {} has no column named "system_id"'.format(table_name))
                else:
                    data_table.loc[np.isnan(data_table.system_id), 'system_id'] = data_table.loc[np.isnan(data_table.system_id), pk_name]
            except DataImportError as _:
                logger.exception('update_system_id')
                continue
        return self

    def get_referenced_keyset(self, table_name):
        pk_name = self.MetaData.get_pk_name(table_name)
        if pk_name is None:
            return []
        ref_tablenames = self.MetaData.get_tablenames_referencing(table_name)
        sets_of_keys = [
            set(self.DataTables[foreign_name][pk_name].loc[~np.isnan(self.DataTables[foreign_name][pk_name])].tolist())
            for foreign_name in ref_tablenames if not self.DataTables[foreign_name] is None
        ]
        return reduce(flatten_sets, sets_of_keys or [], [])

class DataTableSpecification:

    '''
    Specification class that tests validity of data
    '''
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.ignore_columns = [ 'date_updated' ]

    def is_satisfied_by(self, data):

        self.errors = []
        self.warnings = []

        for table_name in data.MetaData.tables_with_data():
            self.is_satisfied_by_table(data, table_name)

        if len(self.warnings) > 0:
            logger.info("\n".join(self.warnings))

        if len(self.errors) > 0:
            logger.error("\n".join(self.errors))

        return len(self.errors) == 0

    def is_satisfied_by_table(self, data, table_name):

        try:
            # Must exist as data table in metadata
            if table_name not in data.tables_with_data():
                self.errors.append("{0} not defined as data table".format(table_name))

            # Must have a system identit
            if not data.has_system_id(table_name):
                self.errors.append("{0} has no system id data column".format(table_name))

            if not data.MetaData.table_exists(table_name):
                self.errors.append("{0} not found in meta data".format(table_name))

            if not data.has_data(table_name):
                self.errors.append("{0} has NO DATA!".format(table_name))

            # Verify that all fields in MetaFields exists DataTable.columns
            meta_column_names = sorted(data.MetaData.table_fields(table_name)['column_name'].values.tolist())
            data_column_names = sorted(data.DataTables[table_name].columns.values.tolist()) \
                if data.has_data(table_name) and data.MetaData.table_exists(table_name) else []

            missing_column_names = list(set(meta_column_names) - set(data_column_names) - set(self.ignore_columns))
            extra_column_names = list(set(data_column_names) - set(meta_column_names) - set(self.ignore_columns))

            if len(missing_column_names) > 0:
                self.errors.append("ERROR {0} has MISSING DATA columns: ".format(table_name) + (", ".join(missing_column_names)))

            if len(extra_column_names) > 0:
                self.warnings.append("WARNING {0} has EXTRA DATA columns: ".format(table_name) + (", ".join(extra_column_names)))

            data_table = data.DataTables[table_name]

            if data_table is not None:

                if 'system_id' not in data_table.columns:
                    self.errors.append('CRITICAL ERROR Table {} has no column named "system_id"'.format(table_name))

                pk_name = data.MetaData.get_pk_name(table_name)
                if pk_name not in data_table.columns:
                    self.errors.append('CRITICAL ERROR Table {} has no PK named "{}"'.format(table_name, pk_name))

                fields = data.MetaData.table_fields(table_name)
                type_compatibility_matrix = {
                    ('integer', 'float64'): True,
                    ('timestamp with time zone', 'float64'): False,
                    ('text', 'float64'): False,
                    ('character varying', 'float64'): False,
                    ('numeric', 'float64'): True,
                    ('timestamp without time zone', 'float64'): False,
                    ('boolean', 'float64'): False,
                    ('date', 'float64'): False,
                    ('smallint', 'float64'): True,
                    ('integer', 'object'): False,
                    ('timestamp with time zone', 'object'): True,
                    ('text', 'object'): True,
                    ('character varying', 'object'): True,
                    ('numeric', 'object'): False,
                    ('timestamp without time zone', 'object'): True,
                    ('boolean', 'object'): False,
                    ('date', 'object'): True,
                    ('smallint', 'object'): False,
                    ('integer', 'int64'): True,
                    ('timestamp with time zone', 'int64'): False,
                    ('text', 'int64'): False,
                    ('character varying', 'int64'): False,
                    ('numeric', 'int64'): True,
                    ('timestamp without time zone', 'int64'): False,
                    ('boolean', 'int64'): False,
                    ('date', 'int64'): False,
                    ('smallint', 'int64'): True,
                    ('timestamp with time zone', 'datetime64[ns]'): True,
                    ('date', 'datetime64[ns]'): True
                }

                for _, item in fields.loc[(~fields.column_name.isin(self.ignore_columns))].iterrows():
                    column = item.to_dict()
                    if column['column_name'] in data_table.columns:
                        data_column_type = data_table.dtypes[column['column_name']].name
                        if not type_compatibility_matrix[(column['type'], data_column_type)]:
                            self.warnings.append("WARNING Type clash: {}.{} {}<=>{}".format(table_name, column['column_name'], column['type'], data_column_type))

        except Exception as e:
            self.errors.append('Error occurred when validating {}: {}'.format(table_name, str(e)))

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
        date_updated = ''.format(time.strftime("%Y-%m-%d %H%M"))
        for table_name in table_names:
            try:

                referenced_keyset = set(data.get_referenced_keyset(table_name))

                logger.info("Processing %s...", table_name)

                data_table = data.DataTables[table_name]
                table_definition = data.MetaData.get_table(table_name)
                pk_name = table_definition['Pk_NAME']

                table_namespace = "com.sead.database.{}".format(table_definition['JavaClass'])

                if data_table is None:
                    continue

                self.emit('<{} length="{}">'.format(table_definition['JavaClass'], data_table.shape[0]), 1)  # data_table.length
                # self.emit_tag(table_definition['JavaClass'], dict(length=data_table.shape[0]), close=False, indent=1)

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

                            fields = data.MetaData.table_fields(table_name)
                            for _, item in fields.loc[(~fields.column_name.isin(self.ignore_columns))].iterrows():
                                column = item.to_dict()
                                column_name = column['column_name']
                                is_fk = data.MetaData.is_fk(table_name, column_name)
                                is_pk = data.MetaData.is_pk(table_name, column_name)
                                class_name = column['Class']

                                # TODO Move to Specification
                                if column_name[-3:] == '_id' and not (is_fk or is_pk):
                                    logger.warning('Table {}, FK? column {}: Column ending with _id not marked as PK/FK'.format(table_name, column_name))

                                # TODO Move to Specification
                                if column_name not in data_row.keys():
                                    logger.warning('Table {}, FK column {}: META field name not found in DATA'.format(table_name, column_name))
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
                                        if np.isnan(value):
                                            # CHANGE: Cannot allow id="NULL" as foreign key
                                            logger.error("Warning: table {}, id {} FK {} is NULL. Skipping property!".format(table_name, system_id, column_name))
                                            continue
                                        fk_system_id = int(value)
                                        fk_table_name = data.MetaData.get_tablename_by_classname(class_name)
                                        if fk_table_name is None:
                                            logger.warning('Table {}, FK column {}: unable to resolve FK class {}'.format(table_name, column_name, class_name))
                                            continue
                                        fk_data_table = data.DataTables[fk_table_name]

                                        if fk_data_table is None:
                                            fk_public_id = fk_system_id
                                        else:
                                            if column_name not in fk_data_table.columns:
                                                logger.warning('Table {}, FK column {}: FK column not found in {}, id={}'.format(table_name, column_name, fk_table_name, fk_system_id))
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
                                        logger.error('Table {}, id={}, process failed for column {}'.format(table_name, system_id, column_name))
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
                self.emit('</{}>'.format(table_definition['JavaClass']), 1)
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

    def process(self, data, tablenames=None, extranames=None):

        if not self.specification.is_satisfied_by(data):
            raise DataImportError("Process ABORTED since data does not conform to SPECIFICATION")

        tablenames = data.MetaData.tables_with_data() if tablenames is None else tablenames
        extranames = set(data.MetaData.Tables["table_name"].tolist()) - set(data.tables_with_data()) if extranames is None else extranames

        self.emit('<?xml version="1.0" ?>')
        self.emit('<sead-data-upload>')
        self.process_lookups(data, extranames)
        self.process_data(data, tablenames)
        self.emit('</sead-data-upload>')

class XmlDocumentService:

    def cleanUp(self, path, suffix='_tidy'):
        tidy_path = path[:-4] + '{}.xml'.format(suffix)
        with io.open(path, 'r', encoding='utf8') as instream:
            xml_document = instream.read()
        tidy_xml_document = tidylib.tidy_document(xml_document, {"input_xml": True})[0]
        with io.open(tidy_path, 'w', encoding='utf8') as outstream:
            outstream.write(tidy_xml_document)

    def compress_and_encode(self, path):

        compressed_data = zlib.compress(path.encode('utf8'))
        encoded = base64.b64encode(compressed_data)
        uue_filename = path + '.gz.uue'
        with io.open(uue_filename, 'wb') as outstream:
            outstream.write(encoded)

        gz_filename = path + '.gz'
        with io.open(gz_filename, 'wb') as outstream:
            outstream.write(compressed_data)


source_folder = "C:\\Users\\roma0050\\Google Drive\\Project\\Projects\\VISEAD (Humlab)\\SEAD Ceramics & Dendro"

options = [

    # dict(
    #     input_folder=os.path.join(source_folder, 'Dendro import'),
    #     output_folder=os.path.join(source_folder, 'output'),
    #     meta_filename='table metadata BUILD DENDRO.xlsx',
    #     data_filename='01_BYGG_20180608.xlsm'
    # ),

    dict(
        input_folder=os.path.join(source_folder, 'Dendro import'),
        output_folder=os.path.join(source_folder, 'output'),
        meta_filename='table metadata ARKEO DENDRO.xlsx',
        data_filename='02_Ark_dendro_20180608.xlsm'
    ),

    # dict(
    #     input_folder=os.path.join(source_folder, 'Ceramics import'),
    #     output_folder=os.path.join(source_folder, 'output'),
    #     meta_filename='table_metadata_20180608.xlsx',
    #     data_filename='tunnslipstabell - in progress 20180608.xlsm'
    # )

]

if __name__ == "__main__":

    for option in options:

        try:
            basename = os.path.splitext(option['data_filename'])[0]
            timestamp = time.strftime("%Y%m%d-%H%M%S")

            meta_filename = os.path.join(option['input_folder'], option['meta_filename'])
            data_filename = os.path.join(option['input_folder'], option['data_filename'])
            log_filename = os.path.join(option['output_folder'], '{}_{}.log'.format(basename, timestamp))
            output_filename = os.path.join(option['output_folder'], '{}_{}.xml'.format(basename, timestamp))

            setup_logger(log_filename)

            logger.info('PROCESS OF %s STARTED', basename)

            meta_data = MetaData().load(meta_filename)

            data = ValueData(meta_data).load(data_filename)

            with io.open(output_filename, 'w', encoding='utf8') as outstream:

                XmlProcessor(outstream).process(data)

            XmlDocumentService().cleanUp(output_filename)
        except:
            logger.exception('ABORTED CRITICAL ERROR %s ', basename)
