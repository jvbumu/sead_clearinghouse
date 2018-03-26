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

def create_logger(filename):
    '''
    Setup logging of import messages to both file and console
    '''
    logger = logging.getLogger('XML processor')
    logger.setLevel(logging.DEBUG)
    formatter = logging.Formatter('%(message)s')
    fh = logging.FileHandler(filename + '.log')
    fh.setLevel(logging.DEBUG)
    fh.setFormatter(formatter)
    logger.addHandler(fh)

    ch = logging.StreamHandler()
    ch.setLevel(logging.ERROR)
    ch.setFormatter(formatter)
    logger.addHandler(ch)
    return logger

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

class MetaData:

    '''
    Logic related to meta-data read from Excel file
    '''
    def __init__(self, logger):
        self.logger = logger
        self.Tables = None
        self.Columns = None
        self.PrimaryKeys = None
        self.ForeignKeys = None

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

        self.PrimaryKeys = pd.merge(self.Tables, self.Columns, how='inner', left_on=['table_name', 'Pk_NAME'], right_on=['table_name', 'column_name'])[['table_name', 'column_name', 'JavaClass']]
        self.PrimaryKeys.columns = ['table_name', 'column_name', 'class_name']

        self.ForeignKeys = pd.merge(self.Columns, self.PrimaryKeys, how='inner', left_on=['column_name', 'Class'], right_on=['column_name', 'class_name'])[['table_name_x', 'table_name_y', 'column_name', 'class_name' ]]
        self.ForeignKeys = self.ForeignKeys[self.ForeignKeys.table_name_x != self.ForeignKeys.table_name_y]

        return self

    def tables_with_data(self):
        return self.Tables.loc[
            np.logical_or((self.Tables.OnlyNewData == 'Yes'),
                          (self.Tables.NewData == 'Yes'))]['table_name'].values.tolist()

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
        return((self.Tables.table_name != table_name) & (self.Tables.Pk_NAME == column_name)).any()

    def is_pk(self, table_name, column_name):
        return((self.Tables.table_name == table_name) & (self.Tables.Pk_NAME == column_name)).any()

    def get_pk_name(self, table_name):
        try:
            return self.PrimaryKeys.loc[(metaData.PrimaryKeys.table_name == table_name)]['column_name'].iloc[0]
        except:
            return None

    def get_classname_by_tablename(self, table_name):
        return self.PrimaryKeys.loc[(metaData.PrimaryKeys.table_name == table_name)]['class_name'].iloc[0]

    def get_tablenames_referencing(self, table_name):
        return self.ForeignKeys.loc[(self.ForeignKeys.table_name_y == table_name)]['table_name_x'].tolist()

