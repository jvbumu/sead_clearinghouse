-- Drop Function If Exists clearing_house.fn_dba_get_sead_public_db_schema(text, text);

/*********************************************************************************************************************************
**  Function    fn_dba_get_sead_public_db_schema
**  When        2013-10-18
**  What        Retrieves SEAD public db schema catalog
**  Who         Roger Mähler
**  Uses        INFORMATION_SCHEMA.catalog in SEAD production
**  Used By     Clearing House installation. DBA.
**  Revisions   2018-06-23 Major rewrite using pg_xxx tables for faster performance and FK inclusion
**********************************************************************************************************************************/
-- select * from clearing_house.fn_dba_get_sead_public_db_schema('public')
CREATE OR REPLACE FUNCTION clearing_house.fn_dba_get_sead_public_db_schema(p_schema_name text default 'public', p_owner text default 'sead_master')
    RETURNS TABLE (
        table_schema information_schema.sql_identifier,
        table_name information_schema.sql_identifier,
        column_name information_schema.sql_identifier,
        ordinal_position information_schema.cardinal_number,
        data_type information_schema.character_data,
        numeric_precision information_schema.cardinal_number,
        numeric_scale information_schema.cardinal_number,
        character_maximum_length information_schema.cardinal_number,
        is_nullable information_schema.yes_or_no,
        is_pk information_schema.yes_or_no,
        is_fk information_schema.yes_or_no,
        fk_table_name information_schema.sql_identifier,
        fk_column_name information_schema.sql_identifier
    ) LANGUAGE 'plpgsql'
    AS $BODY$
    Begin
        Return Query
        WITH fk_constraint AS (
            SELECT DISTINCT fk.conrelid, fk.confrelid, fk.conkey,
                    fk.confrelid::regclass::information_schema.sql_identifier AS fk_table_name,
                    fkc.attname::information_schema.sql_identifier as fk_column_name
            FROM pg_constraint AS fk
            JOIN pg_attribute fkc
            ON fkc.attrelid = fk.confrelid
            AND fkc.attnum = fk.confkey[1]
            WHERE fk.contype = 'f'::"char"
        )
            SELECT  pg_tables.schemaname::information_schema.sql_identifier AS table_schema,
                pg_tables.tablename::information_schema.sql_identifier AS table_name,
                pg_attribute.attname::information_schema.sql_identifier AS column_name,
                pg_attribute.attnum::information_schema.cardinal_number AS ordinal_position,
                format_type(pg_attribute.atttypid, NULL)::information_schema.character_data AS data_type,
                CASE pg_attribute.atttypid
                    WHEN 21 /*int2*/ THEN 16
                    WHEN 23 /*int4*/ THEN 32
                    WHEN 20 /*int8*/ THEN 64
                    WHEN 1700 /*numeric*/ THEN
                        CASE WHEN pg_attribute.atttypmod = -1
                            THEN null
                            ELSE ((pg_attribute.atttypmod - 4) >> 16) & 65535     -- calculate the precision
                            END
                    WHEN 700 /*float4*/ THEN 24 /*FLT_MANT_DIG*/
                    WHEN 701 /*float8*/ THEN 53 /*DBL_MANT_DIG*/
                    ELSE null
                END::information_schema.cardinal_number AS numeric_precision,
                CASE
                WHEN pg_attribute.atttypid IN (21, 23, 20) THEN 0
                WHEN pg_attribute.atttypid IN (1700) THEN
                    CASE
                        WHEN pg_attribute.atttypmod = -1 THEN null
                        ELSE (pg_attribute.atttypmod - 4) & 65535            -- calculate the scale
                    END
                ELSE null
                END::information_schema.cardinal_number AS numeric_scale,
                CASE WHEN pg_attribute.atttypid NOT IN (1042,1043) OR pg_attribute.atttypmod = -1 THEN NULL
                    ELSE pg_attribute.atttypmod - 4 END::information_schema.cardinal_number AS character_maximum_length,
                CASE pg_attribute.attnotnull WHEN false THEN 'YES' ELSE 'NO' END::information_schema.yes_or_no AS is_nullable,
                CASE WHEN pk.contype Is Null Then 'NO' Else 'YES' End::information_schema.yes_or_no AS is_pk,
                CASE WHEN fk.conrelid Is Null Then 'NO' Else 'YES' End::information_schema.yes_or_no AS is_fk,
                fk.fk_table_name,
                fk.fk_column_name
        FROM pg_tables
        JOIN pg_class
          ON pg_class.relname = pg_tables.tablename
        JOIN pg_namespace ns
          ON ns.oid = pg_class.relnamespace
         AND ns.nspname  = pg_tables.schemaname
        JOIN pg_attribute
          ON pg_class.oid = pg_attribute.attrelid
         AND pg_attribute.attnum > 0
        LEFT JOIN pg_constraint pk
          ON pk.contype = 'p'::"char"
         AND pk.conrelid = pg_class.oid
         AND (pg_attribute.attnum = ANY (pk.conkey))
        LEFT JOIN fk_constraint AS fk
          ON fk.conrelid = pg_class.oid
         AND (pg_attribute.attnum = ANY (fk.conkey))
        WHERE TRUE
          AND pg_tables.tableowner = p_owner
          AND pg_attribute.atttypid <> 0::oid
          AND pg_tables.schemaname = p_schema_name
        ORDER BY table_name, ordinal_position ASC;
End
$BODY$;
/*********************************************************************************************************************************
**  View        view_clearinghouse_sead_rdb_schema_pk_columns
**  When        2013-10-18
**  What        Returns PK column name for RDB tables
**  Who         Roger Mähler
**  Uses        INFORMATION_SCHEMA.catalog in SEAD production
**  Used By     Clearing House installation. DBA.
**  Revisions
**********************************************************************************************************************************/
Create Or Replace view clearing_house.view_clearinghouse_sead_rdb_schema_pk_columns as
    Select table_schema, table_name, column_name
    From clearing_house.fn_dba_get_sead_public_db_schema('public', 'sead_master')
    Where is_pk = 'YES'
;

/*********************************************************************************************************************************
**  Function    fn_sead_entity_tables
**  When
**  What        Maps table names to entity names
**  Who         Roger Mähler
**  Uses
**  Used By     NOT USED. DEPRECATED!
**  Revisions
**********************************************************************************************************************************/
-- CREATE OR REPLACE FUNCTION clearing_house.fn_sead_entity_tables()
-- RETURNS TABLE (
--     table_name information_schema.sql_identifier,
--     entity_name information_schema.sql_identifier
-- ) LANGUAGE 'plpgsql'
-- AS $BODY$
-- Begin
-- 	Return Query
-- 		With tables as (
-- 			SELECT DISTINCT r.table_name, replace(r.table_name, 'tbl_', '') as plural_entity_name
-- 			FROM clearing_house.fn_dba_get_sead_public_db_schema('public', 'sead_master') r
-- 			WHERE r.table_name Like 'tbl_%'
-- 			  AND r.is_pk = 'YES' /* Måste finnas PK */
-- 		) Select t.table_name::information_schema.sql_identifier,
-- 			Case When plural_entity_name Like  '%ies' Then regexp_replace(plural_entity_name, 'ies$', 'y')
-- 		 		 When Not plural_entity_name Like '%status' Then rtrim(plural_entity_name, 's')
-- 				 Else plural_entity_name End::information_schema.sql_identifier As entity_name
-- 		  From tables t;
-- End
-- $BODY$;
