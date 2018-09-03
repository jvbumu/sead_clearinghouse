
***DENDRO DATE NOTES FUNCTION***


-- FUNCTION: clearing_house.fn_clearinghouse_review_dendro_date_notes_client_data(integer, integer)

-- DROP FUNCTION clearing_house.fn_clearinghouse_review_dendro_date_notes_client_data(integer, integer);

CREATE OR REPLACE FUNCTION clearing_house.fn_clearinghouse_review_dendro_date_notes_client_data(
	integer,
	integer)
RETURNS TABLE(dendro_date_id integer, note character varying, public_db_id integer, public_note character varying, date_updated text, entity_type_id integer)
    LANGUAGE 'plpgsql'
AS $BODY$

Declare
    entity_type_id int;
Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_dendro_date_notes');

	Return Query

		Select
			LDB.local_db_id					            As dendro_date_id,
			LDB.note                              		As note,
			LDB.public_db_id                            As public_db_id,
			RDB.note                               		As public_note,
			to_char(LDB.date_updated,'YYYY-MM-DD')		As date_updated,
			entity_type_id                  			As entity_type_id
		From (
			Select	dd.source_id						As source_id,
					dd.submission_id					As submission_id,
					dd.local_db_id						As dendro_date_id,
					ddn.local_db_id						As local_db_id,
					ddn.public_db_id					As public_db_id,
					ddn.merged_db_id					As merged_db_id,
					ddn.note							As note,
					ddn.date_updated					As date_updated

			From clearing_house.view_dendro_dates dd
			Join clearing_house.view_dendro_date_notes ddn
			  On ddn.dendro_date_id = dd.merged_db_id
			 And ddn.submission_id In (0, dd.submission_id)
			Join clearing_house.view_analysis_entities ae
			  On ae.merged_db_id = dd.analysis_entity_id
			 And ae.submission_id In (9, dd.submission_id)
			Join clearing_house.view_physical_samples ps
			  On ps.merged_db_id = ae.physical_sample_id
			 And ps.submission_id In (0, dd.submission_id)

		) As LDB Left Join (
			Select	ddn.dendro_date_note_id				As dendro_date_note_id,
					ddn.note							As note
			From public.tbl_dendro_date_notes ddn
		) As RDB
		  On RDB.dendro_date_note_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.physical_sample_id = -$2;

End
$BODY$;

ALTER FUNCTION clearing_house.fn_clearinghouse_review_dendro_date_notes_client_data(integer, integer)
    OWNER TO clearinghouse_worker;
    