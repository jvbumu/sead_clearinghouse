
/*****************************************************************************************************************************
**	Function	fn_clearinghouse_report_feature_types
**	Who			Roger Mähler
**	When		2018-03-29
**	What		Displays feature types data
**	Uses
**	Used By
**	Revisions
******************************************************************************************************************************/
-- Drop Function clearing_house.fn_clearinghouse_report_feature_types(int);
-- Select * From clearing_house.fn_clearinghouse_report_feature_types(1)
Create Or Replace Function clearing_house.fn_clearinghouse_report_feature_types(int)
Returns Table (
	local_db_id                         int,
    type_name                           character varying,
    description                         text,
	public_db_id                        int,
    public_type_name                    character varying,
    public_description                  text,
	date_updated                        text,
	entity_type_id                      int
) As $$

Declare
    entity_type_id int;
Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_feature_types');

	Return Query

        Select
            LDB.local_db_id                       	As local_db_id,
            LDB.type_name                           As type_name,
            LDB.description		                    As description,
            LDB.public_db_id                        As public_db_id,
            RDB.type_name                           As public_type_name,
            RDB.description		                    As public_description,
            to_char(LDB.date_updated,'YYYY-MM-DD')	As date_updated,
            entity_type_id                          As entity_type_id

        From (

            Select
                ft.submission_id                    As submission_id,
                ft.source_id                        As source_id,
                ft.local_db_id					    As local_db_id,
                ft.public_db_id					    As public_db_id,
                ft.feature_type_name                As type_name,
                ft.feature_type_description		    As description,
                ft.date_updated					    As date_updated

            From clearing_house.view_feature_types ft

        ) As LDB

        Left Join (

            Select
                ft.feature_type_id                  As feature_type_id,
                ft.feature_type_name                As type_name,
                ft.feature_type_description		    As description

            From public.tbl_feature_types ft

        ) As RDB
          On RDB.feature_type_id = LDB.public_db_id

        Where LDB.source_id = 1
          And LDB.submission_id = $1
        Order By LDB.type_name;

End $$ Language plpgsql;

Do $$
Declare v_next_id int;
Begin
   If (Select Count(*) From clearing_house.tbl_clearinghouse_reports Where report_procedure like '%fn_clearinghouse_report_feature_types%') = 0 Then

        Select Max(report_id) + 1 Into v_next_id From clearing_house.tbl_clearinghouse_reports;

        Insert Into clearing_house.tbl_clearinghouse_reports (report_id, report_name, report_procedure)
            Values  (v_next_id, 'Feature types', 'Select * From clearing_house.fn_clearinghouse_report_feature_types(?)');

        Raise Notice 'Report wdded with ID: %', v_next_id;

    End If;

End $$ Language plpgsql;

/*****************************************************************************************************************************
**	Function	fn_clearinghouse_report_sample_group_dimensions
**	Who			Roger Mähler
**	When		2018-03-29
**	What		Displays sample group dimensions
**	Uses
**	Used By
**	Revisions
******************************************************************************************************************************/
Drop Function clearing_house.fn_clearinghouse_report_sample_group_dimensions(int);
-- Select * From clearing_house.fn_clearinghouse_report_sample_group_dimensions(1)
Create Or Replace Function clearing_house.fn_clearinghouse_report_sample_group_dimensions(int)
Returns Table (
	local_db_id                         int,
	sample_group_id                     int,
    sample_group_name                   character varying,
    dimension_name                      character varying,
    dimension_value                     numeric(20,5),

	public_db_id                        int,
	public_sample_group_id              int,
    public_sample_group_name            character varying,
    public_dimension_name               character varying,
    public_dimension_value              numeric(20,5),

	date_updated                        text,
	entity_type_id                      int
) As $$

Declare
    entity_type_id int;
Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_sample_group_dimensions');

	Return Query


        Select
            LDB.local_db_id						            As local_db_id,
            LDB.sample_group_id					           	As sample_group_id,
            LDB.sample_group_name							As sample_group_name,
            LDB.dimension_name								As dimension_name,
            LDB.dimension_value								As dimension_value,

            LDB.public_db_id						        As public_db_id,
            RDB.sample_group_id						        As public_sample_group_id,
            RDB.sample_group_name							As public_sample_group_name,
            RDB.dimension_name								As public_dimension_name,
            RDB.dimension_value								As public_dimension_value,

            to_char(LDB.date_updated,'YYYY-MM-DD')			As date_updated,
            entity_type_id						            As entity_type_id

        From (

            Select	sgd.submission_id				        As submission_id,
                    sgd.source_id					        As source_id,
                    sgd.local_db_id				            As local_db_id,
                    sgd.public_db_id				        As public_db_id,
                    sgd.sample_group_id			            As sample_group_id,
                    sgd.dimension_value			            As dimension_value,
                    sgd.date_updated				        As date_updated,
                    sg.sample_group_name			        As sample_group_name,
                    d.dimension_name				        As dimension_name

            From clearing_house.view_sample_group_dimensions sgd
            Join clearing_house.view_dimensions d
              On d.merged_db_id = sgd.dimension_id
             And d.submission_id In (0, sgd.submission_id)
            Join clearing_house.view_sample_groups sg
              On sg.merged_db_id = sgd.sample_group_id
             And sg.submission_id In (0, sgd.submission_id)

        ) As LDB

        Left Join (

            Select 	sgd.sample_group_id				        As sample_group_id,
                    sgd.dimension_value				        As dimension_value,
                    sg.sample_group_name				    As sample_group_name,
                    d.dimension_name					    As dimension_name

            From public.tbl_sample_group_dimensions as sgd
            Join public.tbl_dimensions d
              On sgd.dimension_id = d.dimension_id
            Join public.tbl_sample_groups sg
              On sg.sample_group_id = sgd.sample_group_id

        ) as RDB
          On RDB.sample_group_id = LDB.public_db_id

        Where LDB.source_id = 1
          And LDB.submission_id = $1

        Order by LDB.sample_group_id;

