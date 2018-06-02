/*
1. Optional step: Clear Entity DB
   sql> Select clearing_house.fn_truncate_all_entity_tables()

2. Load XML to submission table:
   dos> bulk_upload_xml.bat

3. Run explosion scripts:
   sql> select clearing_house.fn_explode_submission_xml_to_rdb(1)
*/
select * from clearing_house.tbl_clearinghouse_submission_xml_content_tables
select count(*) from clearing_house.tbl_physical_samples

--select * from clearing_house.fn_extract_and_store_submission_tables(1);
--select * from clearing_house.fn_extract_and_store_submission_columns(1);
--select * from clearing_house.fn_extract_and_store_submission_records(1);
--select * from clearing_house.fn_extract_and_store_submission_values(1);

/* FIX OF WRONG NAMES in EXCEL/XML */
-- update clearing_house.tbl_clearinghouse_submission_xml_content_columns
--    set column_name = 'address_1', column_name_underscored = 'address_1'
-- where column_name = 'address1';

-- update clearing_house.tbl_clearinghouse_submission_xml_content_columns
--    set column_name = 'address_2', column_name_underscored = 'address_2'
-- where column_name = 'address2';


/* FIX: Wrong value in tbl_sample_dimensions
select * from clearing_house.tbl_clearinghouse_submission_xml_content_records r limit 1
select * from clearing_house.tbl_clearinghouse_submission_xml_content_columns r limit 1
select * from clearing_house.tbl_clearinghouse_submission_xml_content_values r limit 1

select *
from clearing_house.tbl_clearinghouse_submission_xml_content_tables s
join clearing_house.tbl_clearinghouse_submission_tables t
  on t.table_id = s.table_id
where t.table_name_underscored = 'tbl_sample_dimensions'
--> table_id = 112
select * from clearing_house.tbl_clearinghouse_submission_xml_content_columns r where table_id = 112;
--> column_id = 379 (dimension_value)

select *
from clearing_house.tbl_clearinghouse_submission_xml_content_values
where table_id = 112
  and column_id = 379
  and value like '%,%';

update clearing_house.tbl_clearinghouse_submission_xml_content_values set value = '4.5' where value_id = 2324817;
*/

Select * From clearing_house.fn_copy_extracted_values_to_entity_tables(1, TRUE, FALSE);


/*
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_dating_uncertainty');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_group_sampling_contexts');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_units');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_location_types');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_method_groups');

Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_description_types');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_contact_types');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_data_type_groups');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_alt_ref_types');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_analysis_entities');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_biblio');

Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_ceramics');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_ceramics_lookup');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_contacts');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_dataset_contacts');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_dataset_masters');

Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_dataset_submissions');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_datasets');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_dimensions');

Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_feature_types');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_features');

Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_locations');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_methods');

Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_physical_sample_features');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_physical_samples');

Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_relative_ages');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_relative_dates');

Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_alt_refs');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_descriptions');

Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_dimensions');

Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_group_description_type_sampling_contexts');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_group_description_types');

Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_group_descriptions');

Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_group_dimensions');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_groups');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_types');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_site_locations');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_site_references');
Select * From clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sites');

*/

