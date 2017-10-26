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
CREATE OR REPLACE FUNCTION clearing_house.fn_java_type_to_postgresql(character varying)
  RETURNS character varying AS
$BODY$
Begin
	If ($1 in ('java.util.Date', 'java.sql.Date')) Then
		return 'date';
	End If;
	
	If ($1 in ('java.math.BigDecimal', 'java.lang.Double')) Then
		return 'numeric';
	End If;
	
	If ($1 in ('java.lang.Integer', 'java.util.Integer', 'java.long.Short')) Then
		return 'integer';
	End If;


	If ($1 = 'java.lang.Boolean') Then
		return 'boolean';
	End If;

	If ($1 in ('java.lang.String', 'java.lang.Character')) Then
		return 'text';
	End If;

	If ($1 Like 'com.sead.database.%') Then
		return 'integer'; /* FK */
	End If;

	Raise Exception 'Fatal error: Java type % encountered in XML not expected', $1;
	
End $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION clearing_house.fn_java_type_to_postgresql(character varying)
  OWNER TO clearinghouse_worker;

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

