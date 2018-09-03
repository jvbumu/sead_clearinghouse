
-- Displayed when physical sample node is clicked

-- ***DENDRO DATE function***


-- FUNCTION: clearing_house.fn_clearinghouse_review_dendro_dates_client_data(integer, integer)

-- DROP FUNCTION clearing_house.fn_clearinghouse_review_dendro_dates_client_data(integer, integer);

  CREATE OR REPLACE FUNCTION clearing_house.fn_clearinghouse_review_dendo_dates_client_data(
	IN integer,
	IN integer)
      RETURNS TABLE(dendro_date_id integer, physical_sample_id integer, sample_name character varying, dating_type character varying, season_type character varying, date character varying, "error: years -" character varying, "error: years +" character varying, public_physical_sample_id integer, public_sample_name character varying, public_dating_type character varying, public_season_type character varying, public_date character varying, "public_error: years -" character varying, "public_error: years +" character varying, entity_type_id integer) AS
$BODY$

Declare
	entity_type_id int;

Begin
	entity_type_id := clearing_house.fn_get_entity_type_for('tbl_dendro_dates');

	Return Query

		Select

			LDB.local_db_id				               																									As dendro_date_id,
			LDB.physical_sample_id																														As physical_sample_id,
			LDB.sample_name                     																										As sample_name,
			LDB.lookup_name																																As dating_type,
			LDB.season_or_qualifier_type																												As season_type,
			case when LDB.uncertainty is null then '' else LDB.uncertainty end || coalesce(LDB.age_older::text,'') || case when coalesce(LDB.age_older::text, null) is null then '' else '-' end || coalesce(LDB.age_younger::text,'') ||' '|| LDB.age_type 	As date,
			case when LDB.error_uncertainty_type is null then '' else LDB.error_uncertainty_type end || ' ' || coalesce(LDB.error_minus::text, null) 	As "error: years -",
			case when LDB.error_uncertainty_type is null then '' else LDB.error_uncertainty_type end || ' ' || coalesce(LDB.error_plus::text, null) 	As "error: years +",

			RDB.physical_sample_id																														As public_physical_sample_id,
			RDB.sample_name                     																										As public_sample_name,
			RDB.lookup_name																																As public_dating_type,
			RDB.season_or_qualifier_type																												As public_season_type,
			case when RDB.uncertainty is null then '' else RDB.uncertainty end || coalesce(RDB.age_older::text,'') || case when coalesce(RDB.age_older::text, null) is null then '' else '-' end || coalesce(RDB.age_younger::text,'') ||' '|| RDB.age_type		As public_date,
			case when RDB.error_uncertainty_type is null then '' else RDB.error_uncertainty_type end || ' ' || RDB.error_minus 							As "public_error: years -",
			case when RDB.error_uncertainty_type is null then '' else RDB.error_uncertainty_type end || ' ' || RDB.error_plus 							As "public_error: years +",

			entity_type_id																																As entity_type_id

		From (


			Select	dd.source_id												As source_id,
					dd.submission_id											As submission_id,
					dd.local_db_id												As local_db_id,
					dd.public_db_id												As public_db_id,
					dd.merged_db_id												As merged_db_id,
					ps.local_db_id												As physical_sample_id,
					ps.sample_name												As sample_name,
					dl.name 													As lookup_name,
					soq.season_or_qualifier_type								As season_or_qualifier_type,
					du.uncertainty												As uncertainty,
					dd.age_older												As age_older,
					dd.age_younger												As age_younger,
					at.age_type													As age_type,
					eu.error_uncertainty_type									As error_uncertainty_type,
					dd.error_minus												As error_minus,
					dd.error_plus												As error_plus,
					dd.date_updated												As date_updated

			From clearing_house.view_dendro_dates dd
			Join clearing_house.view_analysis_entities ae
			  On ae.merged_db_id = dd.analysis_entity_id
			 And ae.submission_id In (0, dd.submission_id)
			Left join clearing_house.view_age_types at
			  On at.merged_db_id = dd.age_type_id
			 And at.submission_id in (0, dd.submission_id)
			Left join clearing_house.view_dating_uncertainty du
			  On du.merged_db_id = dd.dating_uncertainty_id
			 And du.submission_id in (0, dd.submission_id)
			Left join clearing_house.view_error_uncertainties eu
			  On eu.merged_db_id = dd.error_uncertainty_id
			 And eu.submission_id in (0, dd.submission_id)
			Left join clearing_house.view_season_or_qualifier soq
			  On soq.merged_db_id = dd.season_or_qualifier_id
			 And soq.submission_id in (0, dd.submission_id)
			Left join clearing_house.view_dendro_lookup dl
			  On dl.merged_db_id = dd.dendro_lookup_id
			 And dl.submission_id in (0, dd.submission_id)
			Join clearing_house.view_physical_samples ps
			  On ps.merged_db_id = ae.physical_sample_id
			 And ps.submission_id In (0, dd.submission_id)
			) As LDB

		Left Join (

				Select 	ps.physical_sample_id										As physical_sample_id,
						ps.sample_name												As sample_name,
						dd.dendro_date_id											As dendro_date_id,
						dl.name 													As lookup_name,
						soq.season_or_qualifier_type								As season_or_qualifier_type,
						du.uncertainty												As uncertainty,
						dd.age_older												As age_older,
						dd.age_younger												As age_younger,
						at.age_type													As age_type,
						eu.error_uncertainty_type									As error_uncertainty_type,
						dd.error_minus												As error_minus,
						dd.error_plus												As error_plus,
						dd.date_updated												As date_updated

				From public.tbl_physical_samples ps
				Join public.tbl_analysis_entities ae
				  On ps.physical_sample_id = ae.physical_sample_id
				Join public.tbl_dendro_dates dd
				  On ae.analysis_entity_id = dd.analysis_entity_id
				Join public.tbl_age_types at
				  On at.age_type_id = dd.age_type_id
				Left join public.tbl_dating_uncertainty du
				  On du.dating_uncertainty_id = dd.dating_uncertainty_id
				Left join public.tbl_error_uncertainties eu
				  On eu.error_uncertainty_id = dd.error_uncertainty_id
				Left join public.tbl_season_or_qualifier soq
				  On soq.season_or_qualifier_id = dd.season_or_qualifier_id
				Left join public.tbl_dendro_lookup dl
				  On dl.dendro_lookup_id = dd.dendro_lookup_id
				) As RDB

		On RDB.dendro_date_id = LDB.public_db_id

		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.physical_sample_id = -$2;

End
$BODY$;