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
**  Function    fn_dba_get_sead_public_db_schema
**  When        2013-10-18
**  What        Retrieves SEAD public db schema catalog
**  Who         Roger Mähler
**  Uses        INFORMATION_SCHEMA.catalog in SEAD production
**  Used By     Clearing House installation. DBA.
**  Revisions
**********************************************************************************************************************************/
-- Drop Function If Exists clearing_house.fn_dba_get_sead_public_db_schema();
-- Select * From clearing_house.fn_dba_get_sead_public_db_schema('clearing_house');
CREATE OR REPLACE FUNCTION clearing_house.fn_dba_get_sead_public_db_schema(p_schema_name text default 'public')
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
    is_pk information_schema.yes_or_no
) LANGUAGE 'plpgsql'
AS $BODY$
Begin
	Return Query

		Select t.table_schema, t.table_name, c.column_name, c.ordinal_position, c.data_type, c.numeric_precision, c.numeric_scale, c.character_maximum_length,
            c.is_nullable, Case When kcu.column_name Is Null Then 'NO' Else 'YES' End::information_schema.yes_or_no
		From INFORMATION_SCHEMA.TABLES t
        Left Join INFORMATION_SCHEMA.columns c
          On c.table_schema = t.table_schema
         And c.table_name = t.table_name
        Left Join INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
          On tc.table_catalog = t.table_catalog
          And tc.table_schema = t.table_schema
          And tc.table_name = t.table_name
          And tc.constraint_type = 'PRIMARY KEY'
        Left Join INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
          On kcu.table_catalog = t.table_catalog
         And kcu.table_schema = t.table_schema
         And kcu.table_name = t.table_name
         And kcu.column_name = c.column_name
         And kcu.constraint_name = tc.constraint_name
        Where t.table_schema = p_schema_name
          And t.table_type = 'BASE TABLE'
		Order By 1, 2, 3;

End
$BODY$;

/*********************************************************************************************************************************
**  Function    fn_dba_create_and_transfer_sead_public_db_schema
**  When        2013-10-18
**  What        Stores SEAD public db schema catalog in local (frozen) table tbl_chdb_SEAD_rdb_schema
**  Who         Roger Mähler
**  Used By     Clearing House installation. DBA.
**  Revisions
**********************************************************************************************************************************/
-- Drop Function If Exists clearing_house.fn_dba_create_and_transfer_sead_public_db_schema();
-- Select * From  clearing_house.tbl_clearinghouse_sead_rdb_schema;
CREATE OR REPLACE FUNCTION clearing_house.fn_dba_create_and_transfer_sead_public_db_schema()
RETURNS void LANGUAGE 'plpgsql' AS $BODY$
Begin

    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_sead_rdb_schema') Then
        Create Table clearing_house.tbl_clearinghouse_sead_rdb_schema (
            table_schema character varying(255) not null,
            table_name character varying(255) not null,
            column_name character varying(255) not null,
            ordinal_position integer not null,
            data_type character varying(255) not null,
            numeric_precision integer null,
            numeric_scale integer null,
            character_maximum_length integer null,
            is_nullable character varying(10) not null,
            is_pk character varying(10) not null
        );
        Create /* Unique */ Index idx_sead_rdb_schema On clearing_house.tbl_clearinghouse_sead_rdb_schema (table_name, column_name);
    End If;

	Delete From clearing_house.tbl_clearinghouse_sead_rdb_schema;

	Insert Into clearing_house.tbl_clearinghouse_sead_rdb_schema (table_schema, table_name, column_name, ordinal_position, data_type, numeric_precision, numeric_scale, character_maximum_length, is_nullable, is_pk)
		Select table_schema, table_name, column_name, ordinal_position, data_type, numeric_precision, numeric_scale, character_maximum_length, is_nullable, is_pk
		From clearing_house.fn_dba_get_sead_public_db_schema()
		Order By 1,2,3;
End
$BODY$;

ALTER FUNCTION clearing_house.fn_dba_create_and_transfer_sead_public_db_schema()
    OWNER TO clearinghouse_worker;

ALTER FUNCTION clearing_house.fn_dba_get_sead_public_db_schema(text)
    OWNER TO clearinghouse_worker;