class CeramicData:

    '''
    Logic dealing with the ceramic data (load etc)
    '''
    def __init__(self, metaData, logger):
        self.MetaData = metaData
        self.logger = logger
        self.DataTables = None

    def load(self, source):
        reader = pd.ExcelFile(source) if isinstance(source, str) else source
        self.DataTables = {
            x['table_name']: self.parse(reader, x['table_name'], x['ExcelSheet'])
            for i, x in self.MetaData.Tables.iterrows()
        }
        reader.close()
        return self

    def store(self, filename):
        writer = pd.ExcelWriter(filename)
        for (table_name, df) in self.DataTables:
            df.to_excel(writer, table_name)  # , index=False)
        writer.save()
        return self

    def parse(self, reader, table_name, sheetname):
        try:
            table = reader.parse(sheetname)  # .set_index('system_id')
            self.logger.info('READ   CeramicData: table_name={} sheet={}'.format(table_name, sheetname))
            return table
        except:
            self.logger.info('FAILED CeramicData: table_name={0} {1}'.format(table_name, sheetname if sheetname != table_name else ''))
            return None

    def exists(self, table_name):
        return table_name in self.DataTables.keys()

    def has_data(self, table_name):
        return self.exists(table_name) and self.DataTables[table_name] is not None

    def has_system_id(self, table_name):
        return self.has_data(table_name) and 'system_id' in self.DataTables[table_name].columns

    def tables_with_data(self):
        return [ x for x in self.DataTables.keys() if self.has_data(x) ]

    def cast_table(self, table_name):
        dataTable = self.CeramicData.Tables[table_name]
        fields = self.MetaData.table_fields(table_name)
        for _, item in fields.iterrows():
            column = item.to_dict()
            if column['column_name'] in dataTable.columns:
                if column['type'] in ['integer']:
                    self.CeramicData.Tables[table_name].astype(np.int64)

    def update_system_id(self):

        for table_name in self.MetaData.tables_with_data():

            dataTable = self.DataTables[table_name]
            metaTable = self.MetaData.get_table(table_name)
            pkName = metaTable['Pk_NAME']

            if pkName == 'ceramics_id':
                pkName = 'ceramic_id'
            if dataTable is None or pkName not in dataTable.columns:
                continue

            dataTable.loc[np.isnan(dataTable.system_id), 'system_id'] = dataTable.loc[np.isnan(dataTable.system_id), pkName]
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
    def __init__(self, logger):
        self.logger = logger

    def is_satisfied_by(self, metaData, ceramicData):
        for table_name in metaData.tables_with_data():
            self.is_satisfied_by_table(metaData, ceramicData, table_name)

    def is_satisfied_by_table(self, metaData, ceramicData, table_name):

        errors = []
        try:
            # Must exist as data table in metadata
            if table_name not in ceramicData.tables_with_data():
                errors.append("{0} not defined as data table".format(table_name))

            # Must have a system identit
            if not ceramicData.has_system_id(table_name):
                errors.append("{0} has no system id data column".format(table_name))

            if not metaData.table_exists(table_name):
                errors.append("{0} not found in meta data".format(table_name))

            if not ceramicData.has_data(table_name):
                errors.append("{0} has NO DATA!".format(table_name))

            # Verify that all fields in MetaFields exists DataTable.columns
            meta_column_names = metaData.table_fields(table_name)['column_name'].values.tolist()
            data_column_names = ceramicData.DataTables[table_name].columns.values.tolist() \
                if ceramicData.has_data(table_name) and metaData.table_exists(table_name) else []
            diff_column_names = list(set(meta_column_names) - set(data_column_names))
            # diff_columns = set(meta_columns).symmetric_difference(set(data_columns))
            if len(diff_column_names) > 0:
                errors.append("{0} missing columns: ".format(table_name) + (", ".join(diff_column_names)))
                errors.append(" {0} found META columns: ".format(table_name) + (", ".join(meta_column_names)))
                errors.append(" {0} found DATA columns: ".format(table_name) + (", ".join(data_column_names)))

            # TODO Verify column types...
            dataTable = ceramicData.DataTables[table_name]

            if dataTable is not None:
                fields = metaData.table_fields(table_name)
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

                for index, item in fields.loc[(fields.column_name != 'date_updated')].iterrows():
                    column = item.to_dict()
                    if column['column_name'] in dataTable.columns:
                        data_column_type = dataTable.dtypes[column['column_name']].name
                        if not type_compatibility_matrix[(column['type'], data_column_type)]:
                            errors.append("Type clash: {}.{} {}<=>{}".format(table_name, column['column_name'], column['type'], data_column_type))

                #  Verify correctnes of value (DataRecord[MetaField.column_name]) in current field in DataRecord
                #  Value is of valid size / length
                #  Value is not null if MetaField.Null == 'NO'
                # (Assumes all FK references points to local system ID)

            # Return failure in case of errors
            if len(errors) > 0:
                self.logger.info("\n".join(errors))
                return False

            return True
        except Exception as x:
            self.logger.error(x)
            raise
            return False

class XmlProcessor:
    '''
    Main class that processes the Excel file and produces a corresponging XML-file.
    The format of the XML-file is conforms to clearinghouse specifications
    '''
    def __init__(self, outstream, logger=None, level=logging.WARNING):
        self.outstream = outstream
        self.logger = logger
        self.level = level

    def emit(self, data, indent=0):
        self.outstream.write('{}{}\n'.format('  ' * indent, data))

