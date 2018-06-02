
-- STEP #1: Install audit-trigger
-- See https://wiki.postgresql.org/wiki/Audit_trigger_91plus

DO $$
    BEGIN
        -- Apply as humlab_admin: https://github.com/2ndQuadrant/audit-trigger (audit.sql)

        GRANT USAGE ON SCHEMA audit TO humlab_admin;
        GRANT SELECT ON ALL TABLES IN SCHEMA audit TO humlab_admin;

        -- You may also want to set default privileges for future schemas and tables. Run for every role that creates objects in your db
        -- ALTER DEFAULT PRIVILEGES FOR ROLE mycreating_user IN SCHEMA public
        -- GRANT SELECT ON TABLES TO humlab_admin;
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

        v_table_audit_view_sql = clearing_house.fn_script_audit_views(p_table_schema, v_record.table_name);
        Execute v_table_audit_view_sql;

		RAISE NOTICE 'DONE: %', v_table_name;
	END LOOP;

END
$$ LANGUAGE plpgsql STABLE;

/********************************************************************************************************
**  FUNCTION    clearing_house.fn_script_audit_views
**  WHO         Roger Mähler
**  WHAT        Script view DDL over audit HSTORE data for a specific table
*********************************************************************************************************/

Create Or Replace Function clearing_house.fn_script_audit_views(source_schema character varying(255), p_table_name character varying(255)) Returns text As $$
	Declare sql_template text;
	Declare sql_view text;
	Declare column_list text;
	Declare column_type text;
	Declare x clearing_house.tbl_clearinghouse_sead_rdb_schema%rowtype;
Begin

	sql_template = 'CREATE VIEW audit.view_#TABLE-NAME# AS
		SELECT #COLUMN-LIST#,
		action,
		session_user_name,
		action_tstamp_tx
		FROM audit.logged_actions
		WHERE table_name = ''#TABLE-NAME#''
	;';

	column_list := '';

	For x In (
		Select *
		From clearing_house.tbl_clearinghouse_sead_rdb_schema s
		Where s.table_schema = source_schema
		  And s.table_name = p_table_name
		Order By ordinal_position)
	Loop

		column_list := column_list || Case When column_list = '' Then '' Else ',
		'
		End;
		column_type := clearing_house.fn_create_schema_type_string(x.data_type, x.character_maximum_length, x.numeric_precision, x.numeric_scale, 'YES');
		column_type := replace(column_type, ' null', '');
		column_list := column_list || '(row_data->''' || x.column_name || ''')::' || column_type || ' AS ' || x.column_name;

	End Loop;

	sql_view := sql_template;
	sql_view := replace(sql_view, '#TABLE-NAME#', p_table_name);
	sql_view := replace(sql_view, '#COLUMN-LIST#', column_list);

	Return sql_view;

End $$ Language plpgsql;

