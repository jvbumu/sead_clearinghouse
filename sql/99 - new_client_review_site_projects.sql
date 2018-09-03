/* Displayed when site-node is clicked */

With project_sites As (
    Select p.merged_db_id as project_id, s.merged_db_id as site_id
    From clearing_house.view_projects p
    Join clearing_house.view_datasets d
      On p.merged_db_id = d.project_id
     And d.submission_id In (0, p.submission_id)
    Join clearing_house.view_analysis_entities ae
      On d.merged_db_id = ae.dataset_id
     And ae.submission_id In (0, p.submission_id)
    Join clearing_house.view_physical_samples ps
      On ps.merged_db_id = ae.physical_sample_id
     And ps.submission_id In (0, p.submission_id)
    Join clearing_house.view_sample_groups sg
      On sg.merged_db_id = ps.sample_group_id
     And sg.submission_id In (0, p.submission_id)
    Join clearing_house.view_sites s
      On s.merged_db_id = sg.site_id
     And s.submission_id In (0, p.submission_id)
    Where p.submission_id = 1
    Group By p.merged_db_id, s.merged_db_id
)
        Select	p.source_id                             As source_id,
                p.submission_id                         As submission_id,
                s.local_db_id								As site_id,
                p.local_db_id							As local_db_id,
                p.public_db_id						    As public_db_id,

                s.site_name								As site_name,
                p.project_name								As project_name,
                p.project_abbrev_name							As project_abbrev,
                p.description								As description,
                prs.stage_name ||', '|| pt.project_type_name 				As project_type,
                p.date_updated								As date_updated

        From project_sites xx
        Join clearing_house.view_projects p
          On p.merged_db_id = xx.project_id
        Join clearing_house.view_project_types pt
          On pt.merged_db_id = p.project_type_id
         And pt.submission_id In (0, p.submission_id)
        Join clearing_house.view_project_stages prs
          On prs.merged_db_id = p.project_stage_id
         And prs.submission_id In (0, p.submission_id)
        Join clearing_house.view_sites s
          On s.merged_db_id = xx.site_id
         And s.submission_id In (0, p.submission_id)
        Where p.submission_id = 1

CREATE OR REPLACE FUNCTION clearing_house.fn_clearinghouse_review_projects_client_data(
    IN integer,
    IN integer)
  RETURNS TABLE(project_id integer,
  site_id integer,
  site_name character varying,
  project_name character varying,
  project_abbrev character varying,
  project_type character varying,
  description character varying,
  public_db_id integer,
  public_site_id integer,
  public_site_name character varying,
  public_project_name character varying,
  public_project_abbrev character varying,
  public_project_type character varying,
  public_description character varying,
  date_updated text,
  entity_type_id integer) AS
$BODY$
Declare
    entity_type_id int;
Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_projects');

	Return Query

	Select distinct
			LDB.local_db_id				               					As project_id,

			LDB.site_id										As site_id,
			LDB.site_name										As site_name,
			LDB.project_name									As project_name,
			LDB.project_abbrev									As project_abbrev,
			LDB.project_type									As project_type,
			LDB.description										As description,

			LDB.public_db_id				            				As public_db_id,

			RDB.site_id										As public_site_id,
			RDB.site_name										As public_site_name,
			RDB.project_name									As public_project_name,
			RDB.project_abbrev									As public_project_abbrev,
			LDB.project_type									As public_project_type,
			RDB.description										As public_description,

			to_char(LDB.date_updated,'YYYY-MM-DD')							As date_updated,
			entity_type_id										As entity_type_id

		From (
			Select		p.source_id                                         			As source_id,
					p.submission_id                                     			As submission_id,
					s.local_db_id								As site_id,
					p.local_db_id								As local_db_id,
					p.public_db_id								As public_db_id,

					s.site_name								As site_name,
					p.project_name								As project_name,
					p.project_abbrev_name							As project_abbrev,
					p.description								As description,
					prs.stage_name ||', '|| pt.project_type_name 				As project_type,
					p.date_updated								As date_updated





			From clearing_house.view_projects p
			Join clearing_house.view_project_types pt
			  On pt.merged_db_id = p.project_type_id
			 And pt.submission_id In (0, p.submission_id)
			Join clearing_house.view_project_stages prs
			  On prs.merged_db_id = p.project_stage_id
			 And prs.submission_id In (0, p.submission_id)
			Join clearing_house.view_datasets d
			  On p.merged_db_id = d.project_id
			 And d.submission_id In (0, p.submission_id)
			Join clearing_house.view_analysis_entities ae
			  On d.merged_db_id = ae.dataset_id
			 And ae.submission_id In (0, p.submission_id)
			Join clearing_house.view_physical_samples ps
			  On ps.merged_db_id = ae.physical_sample_id
			 And ps.submission_id In (0, p.submission_id)
			Join clearing_house.view_sample_groups sg
			  On sg.merged_db_id = ps.sample_group_id
			 And sg.submission_id In (0, p.submission_id)
			Join clearing_house.view_sites s
			  On s.merged_db_id = sg.site_id
			 And s.submission_id In (0, p.submission_id)

		) As LDB Left Join (

			Select
					s.site_id								As site_id,
					s.site_name								As site_name,
					p.project_id								As project_id,
					p.project_name								As project_name,
					p.project_abbrev_name							As project_abbrev,
					p.description								As description,
					prs.stage_name ||', '|| pt.project_type_name 				As project_type,
					p.date_updated								As date_updated


			From public.tbl_projects p
			Join public.tbl_project_types pt
			  On pt.project_type_id = p.project_type_id
			Join public.tbl_project_stages prs
			  On prs.project_stage_id = p.project_stage_id
			Join public.tbl_datasets d
			  On p.project_id = d.project_id
			Join public.tbl_analysis_entities ae
			  On d.dataset_id = ae.dataset_id
			Join public.tbl_physical_samples ps
			  On ps.physical_sample_id = ae.physical_sample_id
			Join public.tbl_sample_groups sg
			  On sg.sample_group_id = ps.sample_group_id
			Join public.tbl_sites s
			  On s.site_id = sg.site_id

		  ) As RDB
		  On
		  RDB.project_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.dataset_id = -$2
		;

End $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION clearing_house.fn_clearinghouse_review_dataset_contacts_client_data(integer, integer)
  OWNER TO clearinghouse_worker;