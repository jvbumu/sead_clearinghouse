/*****************************************************************************************************************************
**	Function	fn_DD2DMS
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Converts geoposition DD to DMS
**	Uses
**	Used By
**	Revisions
******************************************************************************************************************************/
Create Or Replace Function clearing_house.fn_DD2DMS(
	p_dDecDeg       IN FLOAT,
    p_sDegreeSymbol IN VARCHAR(1) = 'd',
    p_sMinuteSymbol IN VARCHAR(1) = 'm',
    p_sSecondSymbol IN VARCHAR(1) = 's'
)
Returns VARCHAR(50) As
$$
DECLARE
   v_iDeg INT;
   v_iMin INT;
   v_dSec FLOAT;
Begin

   v_iDeg := Trunc(p_dDecDeg)::INT;
   v_iMin := Trunc((Abs(p_dDecDeg) - Abs(v_iDeg)) * 60)::int;
   v_dSec := Round(((((Abs(p_dDecDeg) - Abs(v_iDeg)) * 60) - v_iMin) * 60)::numeric, 3)::float;

   Return trim(to_char(v_iDeg,'9999')) || p_sDegreeSymbol::text || trim(to_char(v_iMin,'99')) || p_sMinuteSymbol::text ||
          Case When v_dSec = 0::FLOAT Then '0' Else replace(trim(to_char(v_dSec,'99.999')),'.000','') End || p_sSecondSymbol::text;

End $$ Language plpgsql;
/*****************************************************************************************************************************
**	Function	fn_pascal_case_to_underscore
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Converts PascalCase to pascal_case
**	Uses
**	Used By
**	Revisions
******************************************************************************************************************************/
-- Select fn_pascal_case_to_underscore('RogerMahler')
Create Or Replace Function clearing_house.fn_pascal_case_to_underscore(character varying(255))
Returns character varying(255) As $$
Begin
	return lower(Left($1, 1) || regexp_replace(substring($1 from 2), E'([A-Z])', E'\_\\1','g'));
End $$ Language plpgsql;
/*****************************************************************************************************************************
**	Function	fn_java_type_to_PostgreSQL
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Converts Java type to PostgreSQL data type
**	Uses
**	Used By
**	Revisions
******************************************************************************************************************************/
-- Select fn_pascal_case_to_underscore('RogerMahler')
CREATE OR REPLACE FUNCTION clearing_house.fn_java_type_to_postgresql(
	character varying)
RETURNS character varying
    LANGUAGE 'plpgsql'
AS $BODY$
Begin
	If (lower($1) in ('java.util.date', 'java.sql.date')) Then
		return 'date';
	End If;

	If (lower($1) in ('java.math.bigdecimal', 'java.lang.double')) Then
		return 'numeric';
	End If;

	If (lower($1) in ('java.lang.integer', 'java.util.integer', 'java.long.short')) Then
		return 'integer';
	End If;

	If (lower($1) = 'java.lang.boolean') Then
		return 'boolean';
	End If;

	If (lower($1) in ('java.lang.string', 'java.lang.character')) Then
		return 'text';
	End If;

	If ($1 Like 'com.sead.database.Tbl%' or $1 Like 'Tbl%') Then
		return 'integer'; /* FK */
	End If;

	Raise Exception 'Fatal error: Java type % encountered in XML not expected', $1;

End

$BODY$;

/*****************************************************************************************************************************
**	Function	fn_clearinghouse_check_submission_length_exceeded
**	Who			Roger Mähler
**	What		Find string field values that exceeds DB varchar max length
******************************************************************************************************************************/
-- Drop Function clearing_house.fn_clearinghouse_check_submission_length_exceeded(p_submission_id int);
Create Or Replace Function clearing_house.fn_clearinghouse_check_submission_length_exceeded(p_submission_id int)
Returns Table (
	submission_id				int,
	table_name                  character varying,
	column_name                 character varying,
	data_type                   character varying,
	value_length                int,
	character_maximum_length	int,
    value                       character varying
) As $$
Declare z RECORD;
Begin
    Return Query
        SELECT p_submission_id, s.table_name_underscored, c.column_name_underscored, c.data_type, length(v.value) as value_length, x.character_maximum_length, v.value::character varying
        FROM clearing_house.tbl_clearinghouse_submission_xml_content_values v
        JOIN clearing_house.tbl_clearinghouse_submission_xml_content_tables t
          ON v.table_id = t.table_id
        JOIN clearing_house.tbl_clearinghouse_submission_xml_content_columns c
          ON c.column_id = v.column_id
        JOIN clearing_house.tbl_clearinghouse_submission_tables s
          ON s.table_id = t.table_id
        JOIN clearing_house.fn_dba_get_sead_public_db_schema('public', 'sead_master') x
          ON x.table_name = s.table_name_underscored
         AND x.column_name = c.column_name_underscored
        WHERE v.submission_id = p_submission_id
          AND c.data_type Like '%String'
          AND Not x.character_maximum_length IS NULL
          AND length(v.value) > x.character_maximum_length;
