GRANT CONNECT ON DATABASE sead_bugs_import_20180503  TO humlab_read, humlab_admin, anonymous_rest_user;

Grant usage On Schema postgrest_default_api, public To humlab_read, humlab_admin, anonymous_rest_user;
Grant select On all tables in Schema postgrest_default_api, public To humlab_read, humlab_admin, anonymous_rest_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA postgrest_default_api, public TO humlab_read, humlab_admin, anonymous_rest_user;

do language plpgsql $$
    Declare x record;
    Declare entity_name text;
    Declare drop_sql text;
    Declare create_sql text;
    Declare owner_sql text;
Begin

	Grant usage On Schema postgrest_default_api, public To humlab_admin;
	Grant select On all tables in Schema postgrest_default_api, public To humlab_read;

    Create Schema If Not Exists postgrest_default_api AUTHORIZATION humlab_read;

    If Not Exists (Select From pg_catalog.pg_roles Where rolname = 'anonymous_rest_user') Then
        Create Role anonymous_rest_user nologin;
        Grant anonymous_rest_user to humlab_admin;
        Grant anonymous_rest_user to humlab_read;
        Grant usage On Schema postgrest_default_api To anonymous_rest_user;
        Grant select On all tables in Schema postgrest_default_api To anonymous_rest_user;
    End If;
   
    For x In (
        select distinct table_name
        from information_schema.tables
        where table_schema = 'public'
          and table_type = 'BASE TABLE'
    ) Loop
        
        entity_name = replace(x.table_name, 'tbl_', '');

        If entity_name Like '%entities' Then
            entity_name = replace(entity_name, 'entities', 'entity');
        ElseIf entity_name Like '%ies' Then
            entity_name = regexp_replace(entity_name, 'ies$', 'y');
        ElseIf Not entity_name Like '%status' Then
            entity_name = rtrim(entity_name, 's');
        End If;

        drop_sql = 'drop view if exists postgrest_default_api.' || entity_name || ';';
        create_sql = 'create or replace view postgrest_default_api.' || entity_name || ' as select * from public.' || x.table_name || ';';
        owner_sql = 'alter table postgrest_default_api.' || entity_name || ' owner to humlab_read;';
    
        Execute drop_sql;
        Execute create_sql;
        Execute owner_sql;
   
        Raise Notice 'Done: %', entity_name;

    End Loop;
End
$$