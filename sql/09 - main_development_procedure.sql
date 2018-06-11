/*****************************************************************************************************************************
**	Function	fn_clearinghouse_main_development_procedure
**	Who			Roger Mähler
**	When		2013-10-21
**	What		Main procedure used in development to create DB schemas
**	Uses
**	Used By
**	Revisions   OBSELETE!
******************************************************************************************************************************/
-- Select clearing_house.fn_get_submission_table_column_names(2, 'tbl_abundances')
Create Or Replace Function clearing_house.fn_clearinghouse_main_development_procedure()
Returns void As $$
Declare z RECORD;
Begin

	/* Create CHDB specific data tables */

	Execute clearing_house.fn_dba_create_clearing_house_db_model();

	/* Transfer PDB column catalog to CHDB */

	-- Execute clearing_house.fn_dba_create_clearing_house_db_model();
    -- Select clearing_house.fn_dba_populate_clearing_house_db_model();
	/* Create CHDB entity tables */

	Execute clearing_house.fn_create_public_db_entity_tables('clearing_house');

	/* TEST: Process av NEW submissions */

	For z In
		Select *
		From clearing_house.tbl_clearinghouse_submissions
		Where submission_state_id = 1
		Order By submission_id
	Loop
		Execute clearing_house.fn_explode_submission_xml_to_rdb(2);
	End Loop;

End $$ Language plpgsql;