End $$ Language plpgsql;
/*****************************************************************************************************************************
**	Function	fn_table_exists
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Checks if table exists in current DB-schema
**	Uses
**	Used By
**	Revisions
******************************************************************************************************************************/
-- Select fn_table_exists('tbl_submission_xml_content_meta_tables')
Create Or Replace Function clearing_house.fn_table_exists(character varying(255))
Returns Boolean As $$
	Declare exists Boolean;
Begin

	Select Count(*) > 0 Into exists
		From information_schema.tables
		Where table_catalog = CURRENT_CATALOG
		  And table_schema = CURRENT_SCHEMA
		  And table_name = $1;

	return exists;

End $$ Language plpgsql;
/*****************************************************************************************************************************
**	Function	fn_get_schema_table_column_names
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Returns table columns as an array
**	Uses
**	Used By
**	Revisions
******************************************************************************************************************************/
-- Select clearing_house.fn_get_schema_table_column_names('tbl_submission_xml_content_meta_columns')
Create Or Replace Function clearing_house.fn_get_schema_table_column_names(character varying(255))
Returns character varying(255)[] As $$
	Declare columns character varying(255)[];
Begin

	Select array_agg(column_name::character varying(255)) Into columns
		From information_schema.columns
		Where table_catalog = CURRENT_CATALOG
		  And table_schema = CURRENT_SCHEMA
		  And table_name = $1;

	return columns;

End $$ Language plpgsql;
/*****************************************************************************************************************************
**	Function	fn_to_integer
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Returns table columns as an array
**	Uses
**	Used By
**	Revisions
******************************************************************************************************************************/
-- Select fn_to_integer('2')
Create Or Replace Function clearing_house.fn_to_integer(character varying(255))
Returns int As $$
Begin
	Return Case When ($1 ~ '^[0-9]+$') Then $1::int Else null End;
End $$ Language plpgsql;

/*****************************************************************************************************************************
**	Function	fn_get_entity_type_for
**	Who			Roger Mähler
**	When		2013-10-14
**	What		Returns entity type for table
**	Uses
**	Used By
**	Revisions
******************************************************************************************************************************/
-- Select clearing_house.fn_get_entity_type_for('tbl_sites')
Create Or Replace Function clearing_house.fn_get_entity_type_for(character varying(255))
Returns int As $$
Declare
    table_entity_type_id int;
Begin
    Select x.entity_type_id Into table_entity_type_id
    From clearing_house.tbl_clearinghouse_reject_entity_types x
    Join clearing_house.tbl_clearinghouse_submission_tables t
      On x.table_id = t.table_id
    Where table_name_underscored = $1;

    Return Coalesce(table_entity_type_id,0);
End $$ Language plpgsql;

/*****************************************************************************************************************************
**	Function	xml_transfer_bulk_upload
**	Who			Roger Mähler
**	When		2017-10-26
**	What
**	Uses
**	Used By
**	Revisions
******************************************************************************************************************************/
-- Select * from clearing_house.tbl_clearinghouse_submissions where not xml is null
-- Select clearing_house.xml_transfer_bulk_upload(1)
Create Or Replace Function clearing_house.xml_transfer_bulk_upload(p_submission_id int = null, p_xml_id int = null, p_upload_user_id int = 4)
Returns int As $$
Begin

	p_xml_id = Coalesce(p_xml_id, (Select Max(ID) from clearing_house.tbl_clearinghouse_xml_temp));

	If p_submission_id Is Null Then

        Select Coalesce(Max(submission_id),0) + 1
        Into p_submission_id
        From clearing_house.tbl_clearinghouse_submissions;

        Insert Into clearing_house.tbl_clearinghouse_submissions(submission_id, submission_state_id, data_types, upload_user_id,
            upload_date, upload_content, xml, status_text, claim_user_id, claim_date_time)

            Select p_submission_id, 1, 'Undefined other', p_upload_user_id, now(), null, xmldata, 'New', null, null
            From clearing_house.tbl_clearinghouse_xml_temp
            Where id = p_xml_id;
    Else

		Update clearing_house.tbl_clearinghouse_submissions
        	Set XML = X.xmldata
        From clearing_house.tbl_clearinghouse_xml_temp X
        Where clearing_house.tbl_clearinghouse_submissions.submission_id = p_submission_id
          And X.id = p_xml_id;

    End If;

    Return p_submission_id;
End $$ Language plpgsql;

/*****************************************************************************************************************************
**	Function	fn_sead_table_entity_name
**	Who			Roger Mähler
**	When		2018-10-21
**	What        Computes a noun from a sead table name in singular form
**	Uses
**	Used By     Clearinghouse transfer & commit
**	Revisions
******************************************************************************************************************************/
CREATE OR REPLACE FUNCTION clearing_house.fn_sead_table_entity_name(p_table_name text)
RETURNS information_schema.sql_identifier AS $$
Begin
	return Replace(Case When p_table_name Like  '%ies' Then regexp_replace(p_table_name, 'ies$', 'y')
		 When Not p_table_name Like '%status' Then rtrim(p_table_name, 's')
		 Else p_table_name End, 'tbl_', '')::information_schema.sql_identifier As entity_name;
End; $$ language plpgsql;