#    def property_tag(self, tag, is_fk, class_name, value, clonedId=np.NaN):
#        if not is_fk:
#            return '<{0} class="{1}">{2}</{0}>'.format(tag, class_name, value)
#        if np.isnan(clonedId):
#            return '<{} class="com.sead.database.{}" id="{}"/>'.format(tag, class_name, int(value))
#        return '<{} class="com.sead.database.{}" id="{}" clonedId="{}"/>'.format(tag, class_name, int(value), int(clonedId))

    def camel_case_name(self, undescore_name):
        first, *rest = undescore_name.split('_')
        return first + ''.join(word.capitalize() for word in rest)

    def process_data(self, metaData, ceramicData, table_names, max_rows=0):
        date_updated = ''.format(time.strftime("%Y-%m-%d %H%M"))
        for table_name in table_names:
            try:

                referenced_keyset = set(ceramicData.get_referenced_keyset(table_name))

                self.logger.info("Processing {}...".format(table_name))

                dataTable = ceramicData.DataTables[table_name]
                metaTable = metaData.get_table(table_name)
                pkName = metaTable['Pk_NAME']

                if dataTable is None:
                    continue

                self.emit('<{} length="{}">'.format(metaTable['JavaClass'], dataTable.shape[0]), 1)  # dataTable.length

                for index, item in dataTable.iterrows():

                    try:

                        dataRow = item.to_dict()
                        clonedId = dataRow[pkName] if pkName in dataRow else np.NAN
                        systemId = int(dataRow['system_id'] if not np.isnan(dataRow['system_id']) else clonedId)
                        referenced_keyset.discard(systemId)

                        assert not (np.isnan(clonedId) and np.isnan(systemId))

                        if not np.isnan(clonedId):
                            clonedId = int(clonedId)
                            self.emit('<com.sead.database.{} id="{}" clonedId="{}"/>'.format(metaTable['JavaClass'], systemId, clonedId), 2)
                        else:
                            self.emit('<com.sead.database.{} id="{}">'.format(metaTable['JavaClass'], systemId), 2)

                            fields = metaData.table_fields(table_name)
                            for index2, item in fields.loc[(fields.column_name != 'date_updated')].iterrows():
                                column = item.to_dict()
                                column_name = column['column_name']
                                is_fk = metaData.is_fk(table_name, column_name)
                                is_pk = metaData.is_pk(table_name, column_name)
                                class_name = column['Class']

                                if column_name[-3:] == '_id' and not (is_fk or is_pk):
                                    self.logger.warning('Table {}, FK? column {}: Column ending with _id not marked as PK/FK'.format(table_name, column_name))

                                if column_name not in dataRow.keys():
                                    self.logger.warning('Table {}, FK column {}: META field name not found in DATA'.format(table_name, column_name))
                                    continue

                                camel_case_column_name = self.camel_case_name(column_name)
                                value = dataRow[column_name]
                                if not is_fk:
                                    if is_pk:
                                        value = int(clonedId) if not np.isnan(clonedId) else systemId
                                    elif isinstance(value, numbers.Number) and np.isnan(value):
                                        value = 'NULL'
                                    self.emit('<{0} class="{1}">{2}</{0}>'.format(camel_case_column_name, class_name, value), 3)
                                else:  # value is a fk system_id
                                    try:
                                        if np.isnan(value):
                                            # CHANGE: Cannot allow id="NULL" as foreign key
                                            self.logger.error("Warning: table {}, id {} FK {} is NULL. Skipping property!".format(table_name, systemId, column_name))
                                            continue
                                        fkSystemId = int(value)
                                        fkTablename = metaData.get_tablename_by_classname(class_name)
                                        if fkTablename is None:
                                            self.warning.info('Table {}, FK column {}: unable to resolve FK class {}'.format(table_name, column_name, class_name))
                                            continue
                                        fkDataTable = ceramicData.DataTables[fkTablename]

                                        if fkDataTable is None:
                                            fkClonedId = fkSystemId
                                        else:
                                            if column_name not in fkDataTable.columns:
                                                self.logger.warning('Table {}, FK column {}: FK column not found in {}, id={}'.format(table_name, column_name, fkTablename, fkSystemId))
                                                continue
                                            fkDataRow = fkDataTable.loc[(fkDataTable.system_id == fkSystemId)]
                                            if fkDataRow.empty or len(fkDataRow) != 1:
                                                fkClonedId = fkSystemId
                                            else:
                                                fkClonedId = fkDataRow[column_name].iloc[0]

                                        class_name = class_name.split('.')[-1]

                                        if np.isnan(fkClonedId):
                                            self.emit('<{} class="com.sead.database.{}" id="{}"/>'.format(camel_case_column_name, class_name, fkSystemId), 3)
                                        else:
                                            self.emit('<{} class="com.sead.database.{}" id="{}" clonedId="{}"/>'.format(camel_case_column_name, class_name, int(fkSystemId), int(fkClonedId)), 3)

                                    except:
                                        self.logger.error('Table {}, id={}, process failed for column {}'.format(table_name, systemId, column_name))
                                        raise

                            # ClonedId tag is always emitted (NULL id missing)
                            self.emit('<clonedId class="java.util.Integer">{}</clonedId>'.format('NULL' if np.isnan(clonedId) else int(clonedId)), 3)
                            self.emit('<dateUpdated class="java.util.Date">{}</dateUpdated>'.format(date_updated), 3)
                            self.emit('</com.sead.database.{}>'.format(metaTable['JavaClass']), 2)

                            if max_rows > 0 and index > max_rows:
                                break

                    except Exception as x:
                        self.logger.error('Critical failure: table {} {}'.format(table_name, x))
                        raise

                if len(referenced_keyset) > 0 and max_rows == 0:
                    self.logger.warning('Warning: {} has {} ref''d keys not found in data'.format(table_name, len(referenced_keyset)))
                    class_name = metaData.get_classname_by_tablename(table_name)
                    for key in referenced_keyset:
                        self.emit('<com.sead.database.{} id="{}" clonedId="{}"/>'.format(class_name, int(key), int(key)), 2)
                self.emit('</{}>'.format(metaTable['JavaClass']), 1)
            except:
                raise
                pass
                continue

    def process_lookups(self, metaData, ceramicData, table_names):

        for table_name in table_names:

            referenced_keyset = set(ceramicData.get_referenced_keyset(table_name))

            if len(referenced_keyset) == 0:
                self.logger.info("Skipping {}: not referenced".format(table_name))
                continue

            class_name = metaData.get_classname_by_tablename(table_name)
            rows = list(map(lambda x: '<com.sead.database.{} id="{}" clonedId="{}"/>'.format(class_name, int(x), int(x)), referenced_keyset))
            xml = '<{} length="{}">\n    {}\n</{}>\n'.format(class_name, len(rows), "\n    ".join(rows), class_name)

            self.emit(xml)

    def process(self, metaData, ceramicData, tablenames=None, extranames=None):
        tablenames = metaData.tables_with_data() if tablenames is None else tablenames
        extranames = set(metaData.Tables["table_name"].tolist()) - set(ceramicData.tables_with_data()) if extranames is None else extranames
        self.emit('<?xml version="1.0" ?>')
        self.emit('<sead-data-upload>')
        self.process_lookups(metaData, ceramicData, extranames)
        self.process_data(metaData, ceramicData, tablenames)
        self.emit('</sead-data-upload>')

