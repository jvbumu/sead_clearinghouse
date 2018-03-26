# -*- coding: utf-8 -*-
import pandas as pd
from sqlalchemy import create_engine

# %%
class SchemaMetaRepository:

    def __init__(self, server='dataserver.humlab.umu.se', dbname='sead_master_8', port='5432', username='clearinghouse_worker', password='Vua9VagZ'):

        self.name = server.split('.')[0] + dbname
        self.connection_string = 'postgresql://{}:{}@{}:{}/{}'.format(username, password, server, port, dbname)
        self.sql = "\
        Select c.table_schema, c.table_name, c.column_name, c.ordinal_position, c.data_type, \
        c.numeric_precision, c.numeric_scale, c.character_maximum_length, c.is_nullable, Case When k.column_name Is Null Then 'NO' Else 'YES' End as is_pk \
        From information_schema.columns c\
        Left Join (\
            Select t.table_schema, t.table_name, kcu.column_name\
            From INFORMATION_SCHEMA.TABLES t \
            Left Join INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc \
              On tc.table_catalog = t.table_catalog \
              And tc.table_schema = t.table_schema \
              And tc.table_name = t.table_name \
              And tc.constraint_type = 'PRIMARY KEY' \
            Left Join INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu \
              On kcu.table_catalog = tc.table_catalog \
             And kcu.table_schema = tc.table_schema \
             And kcu.table_name = tc.table_name \
             And kcu.constraint_name = tc.constraint_name \
            Where t.table_schema NOT IN ('pg_catalog', 'information_schema', 'clearing_house') \
        ) as k \
          On k.table_schema = c.table_schema \
         And k.table_name = c.table_name \
         And k.column_name = c.column_name \
        Where 1 = 1 \
          And c.table_schema Not in ('information_schema', 'pg_catalog', 'clearing_house') \
        Order By 1,2,3; \
        "

    def connect(self):
        self.engine = create_engine(self.connection_string)
        return self

    def dispose(self):
        self.engine.dispose()
        self.engine = None
        return self

    def get_schema(self):
        return pd.read_sql_query(self.sql, con=self.engine)

    def load_query(self, sql):
        return pd.read_sql_query(sql, con=self.engine)

    def load_table(self, tablename, schema='clearing_house'):
        return pd.read_sql_table(tablename, con=self.engine, schema=schema)

    def save_table(self, df, tablename, replace=True):
        df.to_sql(tablename, self.engine, if_exists='replace' if replace else '')

# %%
repositories = [
    SchemaMetaRepository(server='dataserver.humlab.umu.se', dbname='sead_master_8', port='5432', username='clearinghouse_worker', password='Vua9VagZ'),
    SchemaMetaRepository(server='snares.humlab.umu.se', dbname='sead_master_8', port='5432', username='humlab_read', password='Vua9VagZ'),
    SchemaMetaRepository(server='snares.humlab.umu.se', dbname='sead_master_9', port='5432', username='humlab_read', password='Vua9VagZ'),
    SchemaMetaRepository(server='snares.humlab.umu.se', dbname='sead_master_schema', port='5432', username='humlab_read', password='Vua9VagZ')
]
# %%
target = repositories[0]
for repository in repositories:
    df = repository.connect().get_schema()
    target.save_table(df, 'tbl_clearinghouse_' + repository.name + '_rdb_schema_temp')

for repository in repositories:
    repository.dispose()
