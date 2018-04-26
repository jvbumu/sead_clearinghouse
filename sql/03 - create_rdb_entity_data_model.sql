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
    Select table_schema, table_name,  column_name
    From clearing_house.tbl_clearinghouse_sead_rdb_schema
    Where is_pk = 'YES'
;
/*****************************************************************************************************************************
**	Function	fn_rdb_schema_script_table
**	Who			Roger Mähler
**	When		2013-10-17
**	What		Create type string based on schema type fields.
**	Revisions
******************************************************************************************************************************/
-- Select clearing_house.fn_create_schema_type_string('character varying', 255, null, null, 'YES')
Create Or Replace Function clearing_house.fn_create_schema_type_string(
	data_type character varying(255),
	character_maximum_length int,
	numeric_precision int,
	numeric_scale int,
	is_nullable character varying(10)
) Returns text As $$
	Declare type_string text;
Begin
	type_string :=  data_type
		||	Case When data_type = 'character varying' And Coalesce(character_maximum_length, 0) > 0
                    Then '(' || Coalesce(character_maximum_length::text, '255') || ')'
				 When data_type = 'numeric' Then
					Case When numeric_precision Is Null And numeric_scale Is Null Then  ''
						 When numeric_scale Is Null Then  '(' || numeric_precision::text || ')'
						 Else '(' || numeric_precision::text || ', ' || numeric_scale::text || ')'
					End
				 Else '' End || ' '|| Case When Coalesce(is_nullable,'') = 'YES' Then 'null' Else 'not null' End;
	return type_string;

End $$ Language plpgsql;

/*****************************************************************************************************************************
**	Function	fn_script_public_db_entity_table
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Creates new CHDB tables based on SEAD information_schema.catalog
**					- All columns in SEAD catalog is included, and using the same data_types and null attribute
**					- CHDB specific columns submission_id and source_id (LDB or PDB) is added
**					- XML attribute "id" is mapped to CHDB field "local_db_id"
**					- XML attribute "cloned_id" is mapped to CHDB field "public_db_id"
**					- PK in new table is submission_id + source_id + "PK:s in Local DB'
**  Uses
**  Used By
**	Revisions
**	TODO		Add keys on foreign indexes to improve performance.
******************************************************************************************************************************/
-- Select clearing_house.fn_script_public_db_entity_table('public', 'clearing_house', 'tbl_physical_samples')
Create Or Replace Function clearing_house.fn_script_public_db_entity_table(source_schema character varying(255), target_schema character varying(255), table_name character varying(255)) Returns text As $$
	#variable_conflict use_variable
	Declare sql_template text;
	Declare sql text;
	Declare column_list text;
	Declare pk_fields text;
	Declare x clearing_house.tbl_clearinghouse_sead_rdb_schema%rowtype;

Begin

	sql_template = '	Create Table #TABLE-NAME# (

		submission_id int not null,
		source_id int not null,

		local_db_id int not null,
		public_db_id int null,

		#COLUMN-LIST#

		#PK-CONSTRAINT#

	);';

	column_list := '';
	pk_fields := '';

	For x In (
		Select *
		From clearing_house.tbl_clearinghouse_sead_rdb_schema s
		Where s.table_schema = source_schema
		  And s.table_name = table_name
		Order By ordinal_position)
	Loop

		column_list := column_list || Case When column_list = '' Then '' Else ',
		'
		End;

		column_list := column_list || x.column_name || ' ' || clearing_house.fn_create_schema_type_string(x.data_type, x.character_maximum_length, x.numeric_precision, x.numeric_scale, x.is_nullable) || '';

		If x.is_pk = 'YES' Then
			pk_fields := pk_fields || Case When pk_fields = '' Then '' Else ', ' End || x.column_name;
		End If;

	End Loop;

	sql := sql_template;

	sql := replace(sql, '#TABLE-NAME#', target_schema || '.' || table_name);
	sql := replace(sql, '#COLUMN-LIST#', column_list);

	If pk_fields <> '' Then
		sql := replace(sql, '#PK-CONSTRAINT#', replace(',Constraint pk_' || table_name || ' Primary Key (submission_id, source_id, #PK-FIELDS#)', '#PK-FIELDS#', pk_fields));
	Else
		sql := replace(sql, '#PK-CONSTRAINT#', '');
	End If;


	Return sql;

