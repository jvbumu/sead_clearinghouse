-- Display when sample is clicked ()
-- No data avaliable for Ceramics or Dendro0
-- SAMPLE POSITIONS FUNCTION***

-- New function, similar to the sample groups one.

-- Function: clearing_house.fn_clearinghouse_review_sample_positions_client_data(integer, integer)

-- DROP FUNCTION clearing_house.fn_clearinghouse_review_sample_positions_client_data(integer, integer);

CREATE OR REPLACE FUNCTION clearing_house.fn_clearinghouse_review_sample_positions_client_data(
    IN integer,
    IN integer)
  RETURNS TABLE(local_db_id integer, sample_position character varying, position_accuracy character varying, method_name character varying, public_db_id integer, public_sample_position character varying, public_position_accuracy character varying, public_method_name character varying, entity_type_id integer) AS
$BODY$
Declare
    entity_type_id int;
Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_sample_coordinates');

	Return Query

		Select
			LDB.local_db_id				               	As local_db_id,
			coalesce(LDB.dimension_name::text, '') || ' ' || coalesce(LDB.measurement::text, '')                   		As sample_position,
			LDB.accuracy                       		As position_accuracy,
			LDB.method_name                       			As method_name,

			LDB.public_db_id				        As public_db_id,
			coalesce(RDB.dimension_name::text, '') || ' ' || coalesce(RDB.measurement::text, '')                   		As public_sample_position,
			RDB.accuracy                       		As public_position_accuracy,
			RDB.method_name                       			As public_method_name,
			RDB.dimension_name                       		As public_dimension_name,
			entity_type_id						As entity_type_id
		From (
			Select		ps.source_id						As source_id,
					ps.submission_id					As submission_id,
					ps.local_db_id						As physical_sample_id,
					d.local_db_id						As local_db_id,
					d.public_db_id						As public_db_id,
					d.merged_db_id						As merged_db_id,
					c.measurement						As measurement,
					c.accuracy						As accuracy,
					m.method_name						As method_name,
					d.dimension_name					As dimension_name
			From clearing_house.view_physical_samples ps
			Join clearing_house.view_sample_coordinates c
			  On c.physical_sample_id = ps.merged_db_id
			 And c.submission_id In (0, ps.submission_id)
			Join clearing_house.view_coordinate_method_dimensions md
			  On md.merged_db_id = c.coordinate_method_dimension_id
			 And md.submission_id In (0, ps.submission_id)
			Join clearing_house.view_methods m
			  On m.merged_db_id = md.method_id
			 And m.submission_id In (0, ps.submission_id)
			Join clearing_house.view_dimensions d
			  On d.merged_db_id = md.dimension_id
			 And d.submission_id In (0, ps.submission_id)
			Where 1 = 1
		) As LDB Left join (
			Select		c.sample_coordinate_id					As sample_coordinate_id,
					c.measurement						As measurement,
					c.accuracy						As accuracy,
					m.method_name						As method_name,
					d.dimension_name					As dimension_name
			From public.tbl_sample_coordinates c
			Join public.tbl_coordinate_method_dimensions md
			  On md.coordinate_method_dimension_id = c.coordinate_method_dimension_id
			Join public.tbl_methods m
			  On m.method_id = md.method_id
			Join public.tbl_dimensions d
			  On d.dimension_id = md.dimension_id
		) As RDB
		  On RDB.sample_coordinate_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.sample_group_id = -$2;

End $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION clearing_house.fn_clearinghouse_review_sample_group_positions_client_data(integer, integer)
  OWNER TO clearinghouse_worker;
