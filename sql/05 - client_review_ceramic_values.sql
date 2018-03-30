-- Ceramic Values

With LDB As (
    Select	d.submission_id                         As submission_id,
            d.source_id                             As source_id,

            d.local_db_id 			                As local_dataset_id,
            ps.local_db_id 			                As local_physical_sample_id,
            m.local_db_id 			                As local_method_id,

            d.public_db_id 			                As public_dataset_id,
            ps.public_db_id 			            As public_physical_sample_id,
            m.public_db_id 			                As public_method_id,

            ps.sample_name                          As sample_name,
            m.method_name                           As method_name,
            cl.name                                 As lookup_name,
            c.measurement_value                     As measurement_value,

            cl.date_updated                     	As date_updated  -- Select count(*)

    From clearing_house.view_datasets d
    Join clearing_house.view_analysis_entities ae
      On ae.dataset_id = d.merged_db_id
     And ae.submission_id In (0, d.submission_id)
    Join clearing_house.view_ceramics c
      On c.analysis_entity_id = ae.merged_db_id
     And c.submission_id In (0, d.submission_id)
    Join clearing_house.view_ceramics_lookup cl
      On cl.merged_db_id = c.ceramics_lookup_id
     And cl.submission_id In (0, d.submission_id)
    Join clearing_house.view_physical_samples ps
      On ps.merged_db_id = ae.physical_sample_id
     And ps.submission_id In (0, d.submission_id)
    Join clearing_house.view_methods m
      On m.merged_db_id = d.method_id
     And m.submission_id In (0, d.submission_id)

), RDB As (
    Select	d.dataset_id 			                As dataset_id,
            ps.physical_sample_id                   As physical_sample_id,
            m.method_id                             As method_id,

            ps.sample_name                          As sample_name,
            m.method_name                           As method_name,
            cl.name                                 As lookup_name,
            c.measurement_value                     As measurement_value

    From public.tbl_datasets d
    Join public.tbl_analysis_entities ae
      On ae.dataset_id = d.dataset_id
    Join public.tbl_ceramics c
      On c.analysis_entity_id = ae.analysis_entity_id
    Join public.tbl_ceramics_lookup cl
      On cl.ceramics_lookup_id = c.ceramics_lookup_id
    Join public.tbl_physical_samples ps
      On ps.physical_sample_id = ae.physical_sample_id
    Join public.tbl_methods m
      On m.method_id = d.method_id
)
    Select

        LDB.local_dataset_id 			                As local_dataset_id,
        LDB.local_physical_sample_id 			        As local_physical_sample_id,
        LDB.local_method_id 			                As local_method_id,
		LDB.sample_name									As sample_name,
		LDB.method_name									As method_name,
		LDB.lookup_name									As lookup_name,
		LDB.measurement_value							As measurement_value,

        LDB.public_dataset_id 			                As public_dataset_id,
        LDB.public_physical_sample_id 			        As public_physical_sample_id,
        LDB.public_method_id 			                As public_method_id,
		RDB.sample_name									As public_sample_name,
		RDB.method_name									As public_method_name,
		RDB.lookup_name									As public_lookup_name,
		RDB.measurement_value							As public_measurement_value,

		1, --entity_type_id									As entity_type_id.
		to_char(LDB.date_updated,'YYYY-MM-DD')			As date_updated

    From LDB
    Left Join RDB
      On RDB.dataset_id = LDB.public_dataset_id
     And RDB.physical_sample_id = LDB.public_physical_sample_id
     And RDB.method_id = LDB.public_method_id
    Where LDB.source_id = 1
      And LDB.submission_id = 1 -- $1
      And LDB.local_dataset_id = 0 -- NOTE!!!
    Order by LDB.local_physical_sample_id;

/*
Review of a dataset's ceramic values:
, first a view of the ceramic values have to be
created (for both public and clearing house). Using the measured values one as a base,
the view down below is suggested for ceramic values. The only difference is this one contains ceramic lookup name
and ceramic value. There are no prep methods, which is why they were left out.

The only difference from the measured_values function is that this one uses the ceramic_values view and the
addition of the lookup_name field.

TODO Join mot ceramics_id: Visa value + lookup name för jämförelse, som PIVOT!

*/

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

