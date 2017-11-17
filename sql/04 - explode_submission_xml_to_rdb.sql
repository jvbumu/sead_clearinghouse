/*****************************************************************************************************************************
**	Function	fn_get_submission_table_column_names
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Returns column names for specified table as an array
**	Uses
**	Used By
**	Revisions
******************************************************************************************************************************/
-- Select clearing_house.fn_get_submission_table_column_names(2, 'tbl_abundances')
Create Or Replace Function clearing_house.fn_get_submission_table_column_names(int, character varying(255))
Returns character varying(255)[] As $$
	Declare columns character varying(255)[];
Begin

	Select array_agg(c.column_name_underscored order by c.column_id asc) Into columns
	From clearing_house.tbl_clearinghouse_submission_tables t
    Join clearing_house.tbl_clearinghouse_submission_xml_content_columns c
	  On c.table_id = t.table_id
	Where c.submission_id = $1
	  And t.table_name_underscored = $2
	Group By c.submission_id, t.table_name;
	
	return columns;
	
End $$ Language plpgsql;
/*****************************************************************************************************************************
**	Function	fn_get_public_table_column_names
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Returns column names for specified table as an array
**	Uses
**	Used By
**	Revisions
******************************************************************************************************************************/
-- Select clearing_house.fn_get_public_table_column_names('public', 'tbl_abundances')
Create Or Replace Function clearing_house.fn_get_public_table_column_names(sourceschema character varying(255), tablename character varying(255))
Returns character varying(255)[] As $$
	Declare columns character varying(255)[];
Begin
	Select array_agg(c.column_name order by ordinal_position asc) Into columns
	From clearing_house.tbl_clearinghouse_SEAD_rdb_schema c
	Where c.table_schema = sourceschema
	  And c.table_name = tablename;
	return columns;
End $$ Language plpgsql;
/*****************************************************************************************************************************
**	Function	fn_get_public_table_key_column_name
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Returns column names for specified table as an array
**	Uses
**	Used By
**	Revisions
******************************************************************************************************************************/
-- Select clearing_house.fn_get_public_table_key_column_name('public', 'tbl_abundances')
Create Or Replace Function clearing_house.fn_get_public_table_key_column_name(sourceschema character varying(255), tablename character varying(255))
Returns character varying(255) As $$
	Declare key_column character varying(255);
Begin
	Select c.column_name Into key_column
	From clearing_house.tbl_clearinghouse_SEAD_rdb_schema c
	Where c.table_schema = sourceschema
	  And c.table_name = tablename
	  And c.is_pk = 'YES'
	Limit 1;
	return key_column;
End $$ Language plpgsql;
/*****************************************************************************************************************************
**	Function	
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Returns column SQL types for specified table as an array
**	Uses
**	Used By
**	Revisions
******************************************************************************************************************************/
-- Select clearing_house.fn_get_submission_table_column_types(2, 'tbl_abundances')
Create Or Replace Function clearing_house.fn_get_submission_table_column_types(int, character varying(255))
Returns character varying(255)[] As $$
	Declare columns character varying(255)[];
Begin

	Select array_agg(clearing_house.fn_java_type_to_PostgreSQL(c.data_type) order by c.column_id asc) Into columns
	From clearing_house.tbl_clearinghouse_submission_tables t
	Join clearing_house.tbl_clearinghouse_submission_xml_content_columns c
	  On c.table_id = t.table_id
	Where c.submission_id = $1
	  And t.table_name_underscored = $2
	Group By c.submission_id, t.table_name;
	
	return columns;
	
End $$ Language plpgsql;
/*****************************************************************************************************************************
**	Function	fn_select_xml_content_tables
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Returns all listed tables in a submission XML
**  Note
**	Uses
**	Used By
**	Revisions
******************************************************************************************************************************/
-- Select * From clearing_house.fn_select_xml_content_tables(2)
Create Or Replace Function clearing_house.fn_select_xml_content_tables(int)
Returns Table(
	submission_id		int,
	table_name			character varying(255),
	row_count           int
) As $$
Begin

    Return Query

        Select	d.submission_id																	as submission_id,
                --xnode(xml)																	as table_name,
                substring(d.xml::text from '^<([[:alnum:]]+).*>')::character varying(255)		as table_name,
                (xpath('./@length[1]', d.xml))[1]::text::int									as row_count
        From (
            Select x.submission_id, unnest(xpath('/sead-data-upload/*', x.xml)) As xml
            From clearing_house.tbl_clearinghouse_submissions as x
            Where 1 = 1
              And x.submission_id = $1
              And Not xml Is Null
              And xml Is Document
              
        ) d;