End $$ Language plpgsql;
/*****************************************************************************************************************************
**	Function	fn_create_public_db_entity_tables
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Creates a local copy in schema clearing_house of all public db entity tables
**  Note
**  Uses
**  Used By
**	Revisions
******************************************************************************************************************************/
-- Select clearing_house.fn_create_public_db_entity_tables('clearing_house')
-- Select * From clearing_house.tbl_clearinghouse_sead_create_table_log
Create Or Replace Function clearing_house.fn_create_public_db_entity_tables(target_schema character varying(255), only_drop BOOLEAN = FALSE) Returns void As $$

	Declare x RECORD;
	Declare create_script text;
	Declare drop_script text;
	Declare index_script text;

Begin

    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_sead_create_table_log') Then

	    -- Drop Table If Exists clearing_house.tbl_clearinghouse_sead_create_table_log;
	    Create Table clearing_house.tbl_clearinghouse_sead_create_table_log (create_script text, drop_script text);

    End If;

    Delete From clearing_house.tbl_clearinghouse_sead_create_table_log;

	For x In (
		Select distinct table_schema As source_schema, table_name
		From clearing_house.tbl_clearinghouse_sead_rdb_schema
		Where table_schema Not In ('information_schema', 'pg_catalog', 'clearing_house')
		  And table_name Like 'tbl%'
	)
	Loop

		If clearing_house.fn_table_exists(target_schema || '.' || x.table_name) Then

			Raise Exception 'Skipped: % since table already exists. ', target_schema || '.' || x.table_name;

		Else

			create_script := clearing_house.fn_script_public_db_entity_table(x.source_schema, target_schema, x.table_name);
			drop_script := 'Drop Table If Exists ' || target_schema || '.' ||  x.table_name || ' CASCADE;';
            -- FIXME: Index create not tested
            -- index_script = 'Create Index idx_' || x.table_name || '_submission_id On '
            --    || target_schema || '.' ||  x.table_name || ' (submission_id, public_db_id);';

			If (create_script <> '') Then

				Execute drop_script;

                If (Not only_drop) Then
				    Execute create_script;
				    -- Execute index_script;
                End If;

				Insert Into clearing_house.tbl_clearinghouse_sead_create_table_log (create_script, drop_script) Values (create_script, drop_script);

			Else
				Insert Into clearing_house.tbl_clearinghouse_sead_create_table_log (create_script, drop_script) Values ('--Failed: ' || target_schema || '.' || x.table_name, '');
			End If;


		End If;

	End Loop;

End $$ Language plpgsql;


/*****************************************************************************************************************************
**	Function	fn_add_new_public_db_columns
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Adds missing columns found in public db to local entity table
**  Note
**  Uses
**  Used By
**	Revisions
******************************************************************************************************************************/
-- Select clearing_house.fn_add_new_public_db_columns(2, 'tbl_datasets')
Create Or Replace Function clearing_house.fn_add_new_public_db_columns(int, character varying(255)) Returns void As $$

	Declare xml_columns character varying(255)[];
	Declare schema_columns character varying(255)[];
	Declare sql text;
	Declare x RECORD;

Begin

	xml_columns := clearing_house.fn_get_submission_table_column_names($1, $2);

	If array_length(xml_columns, 1) = 0 Then
		Raise Exception 'Fatal error. Table % has unknown fields.', $2;
		Return;
	End If;

	If Not clearing_house.fn_table_exists($2) Then

		sql := 'Create Table clearing_house.' || $2 || ' (

			submission_id int not null,
			source_id int not null,

			local_db_id int not null,
			public_db_id int null,

			Constraint pk_' || $2 || '_' || xml_columns[1] || ' Primary Key (submission_id, ' || xml_columns[1] || ')

		) ';

		Raise Notice '%', sql;
--		Execute sql;

	End If;

	For x In (
		Select t.table_name_underscored, c.column_name_underscored, c.data_type
		From clearing_house.tbl_clearinghouse_submission_tables t
		Join clearing_house.tbl_clearinghouse_submission_xml_content_columns c
		  On c.table_id = t.table_id
		Left Join INFORMATION_SCHEMA.columns ic
		  On ic.table_schema = 'clearing_house'
		 And ic.table_name = t.table_name_underscored
		 And ic.column_name = c.column_name_underscored
		Where c.submission_id = $1
		  And t.table_name_underscored = $2
		  And c.column_name_underscored <> 'cloned_id'
		  And ic.table_name Is Null
	) Loop

		sql := 'Alter Table clearing_house.' || $2 || ' Add Column ' || x.column_name_underscored || ' ' || clearing_house.fn_java_type_to_PostgreSQL(x.data_type) || ' null;';

		Execute sql;

		Raise Notice 'Added new column: % % % [%]', x.table_name_underscored,  x.column_name_underscored , clearing_house.fn_java_type_to_PostgreSQL(x.data_type), sql;

        Insert Into clearing_house.tbl_clearinghouse_sead_unknown_column_log (submission_id, table_name, column_name, column_type, alter_sql)
        Values ($1, x.table_name_underscored, x.column_name_underscored, clearing_house.fn_java_type_to_PostgreSQL(x.data_type), sql);

	End Loop;