class XmlDocumentService:

    def cleanUp(self, path, suffix='_tidy'):
        tidy_path = path[:-4] + '_tidy.xml'
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


if __name__ == "__main__":

    ''' Run time settings i.e. data filenames '''
    data_folder = "C:/Users/roma0050/Google Drive/Project/Projects/VISEAD (Humlab)/Shared/SEAD Ceramics & Dendro"
    meta_data_filename = os.path.join(data_folder, 'input', 'table metadata3.xlsx')
    ceramic_data_filename = os.path.join(data_folder, 'input', 'tunnslipstabell - in progress 20190315.xlsm')

    ''' Output data filename '''
    filename = os.path.join(data_folder, './output/ceramics_{}.xml'.format(time.strftime("%Y%m%d-%H%M%S")))
    logger = create_logger(filename)

    reader = pd.ExcelFile(ceramic_data_filename)

    metaData = MetaData(logger).load(meta_data_filename)
    ceramicData = CeramicData(metaData, logger).load(reader).update_system_id()

    DataTableSpecification(logger).is_satisfied_by(metaData, ceramicData)

    with io.open(filename, 'w', encoding='utf8') as outstream:

        XmlProcessor(outstream, logger).process(metaData, ceramicData)

    XmlDocumentService().cleanUp(filename)