End $$ Language plpgsql;

/*****************************************************************************************************************************
**	Function	fn_select_xml_content_columns
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Returns all listed columns in a submission XML
**  Note        First (not cloned) record per table is selected
**	Uses    
**	Used By     fn_extract_and_store_submission_columns
**	Revisions
******************************************************************************************************************************/
-- Select * From clearing_house.fn_select_xml_content_columns(3)
Create Or Replace Function clearing_house.fn_select_xml_content_columns(int)
Returns Table(
	submission_id		int,
	table_name			character varying(255),
	column_name			character varying(255),
	column_type			character varying(255)
) As $$
Begin

    Return Query

        Select	d.submission_id                                   							as submission_id,
                d.table_name																as table_name,
                substring(d.xml::text from '^<([[:alnum:]]+).*>')::character varying(255)	as column_name,
                (xpath('./@class[1]', d.xml))[1]::character varying(255)					as column_type
        From (
            Select x.submission_id, t.table_name, unnest(xpath('/sead-data-upload/' || t.table_name || '/*[not(@clonedId)][1]/*', xml)) As xml
            From clearing_house.tbl_clearinghouse_submissions x
            Join clearing_house.fn_select_xml_content_tables($1) t
              On t.submission_id = x.submission_id
            Where 1 = 1
              And x.submission_id = $1
              And Not xml Is Null
              And xml Is Document
        ) as d;

End $$ Language plpgsql;

/*****************************************************************************************************************************
**	Function	fn_select_xml_content_records
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Returns all individual records found in a submission XML
**  Note
**	Uses
**	Used By     fn_extract_and_store_submission_records
**	Revisions
******************************************************************************************************************************/
-- Select * From clearing_house.fn_select_xml_content_records(2)

CREATE OR REPLACE FUNCTION clearing_house.fn_select_xml_content_records(IN integer)
  RETURNS TABLE(submission_id integer, table_name character varying, local_db_id integer, public_db_id_attr integer, public_db_id_tag integer) AS
$BODY$
Begin

    Return Query

        With submission_xml_data_rows As (
        
            Select x.submission_id,
				   unnest(xpath('/sead-data-upload/*/*', x.xml)) As xml
            From clearing_house.tbl_clearinghouse_submissions x
            Where Not xml Is Null
              And xml Is Document
              And x.submission_id = $1
        )
            Select v.submission_id,
                   v.table_name::character varying(255),
                   Case When v.local_db_id ~ '^[0-9\.]+$' Then v.local_db_id::numeric::int Else Null End,
                   Case When v.public_db_id_attribute ~ '^[0-9\.]+$' Then v.public_db_id_attribute::numeric::int Else Null End,
                   Case When v.public_db_id_value ~ '^[0-9\.]+$' Then v.public_db_id_value::numeric::int Else Null End
            From (
                Select	d.submission_id																			as submission_id,
                        replace(substring(d.xml::text from '^<([[:alnum:]\.]+).*>'), 'com.sead.database.', '')	as table_name,
                        ((xpath('./@id[1]', d.xml))[1])::character varying(255)									as local_db_id,
                        ((xpath('./@clonedId[1]', d.xml))[1])::character varying(255)							as public_db_id_attribute,
                        ((xpath('./clonedId/text()', d.xml))[1])::character varying(255)						as public_db_id_value
                From submission_xml_data_rows as d
            ) As v;

End $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION clearing_house.fn_select_xml_content_records(integer)
  OWNER TO clearinghouse_worker;