End $$ Language plpgsql;

/*****************************************************************************************************************************
**	Function	fn_script_local_union_public_entity_view
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Creates union views of local and public data
**  Uses
**  Used By
**	Revisions
******************************************************************************************************************************/
-- Select clearing_house.fn_script_local_union_public_entity_view('clearing_house', 'clearing_house', 'public', 'tbl_dating_uncertainty')
-- Select * From tbl_clearinghouse_sead_rdb_schema
Create Or Replace Function clearing_house.fn_script_local_union_public_entity_view(target_schema character varying(255), local_schema character varying(255), public_schema character varying(255), table_name character varying(255)) Returns text As $$
	#variable_conflict use_variable
	Declare sql_template text;
	Declare sql text;
	Declare column_list text;
	Declare pk_field text;
Begin

	sql_template =
'/*****************************************************************************************************************************
**	Function	#VIEW-NAME#
**	Who			THIS VIEW IS AUTO-GENERATED BY fn_create_local_union_public_entity_views / Roger Mähler
**	When		#DATE#
**	What		Returns union of local and public versions of #TABLE-NAME#
**  Uses        clearing_house.tbl_clearinghouse_sead_rdb_schema
**	Note		Plase re-run fn_create_local_union_public_entity_views whenever public schema is changed
**  Used By     SEAD Clearing House
******************************************************************************************************************************/

Create Or Replace View #TARGET-SCHEMA#.#VIEW-NAME# As

	Select submission_id, source_id, local_db_id as merged_db_id, local_db_id, public_db_id, #COLUMN-LIST#
	From #LOCAL-SCHEMA#.#TABLE-NAME#
	Union
	Select 0 As submission_id, 2 As source_id, #PK-COLUMN# as merged_db_id, 0 As local_db_id, #PK-COLUMN# As public_db_id, #COLUMN-LIST#
	From #PUBLIC-SCHEMA#.#TABLE-NAME#

;';

	Select array_to_string(array_agg(s.column_name Order By s.ordinal_position), ',') Into column_list
	From clearing_house.tbl_clearinghouse_sead_rdb_schema s
	Join information_schema.columns c /* Ta endast med kolumner som finns i båda */
	  On c.table_schema = local_schema
	 And c.table_name = table_name
	 And c.column_name = s.column_name
	Where s.table_schema = public_schema
	  And s.table_name = table_name;

	Select column_name Into pk_field
	From clearing_house.tbl_clearinghouse_sead_rdb_schema s
	Where s.table_schema = public_schema
	  And s.table_name = table_name
	  And s.is_pk = 'YES';

	sql := sql_template;
	sql := replace(sql, '#DATE#', to_char(now(), 'YYYY-MM-DD HH24:MI:SS'));
	sql := replace(sql, '#COLUMN-LIST#', column_list);
	sql := replace(sql, '#PK-COLUMN#', pk_field);
	sql := replace(sql, '#TARGET-SCHEMA#', target_schema);
	sql := replace(sql, '#LOCAL-SCHEMA#', local_schema);
	sql := replace(sql, '#PUBLIC-SCHEMA#', public_schema);
	sql := replace(sql, '#VIEW-NAME#', replace(table_name, 'tbl_', 'view_'));
	sql := replace(sql, '#TABLE-NAME#', table_name);

	Return sql;

End $$ Language plpgsql;

/*****************************************************************************************************************************
**	Function	fn_create_local_union_public_entity_views
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Creates "union-views" of local and public entity tables
**  Note
**  Uses
**  Used By
**	Revisions
******************************************************************************************************************************/
-- Select clearing_house.fn_create_local_union_public_entity_views('clearing_house', 'clearing_house', TRUE)
-- Select * From clearing_house.tbl_clearinghouse_sead_create_view_log
Create Or Replace Function clearing_house.fn_create_local_union_public_entity_views(target_schema character varying(255), local_schema character varying(255), only_drop BOOLEAN = FALSE)
Returns void As $$

	Declare x RECORD;
	Declare drop_script text;
	Declare create_script text;

