
-- STEP #1: Install audit-trigger
-- See https://wiki.postgresql.org/wiki/Audit_trigger_91plus

DO $$
    BEGIN
        -- Apply as humlab_admin: https://github.com/2ndQuadrant/audit-trigger (audit.sql)

        GRANT USAGE ON SCHEMA audit TO humlab_admin;
        GRANT SELECT ON ALL TABLES IN SCHEMA audit TO humlab_admin;

        GRANT USAGE ON SCHEMA audit TO sead_master, sead_read, humlab_admin, humlab_read, phil, mattias, postgres;
        GRANT ALL ON ALL TABLES IN SCHEMA audit TO sead_master, sead_read, humlab_admin, mattias, phil, postgres;
        ALTER DEFAULT PRIVILEGES FOR ROLE humlab_admin IN SCHEMA audit
            GRANT SELECT ON TABLES TO sead_master, sead_read, humlab_admin, mattias, phil, humlab_read;

    END
$$;

/********************************************************************************************************
**  FUNCTION    metainformation.audit_schema
**  WHO         Roger Mähler
**  WHAT        Adds DML audit triggers on all tables in schema
*********************************************************************************************************/
CREATE OR REPLACE FUNCTION metainformation.audit_schema(p_table_schema text) RETURNS void AS $$
DECLARE
   v_record RECORD;
   v_table_name text;
   v_table_audit_view text;
BEGIN

	FOR v_record IN
		select  t.table_name
		from information_schema.tables t
		left join pg_trigger g
		  on not g.tgisinternal
		 and g.tgrelid = (t.table_schema || '.' || t.table_name)::regclass
		where t.table_schema = p_table_schema
		  and t.table_type = 'BASE TABLE'
		  and g.tgrelid is NULL
		order by 1
	LOOP
		v_table_name = p_table_schema || '.' || v_record.table_name;
		PERFORM audit.audit_table(v_table_name);

        -- v_table_audit_view_sql = clearing_house.fn_script_audit_views(p_table_schema, v_record.table_name);
        -- Execute v_table_audit_view_sql;

		RAISE NOTICE 'DONE: %', v_table_name;
	END LOOP;

END
$$ LANGUAGE plpgsql VOLATILE;

/********************************************************************************************************
**  FUNCTION    metainformation.fn_script_audit_views
**  WHO         Roger Mähler
**  WHAT        Script view DDL over audit HSTORE data for a specific table
*********************************************************************************************************/
-- DROP FUNCTION IF EXISTS metainformation.fn_script_audit_views(character varying(255), character varying(255))
Create Or Replace Function metainformation.fn_script_audit_views(source_schema character varying(255), p_table_name character varying(255)) Returns text As $$
	Declare v_template text;
	Declare v_view_name text;
	Declare v_view_dml text;
	Declare v_column_list text;
	Declare v_column_type text;
	Declare x clearing_house.tbl_clearinghouse_sead_rdb_schema%rowtype;
Begin

    v_view_name = Replace(p_table_name, 'tbl_', 'view_');

	v_template = '
    DROP VIEW IF EXISTS audit.#VIEW-NAME#;
    CREATE VIEW audit.#VIEW-NAME# AS
		SELECT #COLUMN-LIST#,
		transaction_id,
		action,
		session_user_name,
		action_tstamp_tx
		FROM audit.logged_actions
		WHERE table_name = ''#TABLE-NAME#''
	;';

    /*
	v_column_list := '';

	For x In (
		Select *
		From clearing_house.fn_dba_get_sead_public_db_schema() s
		Where s.table_schema = source_schema
		  And s.table_name = p_table_name
		Order By ordinal_position)
	Loop

		v_column_list := v_column_list || Case When v_column_list = '' Then '' Else ',
		'
		End;
		v_column_type := clearing_house.fn_create_schema_type_string(x.data_type, x.character_maximum_length, x.numeric_precision, x.numeric_scale, 'YES');
		v_column_type := replace(v_column_type, ' null', '');
		v_column_list := v_column_list || '(row_data->''' || x.column_name || ''')::' || v_column_type || ' AS ' || x.column_name;

	End Loop; */

    WITH table_columns AS (
        SELECT column_name,
            clearing_house.fn_create_schema_type_string(data_type, character_maximum_length, numeric_precision, numeric_scale, 'YES') as column_type
        FROM clearing_house.tbl_clearinghouse_sead_rdb_schema s -- clearing_house.fn_dba_get_sead_public_db_schema() s
        WHERE s.table_schema = 'public'
        AND s.table_name = 'tbl_locations'
        ORDER BY ordinal_position
    )
        SELECT string_agg('(row_data->''' || column_name || ''')::' || replace(column_type, ' null', '') || ' AS ' || column_name, ', ' || CHR(13))
        INTO v_column_list
        FROM table_columns;

	v_view_dml := v_template;
	v_view_dml := replace(v_view_dml, '#VIEW-NAME#', v_view_name);
	v_view_dml := replace(v_view_dml, '#TABLE-NAME#', p_table_name);
	v_view_dml := replace(v_view_dml, '#COLUMN-LIST#', v_column_list);

	Return v_view_dml;

End $$ Language plpgsql;

CREATE OR REPLACE FUNCTION metainformation.create_typed_audit_views(p_table_schema text = 'public') RETURNS void AS $$
DECLARE
   v_record RECORD;
   v_view_dml text;
BEGIN

	FOR v_record IN
		select  distinct t.table_name
		from information_schema.tables t
		join pg_trigger g
		  on not g.tgisinternal
		 and g.tgrelid = (t.table_schema || '.' || t.table_name)::regclass
		where t.table_schema = p_table_schema
		  and t.table_type = 'BASE TABLE'
		order by 1
	LOOP
        v_view_dml = metainformation.fn_script_audit_views(p_table_schema, v_record.table_name);
        Execute v_view_dml;
		RAISE NOTICE 'DONE: %', v_record.table_name;
	END LOOP;

END
$$ LANGUAGE plpgsql VOLATILE;

-- SELECT metainformation.create_typed_audit_views('public');