/*****************************************************************************************************************************
**	Function	fn_select_xml_content_values
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Returns all values found in a submission XML
**  Note
**	Uses
**	Used By     fn_extract_and_store_submission_values
**	Revisions
******************************************************************************************************************************/
-- Drop Function clearing_house.fn_select_xml_content_values(int, character varying(255))
-- Select * From clearing_house.fn_select_xml_content_values(2, 'TblAbundances') Where local_db_id = 766
CREATE OR REPLACE FUNCTION clearing_house.fn_select_xml_content_values(
	integer,
	character varying)
RETURNS TABLE(submission_id integer, table_name character varying, local_db_id integer, public_db_id integer, column_name character varying, column_type character varying, fk_local_db_id integer, fk_public_db_id integer, value text) 
    LANGUAGE 'plpgsql'
AS $BODY$
Begin

	Return Query 

		With record_xml As (
            Select x.submission_id, unnest(xpath('/sead-data-upload/' || $2 || '/*', x.xml))					As xml
            From clearing_house.tbl_clearinghouse_submissions x
            Where x.submission_id = $1
              And Not x.xml Is Null
              And x.xml Is Document
		), record_value_xml As (
            Select	x.submission_id																				As submission_id,
                    replace(substring(x.xml::text from '^<([[:alnum:]\.]+).*>'), 'com.sead.database.', '')		As table_name,
                    nullif((xpath('./@id[1]', x.xml))[1]::character varying(255), 'NULL')::numeric::int			As local_db_id,
                    nullif((xpath('./@clonedId[1]', x.xml))[1]::character varying(255), 'NULL')::numeric::int	As public_db_id,
                    unnest(xpath( '/*/*', x.xml))																As xml
            From record_xml x
		)   Select	$1																							As submission_id,
                    $2																							As table_name,
                    x.local_db_id																				As local_db_id,
                    x.public_db_id																				As public_db_id,
                    substring(x.xml::character varying(255) from '^<([[:alnum:]]+).*>')::character varying(255)	As column_name,
                    nullif((xpath('./@class[1]', x.xml))[1]::character varying, 'NULL')::character varying		As column_type,
                    nullif((xpath('./@id[1]', x.xml))[1]::character varying(255), 'NULL')::numeric::int			As fk_local_db_id,
                    nullif((xpath('./@clonedId[1]', x.xml))[1]::character varying(255), 'NULL')::numeric::int	As fk_public_db_id,
                    nullif((xpath('./text()', x.xml))[1]::text, 'NULL')::text									As value
            From record_value_xml x;

End 
$BODY$;

ALTER FUNCTION clearing_house.fn_select_xml_content_values(integer, character varying)
    OWNER TO clearinghouse_worker;


/*****************************************************************************************************************************
**	Function	fn_extract_and_store_submission_tables
**	Who			Roger Mähler
**	When		2013-10-14
**	What        Extracts and stores tables found in XML
**  Note
**	Uses        fn_select_xml_content_tables
**	Used By     fn_explode_submission_xml_to_rdb
**	Revisions
******************************************************************************************************************************/
-- Select clearing_house.fn_extract_and_store_submission_tables(2)
Create Or Replace Function clearing_house.fn_extract_and_store_submission_tables(int) Returns void As $$

Begin

	/* Delete existing data (cascade) */
	Delete From clearing_house.tbl_clearinghouse_submission_xml_content_values
		Where submission_id = $1;

	Delete From clearing_house.tbl_clearinghouse_submission_xml_content_columns
		Where submission_id = $1;

	Delete From clearing_house.tbl_clearinghouse_submission_xml_content_records
		Where submission_id = $1;

	Delete From clearing_house.tbl_clearinghouse_submission_xml_content_tables
		Where submission_id = $1;

	/* Register new tables not previously encountered */
	Insert Into clearing_house.tbl_clearinghouse_submission_tables (table_name, table_name_underscored)
		Select t.table_name, clearing_house.fn_pascal_case_to_underscore(t.table_name)
		From  clearing_house.fn_select_xml_content_tables($1) t
		Left Join clearing_house.tbl_clearinghouse_submission_tables x
		  On x.table_name = t.table_name
		Where x.table_name Is NULL;
	
	/* Store all tables that att exists in submission */
	Insert Into clearing_house.tbl_clearinghouse_submission_xml_content_tables (submission_id, table_id, record_count)
		Select t.submission_id, x.table_id, t.row_count
		From  clearing_house.fn_select_xml_content_tables($1) t
		Join clearing_house.tbl_clearinghouse_submission_tables x
		  On x.table_name = t.table_name
		;

	--Raise Notice 'XML entity tables extracted and stored for submission id %', $1;
	
