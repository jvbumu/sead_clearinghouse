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
-- Select * From clearing_house.fn_dba_get_sead_public_db_schema();
CREATE OR REPLACE FUNCTION clearing_house.fn_dba_get_sead_public_db_schema()
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
	
		Select c.table_schema, c.table_name, c.column_name, c.ordinal_position, c.data_type, c.numeric_precision, c.numeric_scale, c.character_maximum_length,
            c.is_nullable, Case When k.column_name Is Null Then 'NO' Else 'YES' End::information_schema.yes_or_no
		From information_schema.columns c
		Left Join (
			Select t.table_schema, t.table_name, kcu.column_name
			From INFORMATION_SCHEMA.TABLES t 
			Left Join INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc 
			  On tc.table_catalog = t.table_catalog 
			  And tc.table_schema = t.table_schema 
			  And tc.table_name = t.table_name 
			  And tc.constraint_type = 'PRIMARY KEY' 
			Left Join INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu 
			  On kcu.table_catalog = tc.table_catalog 
			 And kcu.table_schema = tc.table_schema 
			 And kcu.table_name = tc.table_name 
			 And kcu.constraint_name = tc.constraint_name 
			Where t.table_schema = 'public'
		) as k
		  On k.table_schema = c.table_schema
		 And k.table_name = c.table_name
		 And k.column_name = c.column_name
		Where 1 = 1 -- c.table_name Like 'tbl_%' and data_type = 'numeric'
		  And c.table_schema = 'public'
		Order By 1,2,3;
End 
$BODY$;

ALTER FUNCTION clearing_house.fn_dba_get_sead_public_db_schema()
    OWNER TO clearinghouse_worker;
