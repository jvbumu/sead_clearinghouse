

-- 'tbl_dimensions','dimension_abbrev','character varying',14,10
-- 'tbl_sample_alt_refs','alt_ref','character varying',52,40
-- 'tbl_sites','site_name','character varying',55,50

-- PK som saknas (tbl_ceramics_lookup)
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
