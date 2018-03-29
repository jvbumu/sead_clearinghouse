-- Ceramic Values

--To create a function for the review of dataset ceramic values, first a view of the ceramic values have to be created (for both public and clearing house). Using the measured values one as a base,
--the view down below is suggested for ceramic values. The only difference is this one contains ceramic lookup name and ceramic value. There are no prep methods, which is
--why they were left out.

CREATE OR REPLACE VIEW clearing_house.view_clearinghouse_dataset_ceramic_values AS
SELECT	d.submission_id,
		d.source_id,
    	d.local_db_id 			As local_dataset_id,
    	d.merged_db_id 			As merged_dataset_id,
    	d.public_db_id 			As public_dataset_id,
    	ps.sample_group_id,
    	ps.merged_db_id 		As physical_sample_id,
    	ps.local_db_id 			As local_physical_sample_id,
    	ps.public_db_id 		As public_physical_sample_id,
    	ps.sample_name,
    	m.method_id,
    	m.public_db_id 			As public_method_id,
    	m.method_name,
    	cl.name,
    	cv.measurement_value
FROM clearing_house.view_datasets d
     JOIN clearing_house.view_analysis_entities ae ON ae.dataset_id = d.merged_db_id AND (ae.submission_id = 0 OR ae.submission_id = d.submission_id)
     JOIN clearing_house.view_ceramics cv ON cv.analysis_entity_id = ae.merged_db_id AND (cv.submission_id = 0 OR cv.submission_id = d.submission_id)
     JOIN clearing_house.view_ceramics_lookup cl ON cl.merged_db_id = cv.ceramics_lookup_id AND (cl.submission_id = 0 OR cl.submission_id = d.submission_id)
     JOIN clearing_house.view_physical_samples ps ON ps.merged_db_id = ae.physical_sample_id AND (ps.submission_id = 0 OR ps.submission_id = d.submission_id)
     JOIN clearing_house.view_methods m ON m.merged_db_id = d.method_id AND (m.submission_id = 0 OR m.submission_id = d.submission_id);

ALTER TABLE clearing_house.view_clearinghouse_dataset_ceramic_values
    OWNER TO clearinghouse_worker;

GRANT ALL ON TABLE clearing_house.view_clearinghouse_dataset_ceramic_values TO clearinghouse_worker;
GRANT SELECT ON TABLE clearing_house.view_clearinghouse_dataset_ceramic_values TO mattias;

select count(*) from clearing_house.view_clearinghouse_dataset_ceramic_values

*fn_clearinghouse_review_ceramics_value(integer)*

--The only difference from the measured_values function is that this one uses the ceramic_values view and the addition of the lookup_name field.

-- TODO Join mot ceramics_id: Visa value + lookup name för jämförelse, som PIVOT!
Select
		LDB.physical_sample_id				            As local_db_id,
		LDB.sample_name									As sample_name,
		LDB.method_id									As method_id,
		LDB.method_name									As method_name,

		LDB.name										As lookup_name,
		LDB.measurement_value							As measurement_value,

		to_char(LDB.date_updated,'YYYY-MM-DD')			As date_updated,

		LDB.physical_sample_id				            As public_db_id,

		RDB.name										As public_lookup_name,
		RDB.measurement_value							As public_measurement_value,

		entity_type_id									As entity_type_id

From	clearing_house.view_clearinghouse_dataset_ceramic_values LDB

Left Join (
    SELECT	d.dataset_id 			As public_dataset_id,
            ps.physical_sample_id,
            cl.name,
            cv.measurement_value
    FROM public.tbl_analysis_entities ae ON ae.dataset_id = d.dataset_id
    JOIN public.tbl_ceramics cv ON cv.analysis_entity_id = ae.analysis_entity_id
    JOIN public.tbl_ceramics_lookup cl ON cl.ceramics_lookup_id = cv.ceramics_lookup_id

    ) RDB
On		RDB.dataset_id = LDB.public_dataset_id
And 	RDB.physical_sample_id = LDB.public_physical_sample_id
And 	RDB.method_id = LDB.public_method_id

Where LDB.source_id = 1
  And LDB.submission_id = $1

Order by LDB.physical_sample_id;

