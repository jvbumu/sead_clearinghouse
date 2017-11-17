-- Strängar som är för långa
with string_value_max As (
    select s.table_name_underscored, c.column_name_underscored, max(length(v.value)) as value_length
    from clearing_house.tbl_clearinghouse_submission_xml_content_values v
    join clearing_house.tbl_clearinghouse_submission_xml_content_tables t ON v.table_id = t.table_id
    join clearing_house.tbl_clearinghouse_submission_xml_content_columns c ON c.column_id = v.column_id
    join clearing_house.tbl_clearinghouse_submission_tables s ON s.table_id = t.table_id
    where c.data_type Like '%String'
    group by s.table_name_underscored, c.column_name_underscored
) SELECT s.table_name, s.column_name, s.data_type, m.value_length, s.character_maximum_length
  FROM string_value_max m
  JOIN clearing_house.tbl_clearinghouse_sead_rdb_schema s
    ON s.table_name = m.table_name_underscored
   AND s.column_name = m.column_name_underscored
  WHERE Not s.character_maximum_length IS NULL
    AND m.value_length > s.character_maximum_length
    
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

DO $$
Begin

    Perform clearing_house.fn_drop_clearinghouse_public_db_model();
    --ALTER TABLE "public"."tbl_dimensions" ALTER COLUMN "dimension_abbrev" TYPE character varying(16) COLLATE "pg_catalog"."default";
	--ALTER TABLE "public"."tbl_sample_alt_refs" ALTER COLUMN "alt_ref" TYPE character varying(60) COLLATE "pg_catalog"."default";
	--ALTER TABLE "public"."tbl_sites" ALTER COLUMN "site_name" TYPE character varying(60) COLLATE "pg_catalog"."default";
    Perform clearing_house.fn_dba_create_and_transfer_sead_public_db_schema();
    Perform clearing_house.fn_create_clearinghouse_public_db_model();
       
End $$ Language plpgsql;