Begin

	Drop Table If Exists clearing_house.tbl_clearinghouse_sead_create_view_log;

	Create Table clearing_house.tbl_clearinghouse_sead_create_view_log (create_script text, drop_script text);

	For x In (
		Select distinct table_schema As public_schema, table_name, replace(table_name, 'tbl_', 'view_') As view_name
		From clearing_house.tbl_clearinghouse_sead_rdb_schema
		Where table_schema Not In ('information_schema', 'pg_catalog', 'clearing_house', 'metainformation')
		  And table_name Like 'tbl%'
		  And is_pk = 'YES' /* Måste finnas PK */
	)
	Loop

		drop_script = 'Drop View If Exists ' || target_schema || '.' || x.view_name || ' CASCADE;';

		create_script := clearing_house.fn_script_local_union_public_entity_view(target_schema, local_schema, x.public_schema, x.table_name);

		If (create_script <> '') Then

			Insert Into clearing_house.tbl_clearinghouse_sead_create_view_log (create_script, drop_script) Values (create_script, drop_script);

            If (only_drop) Then
			    Execute drop_script;
            Else
			    Execute drop_script || ' ' || create_script;
            End If;

		Else
			Insert Into clearing_house.tbl_clearinghouse_sead_create_view_log (create_script, drop_script) Values ('--Failed: ' || target_schema || '.' || x.table_name, '');
		End If;


	End Loop;

End $$ Language plpgsql;
/*****************************************************************************************************************************
**	Function	fn_generate_foreign_key_indexes
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Generates DDL create index statement if column (via name matching) is FK in public DB and lacks index.
**  Note
**  Uses
**  Used By
**	Revisions
******************************************************************************************************************************/

Create Or Replace Function clearing_house.fn_generate_foreign_key_indexes()
Returns void As $$
Declare x RECORD;
Begin
	For x In (

        Select 'Create Index idx_' || target_constraint_name || ' On clearing_house.' || target_table || ' (' || target_colname || ');' as create_script,
               'Drop Index If Exists clearing_house.idx_' || target_constraint_name || ';' as drop_script
        From (
            select	(select nspname from pg_namespace where oid=m.relnamespace)																as target_ns,
                    m.relname																												as target_table,
                    (select a.attname from pg_attribute a where a.attrelid = m.oid and a.attnum = o.conkey[1] and a.attisdropped = false)	as target_colname,
                    o.conname																												as target_constraint_name,
                    (select nspname from pg_namespace where oid=f.relnamespace)																as foreign_ns,
                    f.relname																												as foreign_table,
                    (select a.attname from pg_attribute a where a.attrelid = f.oid and a.attnum = o.confkey[1] and a.attisdropped = false)	as foreign_colname
            from pg_constraint o
            left join pg_class c
              on c.oid = o.conrelid
            left join pg_class f
              on f.oid = o.confrelid
            left join pg_class m
              on m.oid = o.conrelid
            where o.contype = 'f'
              and o.conrelid in (select oid from pg_class c where c.relkind = 'r')
            order by 2
        ) as x
        Left Join pg_indexes i
          On i.schemaname = 'clearing_house'
         And i.tablename =  target_table
         And i.indexname =  'idx_' || target_constraint_name
        Where target_ns = 'public'
          And i.indexname is null
    ) Loop
        Raise Notice '%', x.drop_script;
        Raise Notice '%', x.create_script;

        Execute x.drop_script;
        Execute x.create_script;
    End Loop;

End $$ Language plpgsql;


/*****************************************************************************************************************************
**	Function	fn_create_clearinghouse_public_db_model
**	Who			Roger Mähler
**	When		2017-11-16
**	What		Calls functions above to create a CH version of public entity tables and viewes that merges
**              local and public entity tables
**  Uses
**  Used By
**	Revisions
******************************************************************************************************************************/

Create Or Replace Function clearing_house.fn_create_clearinghouse_public_db_model()
Returns void As $$
Begin

    Perform clearing_house.fn_create_public_db_entity_tables('clearing_house', FALSE);
    Perform clearing_house.fn_generate_foreign_key_indexes();
    Perform clearing_house.fn_create_local_union_public_entity_views('clearing_house', 'clearing_house', FALSE);

End $$ Language plpgsql;

Create Or Replace Function clearing_house.fn_drop_clearinghouse_public_db_model()
Returns void As $$
Begin
    Perform clearing_house.fn_create_local_union_public_entity_views('clearing_house', 'clearing_house', TRUE);
    Perform clearing_house.fn_create_public_db_entity_tables('clearing_house', TRUE);
End $$ Language plpgsql;

