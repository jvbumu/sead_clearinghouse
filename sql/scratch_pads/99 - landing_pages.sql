
CREATE OR REPLACE FUNCTION site_landing_page_site_locations(p_site_id int) 
RETURNS json AS
$$
DECLARE 
	v_json json;
BEGIN
	WITH T AS (
		SELECT L.location_name as name, L.location_type_id as level
		FROM tbl_site_locations SL
		JOIN tbl_locations L
		  ON L.location_id = SL.location_id
		WHERE SL.site_id = p_site_id
		ORDER BY L.location_type_id ASC
	) SELECT array_to_json(array_agg(T))
		INTO v_json
	  FROM T;
	RETURN v_json;
END	
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION site_landing_page_site_sample_groups(p_site_id int) 
RETURNS json AS
$$
DECLARE 
	v_sample_group_columns json;
	v_sample_group_rows json;
BEGIN
	 WITH data_columns AS (
		 SELECT *
		 FROM (
			 VALUES 
				('Samples', false, 'subtable'),
				('Site ID', false, 'numeric'),
				('Sample group ID', true, 'numeric'),
				('Sample group name', false, 'string'),
				('Sampling context', false, 'string'),
				('Sampling method', false, 'string'),
				('Number of samples', false, 'numeric'),
				('Datasets ID', false, 'string')
		) AS A(title,pkey,dataType)
	) SELECT array_to_json(array_agg(data_columns))
	  INTO v_sample_group_columns
	  FROM data_columns;
  
	WITH T AS (
		SELECT null
		FROM tbl_sites s
		WHERE s.site_id = 1
	) SELECT array_to_json(array_agg(T))
		INTO v_sample_group_rows
	  FROM T;
	  
	RETURN json_build_object(
			'name', 'samplegroups',
			'title', 'Sample groups',
			'data', json_build_object(
				'columns', v_sample_group_columns,
				'rows', v_sample_group_rows
			)
		);
END	
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION site_landing_page_site_sample_section(p_site_id int) 
RETURNS json AS
$$
DECLARE 
	v_json json;
BEGIN
	WITH T AS (
		SELECT json_build_object(
			'name', 'samples',
			'title', 'Samples',
			'description', 'Samples collected from this site',
			'contentItems', site_landing_page_site_sample_groups(p_site_id)
		) AS json_site
		FROM tbl_sites s
		WHERE s.site_id = p_site_id
	) SELECT json_site INTO v_json
	  FROM T;
	RETURN v_json;
END	
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION site_landing_page_site(p_site_id int) 
RETURNS json AS
$$
DECLARE 
	v_json json;
BEGIN
	WITH T AS (
		SELECT json_build_object(
			'siteId', s.site_id,
			'siteName', s.site_name,
			'siteDescription', COALESCE(s.site_description,''),
			'places', site_landing_page_site_locations(p_site_id),
			'coordinates',  json_build_object(
				'lat', s.latitude_dd,
				'lng', s.longitude_dd,
				'epsg', '4326' -- FIXME!
			),
			'sections', json_build_array(
				site_landing_page_site_sample_section(p_site_id),
				null
			)
		) AS json_site
		FROM tbl_sites s
		WHERE s.site_id = p_site_id
	) SELECT json_site INTO v_json
	  FROM T;
	RETURN v_json;
END	
$$ LANGUAGE plpgsql;	

SELECT *
FROM site_landing_page_site(1)



  
select 
  SG.site_id                                                                      	as site_id,
  SG.sample_group_id                                                               	as sample_group_id,
  SG.sample_group_name                                                             	as sample_group_name,
  CXT.sampling_context																as sampling_context,
  SGM.method_name																	as sampling_method,
  -- tbl_feature_types.feature_type_name                                               as feature_type_name,
  -- tbl_feature_types.feature_type_description                                        as feature_type_description,
  -- tbl_record_types.record_type_name                                                 as record_type_name,
  TRUE
from tbl_sample_groups SG
left join tbl_sample_group_sampling_contexts CXT
  on CXT.sampling_context_id = SG.sampling_context_id
left join tbl_methods SGM
  on SGM.method_id = SG.method_id

left join (
	SELECT PS.sample_group_id, COUNT()
	FROM tbl_physical_samples PS
	JOIN tbl_analysis_entities AE
	  ON AE.physical_sample_id = PS.physical_sample_id
	GROUP BY PS.sample_group_id
  on PS.sample_group_id = SG.sample_group_id
  
  
left join tbl_datasets D
  on tbl_analysis_entities."dataset_id" = tbl_datasets."dataset_id" 
  
  
inner join tbl_record_types
  on tbl_methods."record_type_id" = tbl_record_types."record_type_id" 
left join tbl_sample_groups
  on tbl_physical_samples."sample_group_id" = tbl_sample_groups."sample_group_id" 
left join tbl_sites
  on tbl_sample_groups."site_id" = tbl_sites."site_id" 
left join tbl_physical_sample_features
  on tbl_physical_sample_features."physical_sample_id" = tbl_physical_samples."physical_sample_id" 
left join tbl_features
  on tbl_features."feature_id" = tbl_physical_sample_features."feature_id" 
left join tbl_feature_types
  on tbl_feature_types."feature_type_id" = tbl_features."feature_type_id" 
where TRUE
  AND SG.site_id = 1
  