End $$ Language plpgsql;
/*****************************************************************************************************************************
**	Function	fn_extract_and_store_submission_columns
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Stores column information for tables found in received XML
**  Note
**	Uses
**	Used By     fn_explode_submission_xml_to_rdb
**	Revisions
******************************************************************************************************************************/
-- Select clearing_house.fn_extract_and_store_submission_columns(2)
Create Or Replace Function clearing_house.fn_extract_and_store_submission_columns(int) Returns void As $$

Begin

	Delete From clearing_house.tbl_clearinghouse_submission_xml_content_columns
		Where submission_id = $1;
		
	/* Extract all unique column names */
	Insert Into clearing_house.tbl_clearinghouse_submission_xml_content_columns (submission_id, table_id, column_name, column_name_underscored, data_type, fk_flag, fk_table, fk_table_underscored)
		Select	c.submission_id,
				t.table_id,
				c.column_name,
				clearing_house.fn_pascal_case_to_underscore(c.column_name),
				c.column_type,
				left(c.column_type, 18) = 'com.sead.database.',
				Case When left(c.column_type, 18) = 'com.sead.database.' Then substring(c.column_type from 19) Else Null End,
				''
		From  clearing_house.fn_select_xml_content_columns($1) c
		Join clearing_house.tbl_clearinghouse_submission_tables t
		  On t.table_name = c.table_name
		Where c.submission_id = $1;

	Update clearing_house.tbl_clearinghouse_submission_xml_content_columns
		Set fk_table_underscored = clearing_house.fn_pascal_case_to_underscore(fk_table)
	Where submission_id = $1;

	--Raise Notice 'XML columns extracted and stored for submission id %', $1;
	
End $$ Language plpgsql;
/*****************************************************************************************************************************
**	Function	fn_extract_and_store_submission_records
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Stores all unique table rows found in XML in tbl_clearinghouse_submission_xml_content_records
**  Note
**	Uses        fn_select_xml_content_records
**	Used By     fn_explode_submission_xml_to_rdb
**	Revisions
******************************************************************************************************************************/
-- Select clearing_house.fn_extract_and_store_submission_records(2)
Create Or Replace Function clearing_house.fn_extract_and_store_submission_records(int) Returns void As $$

Begin

	/* Extract all unique records */
	Insert Into clearing_house.tbl_clearinghouse_submission_xml_content_records (submission_id, table_id, local_db_id, public_db_id)
		Select r.submission_id, t.table_id, r.local_db_id, coalesce(r.public_db_id_tag, public_db_id_attr)
		From clearing_house.fn_select_xml_content_records($1) r
		Join clearing_house.tbl_clearinghouse_submission_tables t
		  On t.table_name = r.table_name
		Where r.submission_id = $1;
		
	--Raise Notice 'XML record headers extracted and stored for submission id %', $1;
	
End $$ Language plpgsql;
/*****************************************************************************************************************************
**	Function	fn_extract_and_store_submission_values
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Extract values from XML and store in generic table clearing_house.tbl_clearinghouse_submission_xml_content_values
**  Note
**	Uses
**	Used By     fn_explode_submission_xml_to_rdb
**	Revisions
******************************************************************************************************************************/
-- Select clearing_house.fn_extract_and_store_submission_values(2)
Create Or Replace Function clearing_house.fn_extract_and_store_submission_values(int) Returns void As $$
	Declare x RECORD;
