
    Select t.table_name_underscored, c.column_name_underscored, -- v.local_db_id, v.value, length(v.value) as len_value, c.data_type,
           --i_c.is_nullable,
           --i_c.data_type || '(' || coalesce(i_c.character_maximum_length::text, i_c.numeric_precision::text, '*') || ')',
           Case When (c.data_type like '%String%' And length(v.value) > i_c.character_maximum_length) Then 'Value length exceeded'
                When (i_c.is_nullable = 'NO' and v.value is NULL) Then 'NULL value for NON-NULL column'
       			When (i_c.table_name is Null) Then 'Unknown column'
       			When (i_c.column_name is Null) Then 'Unknown column'
                Else '' End as error, 
                count(*)
    From clearing_house.tbl_clearinghouse_submission_xml_content_values v

    Join clearing_house.tbl_clearinghouse_submission_tables t
      On t.table_id = v.table_id

    Join clearing_house.tbl_clearinghouse_submission_xml_content_columns c
      On c.submission_id = v.submission_id
     And c.table_id = t.table_id
     And c.column_id = v.column_id
     
    Left Join information_schema.tables i_t
      on i_t.table_type = 'BASE TABLE'
     And i_t.table_schema = 'public'
     And i_t.table_name = t.table_name_underscored

    Left Join information_schema.columns i_c
      on i_c.table_catalog = i_t.table_catalog  
     and i_c.table_schema = i_t.table_schema
     and i_c.table_name = i_t.table_name
     and i_c.column_name = c.column_name_underscored
        
    Where 1 = 1
      And v.submission_id = 1
      And c.column_name <> 'clone_id'
      And ((c.data_type like '%String%' And length(v.value) > i_c.character_maximum_length)
       Or (i_c.is_nullable = 'NO' and v.value is NULL)
       Or (i_c.column_name is Null))
	Group by 1, 2, 3
