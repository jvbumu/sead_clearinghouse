
    update clearing_house.tbl_clearinghouse_submission_xml_content_columns
        set column_name = 'address_1', column_name_underscored = 'address_1'
    where column_name = 'address1';

    update clearing_house.tbl_clearinghouse_submission_xml_content_columns
        set column_name = 'address_2', column_name_underscored = 'address_2'
    where column_name = 'address2';
    
    with pk_values As (
        select v.value_id, s.table_name_underscored, c.column_name_underscored, v.value, v.local_db_id
        from clearing_house.tbl_clearinghouse_submission_xml_content_values v
        join clearing_house.tbl_clearinghouse_submission_xml_content_tables t ON v.table_id = t.table_id
        join clearing_house.tbl_clearinghouse_submission_xml_content_columns c ON c.column_id = v.column_id
        join clearing_house.tbl_clearinghouse_submission_tables s ON s.table_id = t.table_id
    ) SELECT m.value_id, s.table_name, s.column_name, s.data_type, m.value, m.local_db_id,
            'UPDATE clearing_house.tbl_clearinghouse_submission_xml_content_values SET value = local_db_id WHERE value is NULL AND value_id = ' || value_id::text || ';'
      FROM pk_values m
      JOIN clearing_house.tbl_clearinghouse_sead_rdb_schema s
        ON s.table_name = m.table_name_underscored
       AND s.column_name = m.column_name_underscored
      WHERE s.is_pk = 'YES'
        --AND s.table_name = 'tbl_ceramics'
        AND m.value is NULL
        
Do $$
Begin

-- Perform clearing_house.fn_extract_and_store_submission_tables(1);
-- Perform clearing_house.fn_extract_and_store_submission_columns(1);
-- Perform clearing_house.fn_extract_and_store_submission_records(1);
-- Perform clearing_house.fn_extract_and_store_submission_values(1);
-- Perform clearing_house.fn_copy_extracted_values_to_entity_tables(submission_id);

   --Print out statement for each individual copy:
   --Perform clearing_house.fn_copy_extracted_values_to_entity_tables(1, TRUE, FALSE);

    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_dimensions');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_alt_ref_types');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_contact_types');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_feature_types');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_location_types');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_ceramics_lookup');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_group_description_types');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_description_types');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_units');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_data_type_groups');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_dating_uncertainty');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_alt_refs');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_group_description_type_sampling_contexts');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_locations');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sites');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_site_references');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_site_locations');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_types');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_method_groups');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_features');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_contacts');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_dimensions');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_group_dimensions');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_biblio');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_relative_dates');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_relative_ages');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_methods');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_datasets');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_dataset_masters');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_dataset_contacts');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_dataset_submissions');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_groups');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_group_descriptions');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_group_sampling_contexts');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_physical_samples');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_sample_descriptions');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_physical_sample_features');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_analysis_entities');
    -- PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(1, 'tbl_ceramics');

End $$ Language plpgsql;--select Count(*) from clearing_house.tbl_clearinghouse_submission_xml_content_columns


select *
from clearing_house.tbl_clearinghouse_submissions