Begin

	For x In (Select t.*
			  From clearing_house.tbl_clearinghouse_submission_tables t
			  Join clearing_house.tbl_clearinghouse_submission_xml_content_tables c
			    On c.table_id = t.table_id
			  Where c.submission_id = $1)
	Loop

		Insert Into clearing_house.tbl_clearinghouse_submission_xml_content_values (submission_id, table_id, local_db_id, column_id, fk_flag, fk_local_db_id, fk_public_db_id, value)
			Select	$1,
					t.table_id,
					v.local_db_id,
					c.column_id,
					Not (v.fk_local_db_id Is Null),
					v.fk_local_db_id,
					v.fk_public_db_id,
					Case When v.value = 'NULL' Then NULL Else v.value End
			From clearing_house.fn_select_xml_content_values($1, x.table_name) v
			Join clearing_house.tbl_clearinghouse_submission_tables t
			  On t.table_name = v.table_name
			Join clearing_house.tbl_clearinghouse_submission_xml_content_columns c
			  On c.submission_id = v.submission_id
			 And c.table_id = t.table_id
			 And c.column_name = v.column_name;

	End Loop;		
	
	--Raise Notice 'XML entity field values extracted and stored for submission id %', $1;
	
End $$ Language plpgsql;
/*****************************************************************************************************************************
**	View        clearing_house.view_clearinghouse_local_fk_references
**	Who			Roger Mähler
**	When		2013-11-06
**	What		Gives FK-column that references a local record in the CHDB database
**  Note        Note that CHDB table is in underscore notation e.g. "tblAbundances"
**	Uses        fn_get_submission_table_column_names, fn_get_submission_table_column_types
**	Used By     fn_explode_submission_xml_to_rdb
**	Revisions
******************************************************************************************************************************/
-- Drop View clearing_house.view_clearinghouse_local_fk_references
-- Select * From clearing_house.view_clearinghouse_local_fk_references
Create Or Replace View clearing_house.view_clearinghouse_local_fk_references As

    Select v.submission_id, v.local_db_id, c.table_id, c.column_id, v.fk_local_db_id, /* v.fk_public_db_id, */ fk_t.table_id as fk_table_id, fk_c.column_id as fk_column_id --, fk_v.value::int as fk_id
    From clearing_house.tbl_clearinghouse_submission_xml_content_values v
    Join clearing_house.tbl_clearinghouse_submission_xml_content_columns c
      On c.submission_id = v.submission_id
     And c.table_id = v.table_id
     And c.column_id = v.column_id
    Join clearing_house.tbl_clearinghouse_submission_tables fk_t 
      On fk_t.table_name_underscored = c.fk_table_underscored
    Join clearing_house.view_clearinghouse_SEAD_rdb_schema_pk_columns s
      On s.table_schema = 'public'
     And s.table_name = fk_t.table_name_underscored
    Join clearing_house.tbl_clearinghouse_submission_xml_content_columns fk_c
      On fk_c.submission_id = v.submission_id
     And fk_c.table_id = fk_t.table_id
     And fk_c.column_name_underscored = s.column_name
    Join clearing_house.tbl_clearinghouse_submission_xml_content_values fk_v
      On fk_v.submission_id = v.submission_id
     And fk_v.table_id = fk_t.table_id
     And fk_v.column_id = fk_c.column_id
     And fk_v.local_db_id = v.fk_local_db_id
    Where v.fk_flag = true
;
/*****************************************************************************************************************************
**	Function	fn_copy_extracted_values_to_entity_table
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Copies explodes (vertical) XML data to corresponding CHDB table
**  Note        Note that CHDB table is in underscore notation e.g. "tblAbundances"
**	Uses        fn_get_submission_table_column_names, fn_get_submission_table_column_types
**	Used By     fn_explode_submission_xml_to_rdb
**	Revisions
******************************************************************************************************************************/
-- Drop Function explode_submission_xml_to_rdb(int);
-- 	Select clearing_house.fn_copy_extracted_values_to_entity_table(2, 'tbl_taxa_tree_genera')
--	Select clearing_house.fn_get_submission_table_column_names(2, 'tbl_locations');
Create Or Replace Function clearing_house.fn_copy_extracted_values_to_entity_table(int, character varying(255)) Returns text As $$

	Declare schema_columns character varying(255)[];
	Declare submission_columns character varying(255)[];
	Declare submission_column_types character varying(255)[];
	
	Declare insert_columns_string text;
	Declare select_columns_string text;
	Declare public_columns_string text;
	Declare public_key_columns_string text;
	
	Declare sql text;
	Declare i integer;
	
