DROP VIEW clearing_house.view_sample_group_sampling_contexts;
DROP VIEW postgrest_default_api.sample_group_sampling_context;

ALTER TABLE public.tbl_sample_group_sampling_contexts ALTER COLUMN sampling_context TYPE character varying(60);

BEGIN TRANSACTION;

	INSERT INTO tbl_locations (location_name, location_type_id) VALUES
		('Öland', 18),              -- 1724 byggdatat
		('Hakarp socken', 2),       -- 1818 byggdatat
		('Jönköping', 4),           -- 1847 arkeologiska datat
		('Kalmar socken', 2),       -- 1850 arkeologiska datat
		('Lofta socken', 2),        -- 1888 byggdatat
		('Räpplinge socken', 2),    -- 1925 byggdatat
		('Flensburg', 4);           -- 2033 byggdatat

	INSERT INTO tbl_sample_group_sampling_contexts (sampling_context, description) VALUES
		('Dendrochronological building investigation', 'Investigation of wood for age determination, sampled in a historic building context'),
		('Dendrochronological archaeological sampling', 'Investigation of wood for age determination, sampled in an archaeological context');

	INSERT INTO tbl_feature_types (feature_type_name, feature_type_description)
		VALUES ('Unknown', 'Feature type is either of a unknown character or not specified'); -- 66 byggdatat

	INSERT INTO tbl_contacts (address_1, address_2, first_name, last_name, email, url, location_id)
		VALUES (
			'Environmental Archaeology Lab Dept. of Philosophical, Historical & Religious Studies', 'Umeå University', 'Mattias', 'Sjölander', 'mattias.sjolander@umu.se',
			'http://www.idesam.umu.se/om/personal/?uid=masj0062&guiseId=360086&orgId=4864cb4234d0bf7c77c65d7f78ffca7ecaf285c7&name=Mattias%20Sj%c3%b6lander',
			205
		); -- 11 arkeologiska och byggdatat

COMMIT;

-- Recreate Dropped View
SELECT clearing_house.fn_create_local_union_public_entity_views('clearing_house', 'clearing_house', FALSE, TRUE);

-- SELECT metainformation.create_typed_audit_views('public');
-- SELECT * FROM audit.view_locations WHERE action_tstamp_tx = '2018-06-07 15:47:16.992688+02';
-- SELECT * FROM audit.view_feature_types WHERE action_tstamp_tx = '2018-06-07 15:47:16.992688+02';
-- SELECT * FROM audit.view_contacts WHERE action_tstamp_tx = '2018-06-07 15:47:16.992688+02';
-- SELECT * FROM audit.view_sample_group_sampling_contexts WHERE action_tstamp_tx = '2018-06-07 15:47:16.992688+02';


