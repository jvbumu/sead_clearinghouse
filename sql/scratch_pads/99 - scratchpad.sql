SELECT relname, CASE WHEN (seq_scan + idx_scan) = 0 THEN null ELSE 100 * idx_scan / (seq_scan + idx_scan) END percent_of_times_index_used, n_live_tup rows_in_table
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;

-- all tables and their size, with/without indexes
select datname, pg_size_pretty(pg_database_size(datname))
from pg_database
order by pg_database_size(datname) desc;

-- cache hit rates (should not be less than 0.99)
SELECT sum(heap_blks_read) as heap_read, sum(heap_blks_hit)  as heap_hit, (sum(heap_blks_hit) - sum(heap_blks_read)) / sum(heap_blks_hit) as ratio
FROM pg_statio_user_tables;

Select *
From clearing_house.fn_dba_get_sead_public_db_schema('public') A
Full Outer Join clearing_house.fn_dba_get_sead_public_db_schema_newer('public') B USING(table_name, column_name)
Where (A.ordinal_position <> B.ordinal_position) Or
(A.data_type <> B.data_type) Or
(A.numeric_precision <> B.numeric_precision) Or
(A.numeric_scale <> B.numeric_scale) Or
(A.character_maximum_length <> B.character_maximum_length) Or
(A.is_nullable <> B.is_nullable) Or
(A.is_pk <> B.is_pk)
/* Schema diff test:

    Select coalesce(p.table_name, c.table_name) as table_name,
           coalesce(p.column_name, c.column_name) as column_name,
           case when not p.table_name is Null then '' else 'missing' end as public,
           case when not c.table_name is Null then '' else 'missing' end as clearinghouse,
           case when p.data_type <> p.data_type then 'type: ' || coalesce(c.data_type, '') || ' - ' || coalesce(p.data_type, '')
                when p.character_maximum_length <> p.character_maximum_length then 'len: ' || coalesce(p.character_maximum_length::text, '') || ' - ' || coalesce(c.character_maximum_length::text, '') || ' '
                else '' end
    From clearing_house.fn_dba_get_sead_public_db_schema('public') p
    Full Outer Join clearing_house.fn_dba_get_sead_public_db_schema('clearing_house') c
      On p.table_name = c.table_name
     And p.column_name = c.column_name
    Where 1 = 1
      And (p.table_schema Is Null Or c.table_schema Is Null)
      And coalesce(c.column_name, '') Not In ('local_db_id', 'public_db_id', 'source_id', 'submission_id')
      And coalesce(c.table_name, '') Not Like 'tbl_clearinghouse_%'

*/

/*********************************************************************************************************************************
**  Function    fn_dba_get_pk_constraints
**  When
**  What        Retrieves schemas PK constraints
**  Who         Roger Mähler
**  Uses
**  Used By     NOT USED. DEPRECATED!
**  Revisions
**********************************************************************************************************************************/
-- Drop Function If Exists clearing_house.fn_dba_get_pk_constraints(text);
-- Select * From clearing_house.fn_dba_get_pk_constraints('public');
CREATE OR REPLACE FUNCTION clearing_house.fn_dba_get_pk_constraints(p_schema_name text default 'public')
RETURNS TABLE (
    table_name information_schema.sql_identifier,
    column_name information_schema.sql_identifier
) LANGUAGE 'plpgsql'
AS $BODY$
Begin
    Return Query
    WITH pk_constraints AS (
        SELECT n.nspname, conrelid, unnest(c.conkey) AS attnum
        FROM  pg_constraint c
        JOIN  pg_namespace n ON n.oid = c.connamespace
        WHERE contype IN ('p ')
    )
        SELECT a.attrelid::regclass::information_schema.sql_identifier AS table_name, a.attname::information_schema.sql_identifier as column_name
        FROM pk_constraints c
        JOIN pg_attribute a
          ON a.attrelid = c.conrelid
         AND a.attnum = c.attnum
        WHERE c.nspname = p_schema_name ;
End
$BODY$;
/*********************************************************************************************************************************
**  Function    fn_dba_get_fk_constraints
**  When
**  What        Retrieves schemas FK constraints
**  Who         Roger Mähler
**  Uses
**  Used By     NOT USED. DEPRECATED!
**  Revisions
**********************************************************************************************************************************/
-- Drop Function If Exists clearing_house.fn_dba_get_fk_constraints(text);
-- Select * From clearing_house.fn_dba_get_fk_constraints('public');
CREATE OR REPLACE FUNCTION clearing_house.fn_dba_get_fk_constraints(p_schema_name text default 'public')
RETURNS TABLE (
    from_table information_schema.sql_identifier,
    from_column information_schema.sql_identifier,
    to_table information_schema.sql_identifier,
    to_column information_schema.sql_identifier
) LANGUAGE 'plpgsql'
AS $BODY$
Begin
	Return Query
    WITH fk_constraints AS (
        SELECT nspname, conrelid, confrelid, unnest(c.conkey) AS attnum, unnest(c.confkey) AS fattnum
        FROM pg_constraint c
        JOIN pg_namespace n
          ON n.oid = c.connamespace
        WHERE contype IN ('f')
    )
        SELECT c.conrelid::regclass::information_schema.sql_identifier AS from_table,
               a.attname::information_schema.sql_identifier AS from_column,
               c.confrelid::regclass::information_schema.sql_identifier AS to_table,
               af.attname::information_schema.sql_identifier AS to_column
        FROM fk_constraints c
        LEFT JOIN pg_attribute af
          ON af.attrelid = c.confrelid
         AND af.attnum = c.fattnum
        LEFT JOIN pg_attribute a
          ON a.attrelid = c.conrelid
         AND a.attnum = c.attnum
        WHERE c.nspname = p_schema_name;
End
$BODY$;