Begin

	If clearing_house.fn_table_exists($2) = false Then
		Raise Exception 'Table does not exist: %', $2;
		Return Null;
	End If;  

	sql := 'Delete From clearing_house.' || $2 || ' Where submission_id = ' || $1::character varying(20) || ';';
	
	--Execute sql;

	submission_columns := clearing_house.fn_get_submission_table_column_names($1, $2);

	If Not (submission_columns is Null or array_length(submission_columns, 1) = 0) Then

		submission_column_types := clearing_house.fn_get_submission_table_column_types($1, $2);

		insert_columns_string := array_to_string(submission_columns, ', ');
		
		select_columns_string := '';
		For i In array_lower(submission_columns, 1) .. array_upper(submission_columns, 1)
		Loop

			select_columns_string := select_columns_string || ' v.values[' || i::text || ']::' || submission_column_types[i] || Case When i < array_upper(submission_columns, 1) Then ', ' Else '' End;

		End Loop;

		/*
		If Not submission_columns <@ clearing_house.fn_get_schema_table_column_names($2) Then
			Raise Exception 'XML contains unknown columns for table % [%] [%]', $2, array_to_string(submission_columns, ','), array_to_string(clearing_house.fn_get_schema_table_column_names($2), ',');
			Return Null;
		End If;
		*/

		insert_columns_string := replace(insert_columns_string, 'cloned_id', 'public_db_id');

		/* Insert values to entity tables. Insert Local DB id attribute (ref_id) if the attribute is a FK */
		sql := sql || 'Insert Into clearing_house.' || $2 || ' (submission_id, source_id, local_db_id, ' || insert_columns_string || ') 
			Select v.submission_id, 1 as source_id, -v.local_db_id, ' || select_columns_string || '
			From (
				Select v.submission_id, t.table_name, v.local_db_id, array_agg(
					   Case when v.fk_flag = TRUE Then
							Case When Not v.fk_public_db_id Is Null And r.fk_local_db_id Is Null Then v.fk_public_db_id::text Else (-v.fk_local_db_id)::text End
					   Else v.value End
					Order by c.column_id asc
				) as values
				From clearing_house.tbl_clearinghouse_submission_xml_content_values v

				Join clearing_house.tbl_clearinghouse_submission_tables t
				  On t.table_id = v.table_id

				Join clearing_house.tbl_clearinghouse_submission_xml_content_columns c
				  On c.submission_id = v.submission_id
				 And c.table_id = t.table_id
				 And c.column_id = v.column_id

                /* Check if public record pointed to by FK exists in local DB. In such case set FK value to -fk_local_db_id */
                Left Join clearing_house.view_clearinghouse_local_fk_references r
                  On v.fk_flag = TRUE
                 And r.submission_id = v.submission_id
                 And r.table_id = t.table_id
                 And r.column_id = c.column_id
                 And r.local_db_id = v.local_db_id
                 And r.fk_local_db_id = v.fk_local_db_id

				Where 1 = 1
				  And v.submission_id = ' || $1::character varying(20) || '
				  And t.table_name_underscored = ''' || $2 || '''
				Group By v.submission_id, t.table_name, v.local_db_id
			) as v
		';



		Raise Notice 'Inserted %', sql;
		
		Execute sql;
	
	End If;  


	/* Insert explicilty referenced public data */
	