End $$ Language plpgsql;

Do $$
Declare v_next_id int;
Begin
   If (Select Count(*) From clearing_house.tbl_clearinghouse_reports Where report_procedure like '%fn_clearinghouse_report_sample_group_dimensions%') = 0 Then

        Select Max(report_id) + 1 Into v_next_id From clearing_house.tbl_clearinghouse_reports;

        Insert Into clearing_house.tbl_clearinghouse_reports (report_id, report_name, report_procedure)
            Values  (v_next_id, 'Sample group dimensions', 'Select * From clearing_house.fn_clearinghouse_report_sample_group_dimensions(?)');

        Raise Notice 'Report added with ID: %', v_next_id;

    End If;

End $$ Language plpgsql;

/*****************************************************************************************************************************
**	Function	fn_clearinghouse_report_sample_dimensions
**	Who			Roger Mähler
**	When		2018-03-29
**	What		Displays sample group dimensions
**	Uses
**	Used By
**	Revisions
******************************************************************************************************************************/
-- Drop Function clearing_house.fn_clearinghouse_report_sample_dimensions(int);
-- Select * From clearing_house.fn_clearinghouse_report_sample_dimensions(1)
Create Or Replace Function clearing_house.fn_clearinghouse_report_sample_dimensions(int)
Returns Table (
	local_db_id                         int,
	physical_sample_id                  int,
    sample_name                         character varying,
    dimension_name                      character varying,
    dimension_value                     numeric(20,5),

	public_db_id                        int,
	public_physical_sample_id           int,
    public_sample_name                  character varying,
    public_dimension_name               character varying,
    public_dimension_value              numeric(20,5),

	date_updated                        text,
	entity_type_id                      int
) As $$

Declare
    entity_type_id int;
Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_sample_dimensions');

	Return Query

        Select
            LDB.local_db_id						            As local_db_id,
            LDB.physical_sample_id					        As physical_sample_id,
            LDB.sample_name							        As sample_name,
            LDB.dimension_name								As dimension_name,
            LDB.dimension_value								As dimension_value,

            LDB.public_db_id						        As public_db_id,
            RDB.physical_sample_id						    As public_physical_sample_id,
            RDB.sample_name							        As public_sample_name,
            RDB.dimension_name								As public_dimension_name,
            RDB.dimension_value								As public_dimension_value,

            to_char(LDB.date_updated,'YYYY-MM-DD')			As date_updated,
            entity_type_id						            As entity_type_id

        From (

            Select	sd.submission_id				        As submission_id,
                    sd.source_id					        As source_id,
                    sd.local_db_id				            As local_db_id,
                    sd.public_db_id				            As public_db_id,
                    ps.physical_sample_id                   As physical_sample_id,
                    ps.sample_name			                As sample_name,
                    d.dimension_name				        As dimension_name,
                    sd.dimension_value			            As dimension_value,
                    sd.date_updated				            As date_updated

            From clearing_house.view_sample_dimensions sd
            Join clearing_house.view_dimensions d
              On d.merged_db_id = sd.dimension_id
             And d.submission_id In (0, sd.submission_id)
            Join clearing_house.view_physical_samples ps
              On ps.merged_db_id = sd.physical_sample_id
             And ps.submission_id In (0, sd.submission_id)

        ) As LDB

        Left Join (

            Select 	sd.sample_dimension_id                  As sample_dimension_id,
                    ps.physical_sample_id				    As physical_sample_id,
                    ps.sample_name				            As sample_name,
                    d.dimension_name					    As dimension_name,
                    sd.dimension_value				        As dimension_value
            From public.tbl_sample_dimensions sd
            Join public.tbl_dimensions d
              On d.dimension_id = sd.dimension_id
            Join public.tbl_physical_samples ps
              On ps.physical_sample_id = sd.physical_sample_id

        ) as RDB
          On RDB.sample_dimension_id = LDB.public_db_id

        Where LDB.source_id = 1
          And LDB.submission_id = $1

        Order by LDB.physical_sample_id;

End $$ Language plpgsql;

Do $$
Declare v_next_id int;
Begin
   If (Select Count(*) From clearing_house.tbl_clearinghouse_reports Where report_procedure like '%fn_clearinghouse_report_sample_dimensions%') = 0 Then

        Select Max(report_id) + 1 Into v_next_id From clearing_house.tbl_clearinghouse_reports;

        Insert Into clearing_house.tbl_clearinghouse_reports (report_id, report_name, report_procedure)
            Values  (v_next_id, 'Sample dimensions', 'Select * From clearing_house.fn_clearinghouse_report_sample_dimensions(?)');

        Raise Notice 'Report added with ID: %', v_next_id;

    End If;

End $$ Language plpgsql;