/*
	public_columns_string := array_to_string(clearing_house.fn_get_public_table_column_names('public', $2), ', ');
	public_key_columns_string := clearing_house.fn_get_public_table_key_column_name('public', $2);
	
	sql := 'Insert Into clearing_house.' || $2 || ' (submission_id, source_id, local_db_id, public_db_id, ' || public_columns_string || ') 
		Select ' || $1::text || ' as submission_id, 2 as source_id, r.local_db_id, e.' || public_key_columns_string || ', ' || public_columns_string || '
		From public.' || $2 || ' e
		Join clearing_house.tbl_clearinghouse_submission_xml_content_records r
		  On r.submission_id = ' || $1::text || '
		 And r.public_db_id = e.' || public_key_columns_string || '
		Join clearing_house.tbl_clearinghouse_submission_tables t
		  On t.table_id = r.table_id
		Where r.submission_id = ' || $1::text || '
		  And t.table_name_underscored = ''' || $2 || ''' 
		  And Not r.public_db_id Is NULL
	';
*/

	Execute sql;

	--Raise Notice 'Copied data: %', sql;

	Return sql;
	
End $$ Language plpgsql;

/*****************************************************************************************************************************
**	Function	fn_copy_extracted_values_to_entity_tables
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Copies extracted XML values to entity specific CHDB tables
**  Note        
**	Uses        fn_rdb_schema_add_new_columns
**              fn_copy_extracted_values_to_entity_table
**	Used By     fn_explode_submission_xml_to_rdb
**	Revisions
******************************************************************************************************************************/
-- Select clearing_house.fn_copy_extracted_values_to_entity_tables(2)
Create Or Replace Function clearing_house.fn_copy_extracted_values_to_entity_tables(p_submission_id int, p_dry_run = FALSE, p_add_missing_columns boolean = FALSE)
Returns void As $$
	Declare x RECORD;
Begin

	For x In (
        Select t.*
        From clearing_house.tbl_clearinghouse_submission_tables t
        Join clearing_house.tbl_clearinghouse_submission_xml_content_tables c
        On c.table_id = t.table_id
        Where c.submission_id = p_submission_id
	) Loop

		--Raise Notice 'Executing table: %', x.table_name_underscored;

        If (p_add_missing_columns) Then
		    Perform clearing_house.fn_add_new_public_db_columns(p_submission_id, x.table_name_underscored);
        End If;
        
        If Not (p_dry_run) Then
            Perform clearing_house.fn_copy_extracted_values_to_entity_table(p_submission_id, x.table_name_underscored);
        End If;
        
        Raise Notice 'clearing_house.fn_copy_extracted_values_to_entity_table(%, ''%'');', p_submission_id, x.table_name_underscored;

	End Loop;	
	
	--Raise Notice 'XML entity field values extracted and stored for submission id %', p_submission_id;
	
End $$ Language plpgsql;
/*****************************************************************************************************************************
**	Function	fn_explode_submission_xml_to_rdb
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Explodes uploaded XML data to CHDB RDB tables
**  Note
**	Uses        fn_extract_and_store_submission_tables
**              fn_extract_and_store_submission_columns
**              fn_extract_and_store_submission_records
**              fn_extract_and_store_submission_values
**              fn_copy_extracted_values_to_entity_tables
**	Used By     Clearing House "Process submission" use case (PHP process).
**	Revisions
******************************************************************************************************************************/
-- Drop Function explode_submission_xml_to_rdb(int);
-- Select clearing_house.fn_explode_submission_xml_to_rdb(2)
Create Or Replace Function clearing_house.fn_explode_submission_xml_to_rdb(submission_id int) Returns void As $$

Begin

	Perform clearing_house.fn_extract_and_store_submission_tables(submission_id);
	Perform clearing_house.fn_extract_and_store_submission_columns(submission_id);
	Perform clearing_house.fn_extract_and_store_submission_records(submission_id);
	Perform clearing_house.fn_extract_and_store_submission_values(submission_id);

    /* FIX OF WRONG NAMES in EXCEL/XML */
    update clearing_house.tbl_clearinghouse_submission_xml_content_columns
        set column_name = 'address_1', column_name_underscored = 'address_1'
    where column_name = 'address1';

    update clearing_house.tbl_clearinghouse_submission_xml_content_columns
        set column_name = 'address_2', column_name_underscored = 'address_2'
    where column_name = 'address2';

	Perform clearing_house.fn_copy_extracted_values_to_entity_tables(submission_id);

End $$ Language plpgsql;

