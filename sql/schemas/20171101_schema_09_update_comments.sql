COMMENT ON COLUMN "public"."tbl_abundance_elements"."element_description" IS 'Explanation of short name, e.g. Minimum Number of Individuals, base of seed grain, covering of leaf or flower bud';
COMMENT ON COLUMN "public"."tbl_abundance_elements"."element_name" IS 'Short name for element, e.g. MNI, seed, leaf';
COMMENT ON COLUMN "public"."tbl_abundance_elements"."record_type_id" IS 'Used to restrict list of available elements according to record type. Enables specific use of single term for multiple proxies whilst avoiding confusion, e.g. MNI insects, MNI seeds';
COMMENT ON TABLE "public"."tbl_abundances" IS '20120503PIB Deleted column "abundance_modification_id" as appeared superfluous with "abundance_id" in tbl_adbundance_modifications';
COMMENT ON COLUMN "public"."tbl_abundances"."abundance" IS 'Usually count value (abundance) but can be presence (1) or catagorical or relative scale, as defined by tbl_data_types through tbl_datasets';
COMMENT ON COLUMN "public"."tbl_abundances"."abundance_element_id" IS 'Allows recording of different parts for single taxon, e.g. leaf, seed, MNI etc.';
COMMENT ON COLUMN "public"."tbl_aggregate_datasets"."aggregate_dataset_name" IS 'Name of aggregated dataset';
COMMENT ON TABLE "public"."tbl_aggregate_order_types" IS '20120504PIB: drop this? or replace with alternative?';
COMMENT ON COLUMN "public"."tbl_aggregate_order_types"."aggregate_order_type" IS 'Aggregate order name, e.g. Site name, Age, Sample Depth, Altitude';
COMMENT ON COLUMN "public"."tbl_aggregate_order_types"."description" IS 'Explanation of ordering system';
COMMENT ON TABLE "public"."tbl_aggregate_samples" IS '20120504PIB: Can we drop aggregate sample name? Seems excessive and unnecessary sample names can be traced.';
COMMENT ON COLUMN "public"."tbl_aggregate_samples"."aggregate_sample_name" IS 'Optional name for aggregated entity.';
COMMENT ON TABLE "public"."tbl_analysis_entities" IS '20120503PIB Deleted column preparation_method_id, but may need to cater for this in datasets...
20120506PIB: deleted method_id and added table for multiple methods per entity';
COMMENT ON COLUMN "public"."tbl_analysis_entity_prep_methods"."method_id" IS 'Preparation methods only';
COMMENT ON TABLE "public"."tbl_ceramics_lookup" IS 'Type=lookup';
COMMENT ON COLUMN "public"."tbl_chronologies"."relative_age_type_id" IS 'Constraint removed to obsolete table (tbl_age_types), replaced by non-binding id of relative_age_types - but not fully implemented. Notes should be used to inform on chronology years types and construction.';
COMMENT ON COLUMN "public"."tbl_dataset_masters"."biblio_id" IS 'Primary reference for master dataset if available, e.g. Buckland & Buckland 2006 for BugsCEP';
COMMENT ON COLUMN "public"."tbl_dataset_masters"."master_name" IS 'Identification of master dataset, e.g. MAL, BugsCEP, Dendrolab';
COMMENT ON COLUMN "public"."tbl_dataset_masters"."master_notes" IS 'Description of master dataset, its form (e.g. database, lab) and any other relevant information for tracing it.';
COMMENT ON COLUMN "public"."tbl_dataset_masters"."url" IS 'Website or other url for master dataset, be it a project, lab or... other';
COMMENT ON COLUMN "public"."tbl_dataset_submission_types"."description" IS 'Explanation of submission type, explaining clearly data ingestion mechanism';
COMMENT ON COLUMN "public"."tbl_dataset_submission_types"."submission_type" IS 'Descriptive name for type of submission, e.g. original submission, ingestion from another database';
COMMENT ON COLUMN "public"."tbl_dataset_submissions"."notes" IS 'Any details of submission not covered by submission_type information, such as name of source from which submission originates if not covered elsewhere in database, e.g. from BugsCEP';
COMMENT ON COLUMN "public"."tbl_datasets"."dataset_name" IS 'Something uniquely identifying the dataset for this site. May be same as sample group name, or created adhoc if necessary, but preferably with some meaning.';
COMMENT ON TABLE "public"."tbl_dating_labs" IS '20120504PIB: reduced this table and linked to tbl_contacts for address related data';
COMMENT ON COLUMN "public"."tbl_dating_labs"."contact_id" IS 'Address details are stored in tbl_contacts';
COMMENT ON COLUMN "public"."tbl_dating_labs"."international_lab_id" IS 'International standard radiocarbon lab identifier.
From http://www.radiocarbon.org/Info/labcodes.html';
COMMENT ON COLUMN "public"."tbl_dating_labs"."lab_name" IS 'International standard name of radiocarbon lab, from http://www.radiocarbon.org/Info/labcodes.html';
COMMENT ON TABLE "public"."tbl_dendro_lookup" IS 'Type=lookup';
COMMENT ON COLUMN "public"."tbl_features"."feature_description" IS 'Description of the feature. May include any field notes, lab notes or interpretation information useful for interpreting the sample data.';
COMMENT ON COLUMN "public"."tbl_features"."feature_name" IS 'Estabilished reference name/number for the FEATURE (note: NOT the sample). E.g. Well 47, Anl.3, C107.
Remember that a sample can come from multiple features (e.g. C107 in Well 47) but each feature should have a separate record.';
COMMENT ON COLUMN "public"."tbl_geochron_refs"."biblio_id" IS 'Reference for specific date';
COMMENT ON COLUMN "public"."tbl_geochronology"."age" IS 'Radiocarbon (or other radiometric) age.';
COMMENT ON COLUMN "public"."tbl_geochronology"."delta_13c" IS 'Delta 13C where available for calibration correction.';
COMMENT ON COLUMN "public"."tbl_geochronology"."error_older" IS 'Plus (+) side of the measured error (set same as error_younger if standard +/- error)';
COMMENT ON COLUMN "public"."tbl_geochronology"."error_younger" IS 'Minus (-) side of the measured error (set same as error_younger if standard +/- error)';
COMMENT ON COLUMN "public"."tbl_geochronology"."notes" IS 'Notes specific to this date';
COMMENT ON COLUMN "public"."tbl_locations"."default_lat_dd" IS 'Default latitude in decimal degrees for location, e.g. mid point of country. Leave empty if not known.';
COMMENT ON COLUMN "public"."tbl_locations"."default_long_dd" IS 'Default longitude in decimal degrees for location, e.g. mid point of country';
COMMENT ON COLUMN "public"."tbl_modification_types"."modification_type_description" IS 'Clear explanation of modification so that name makes sense to non-domain scientists';
COMMENT ON COLUMN "public"."tbl_modification_types"."modification_type_name" IS 'Short name of modification, e.g. carbonised';
COMMENT ON COLUMN "public"."tbl_physical_samples"."alt_ref_type_id" IS 'Type of name represented by primary sample name, e.g. Lab number, museum number etc.';
COMMENT ON COLUMN "public"."tbl_physical_samples"."sample_name" IS 'Reference number or name of sample. Multiple references/names can be added as alternative references.';
COMMENT ON COLUMN "public"."tbl_physical_samples"."sample_type_id" IS 'Physical form of sample, e.g. bulk sample, kubienta subsample, core subsample, dendro core, dendro slice...';
COMMENT ON COLUMN "public"."tbl_project_stages"."description" IS 'Explanation of stage name term, including details of purpose and general contents';
COMMENT ON COLUMN "public"."tbl_project_stages"."stage_name" IS 'Stage of project in investigative cycle, e.g. desktop study, prospection, final excavation';
COMMENT ON COLUMN "public"."tbl_project_types"."description" IS 'Project type combinations can be used where appropriate, e.g. Teaching/research';
COMMENT ON COLUMN "public"."tbl_project_types"."project_type_name" IS 'Descriptive name for project type, e.g. Consultancy, Research, Teaching; also combinations Consultancy/teaching';
COMMENT ON COLUMN "public"."tbl_projects"."description" IS 'Brief description of project and any useful information for finding out more.';
COMMENT ON COLUMN "public"."tbl_projects"."project_abbrev_name" IS 'Optional. Abbreviation of project name or acronym (e.g. VGV, SWEDAB)';
COMMENT ON COLUMN "public"."tbl_projects"."project_name" IS 'Name of project (e.g. Phil''s PhD thesis, Malmö ringroad Vägverket)';
COMMENT ON COLUMN "public"."tbl_rdb"."location_id" IS 'Geographical source/relevance of the specific code. E.g. the international IUCN classification of species in the UK.';
COMMENT ON COLUMN "public"."tbl_rdb_systems"."location_id" IS 'geaographical relevance of rdb code system, e.g. UK, International, New Forest';
COMMENT ON TABLE "public"."tbl_record_types" IS 'May also use this to group methods - e.g. Phosphate analyses (whereas tbl_method_groups would store the larger group "Palaeo chemical/physical" methods)';
COMMENT ON COLUMN "public"."tbl_record_types"."record_type_description" IS 'Detailed description of group and explanation for grouping';
COMMENT ON COLUMN "public"."tbl_record_types"."record_type_name" IS 'Short name of proxy/proxies in group';
COMMENT ON TABLE "public"."tbl_relative_age_types" IS '20130723PIB: replaced date_updated column with new one with same name but correct data type';
COMMENT ON COLUMN "public"."tbl_relative_age_types"."age_type" IS 'Name of chronological age type, e.g. Archaeological period, Single calendar date, Calendar age range, Blytt-Sernander';
COMMENT ON COLUMN "public"."tbl_relative_age_types"."description" IS 'Description of chronological age type, e.g. Period defined by archaeological and or geological dates representing cultural activity period, Climate period defined by palaeo-vegetation records';
COMMENT ON COLUMN "public"."tbl_relative_ages"."c14_age_older" IS 'C14 age of younger boundary of period (where relevant).';
COMMENT ON COLUMN "public"."tbl_relative_ages"."c14_age_younger" IS 'C14 age of later boundary of period (where relevant). Leave blank for calendar ages.';
COMMENT ON COLUMN "public"."tbl_relative_ages"."cal_age_older" IS '(Approximate) age before present (1950) of earliest boundary of period. Or if calendar age then the calendar age converted to BP.';
COMMENT ON COLUMN "public"."tbl_relative_ages"."cal_age_younger" IS '(Approximate) age before present (1950) of latest boundary of period. Or if calendar age then the calendar age converted to BP.';
COMMENT ON COLUMN "public"."tbl_relative_ages"."description" IS 'A description of the (usually) period.';
COMMENT ON COLUMN "public"."tbl_relative_ages"."notes" IS 'Any further notes not included in the description, such as reliability of definition or fuzzyness of boundaries.';
COMMENT ON COLUMN "public"."tbl_relative_ages"."relative_age_name" IS 'Name of the dating period, e.g. Bronze Age. Calendar ages should be given appropriate names such as AD 1492, 74 BC';
COMMENT ON COLUMN "public"."tbl_relative_dates"."method_id" IS 'Dating method used to attribute sample to period or calendar date.';
COMMENT ON COLUMN "public"."tbl_relative_dates"."notes" IS 'Any notes specific to the dating of this sample to this calendar or period based age';
COMMENT ON TABLE "public"."tbl_sample_dimensions" IS '20120506PIB: depth measurements for samples moved here from tbl_physical_samples';
COMMENT ON COLUMN "public"."tbl_sample_dimensions"."dimension_id" IS 'Details of the dimension measured';
COMMENT ON COLUMN "public"."tbl_sample_dimensions"."dimension_value" IS 'Numerical value of dimension, in the units indicated in the documentation and interface.';
COMMENT ON COLUMN "public"."tbl_sample_dimensions"."method_id" IS 'Method describing dimension measurement, with link to units used';
COMMENT ON COLUMN "public"."tbl_sample_group_sampling_contexts"."description" IS 'Full explanation of the grouping term';
COMMENT ON COLUMN "public"."tbl_sample_group_sampling_contexts"."sampling_context" IS 'Short but meaningful name defining sample group context, e.g. Stratigraphic sequence, Archaeological excavation';
COMMENT ON COLUMN "public"."tbl_sample_group_sampling_contexts"."sort_order" IS 'Allows lists to group similar or associated group context close to each other, e.g. modern investigations together, palaeo investigations together';
COMMENT ON COLUMN "public"."tbl_sample_groups"."method_id" IS 'Sampling method, e.g. Russian auger core, Pitfall traps. Note different from context in that it is specific to method of sample retrieval and not type of investigation.';
COMMENT ON COLUMN "public"."tbl_sample_notes"."note" IS 'Note contents';
COMMENT ON COLUMN "public"."tbl_sample_notes"."note_type" IS 'Origin of the note, e.g. field note, lab note';
COMMENT ON TABLE "public"."tbl_site_natgridrefs" IS '20120507PIB: removed tbl_national_grids and trasfered storage of coordinate systems to tbl_methods';
COMMENT ON COLUMN "public"."tbl_site_natgridrefs"."method_id" IS 'Points to coordinate system.';
COMMENT ON COLUMN "public"."tbl_site_other_records"."biblio_id" IS 'Reference to publication containing data';
COMMENT ON COLUMN "public"."tbl_site_other_records"."record_type_id" IS 'Reference to type of data (proxy)';
COMMENT ON COLUMN "public"."tbl_site_preservation_status"."assessment_author_contact_id" IS 'Person or authority in tbl_contacts responsible for the assessment of preservation status and threat';
COMMENT ON COLUMN "public"."tbl_site_preservation_status"."assessment_type" IS 'Type of assessment giving information on preservation status and threat, e.g. UNESCO report, archaeological survey';
COMMENT ON COLUMN "public"."tbl_site_preservation_status"."description" IS 'Brief description of site preservation status or threat to site preservation. Include data here that does not fit in the other fields (for now - we may expand these features later if demand exists)';
COMMENT ON COLUMN "public"."tbl_site_preservation_status"."preservation_status_or_threat" IS 'Descriptive name for:
Preservation status, e.g. (e.g. lost, damaged, threatened) OR
Main reason for potential or real risk to site (e.g. hydroelectric, oil exploitation, mining, forestry, climate change, erosion)';
COMMENT ON COLUMN "public"."tbl_site_preservation_status"."site_id" IS 'Allows multiple preservation/threat records per site';
COMMENT ON COLUMN "public"."tbl_sites"."site_location_accuracy" IS 'Accuracy of highest location resolution level. E.g. Nearest settlement, lake, bog, ancient monument, approximate';
COMMENT ON TABLE "public"."tbl_species_associations" IS '20131001PIB: removed not null constraint from biblio_id to allow associations without reference';
COMMENT ON COLUMN "public"."tbl_species_associations"."referencing_type" IS 'Refers to bibliographic reference - how publication  indicates the association (e.g. experimentally shown, observation in the wild etc.)';
COMMENT ON TABLE "public"."tbl_taxa_images" IS '';
COMMENT ON TABLE "public"."tbl_taxa_reference_specimens" IS '';
COMMENT ON COLUMN "public"."tbl_taxa_seasonality"."location_id" IS 'Geographical relevance of seasonality data';
COMMENT ON TABLE "public"."tbl_taxa_synonyms" IS '20131001PIB: This table will be made obsolete through the use of tbl_species_associations for recording synonyms. This transition will require modification of Toby''s Bugs to SEAD scripts, which will be taken care of later';
COMMENT ON TABLE "public"."tbl_taxa_tree_master" IS '20131001PIB: Scope of table expanded to include synonyms as records in this table only. Synonym references are now made using tbl_species_associations to link two taxa - one as master, the other as synonym.
20130416PIB: removed default=0 for author_id and genus_id as was incorrect';

------ Comments associated to recent changes
COMMENT ON TABLE "public"."tbl_analysis_entity_ages" IS '20170911PIB: Changed numeric ranges of values to 20,5 to match tbl_relative_ages
20120504PIB: Should this be connected to physical sample instead of analysis entities? Allowing multiple ages (from multiple dates) for a sample. At the moment it requires a lot of backtracing to find a sample''s age... but then again, it allows... what, exactly?';
COMMENT ON TABLE "public"."tbl_analysis_entity_prep_methods" IS '20170907PIB: Devolved due to problems in isolating measurement datasets with pretreatment/without. Many to many between datasets and methods used as replacement.
20120506PIB: created to cater for multiple preparation methods for analysis but maintaining simple dataset concept.';
COMMENT ON TABLE "public"."tbl_biblio" IS '20170906 PIB: Massive reduction in number of fields to simplify reference management';
COMMENT ON TABLE "public"."tbl_chronologies" IS '20170911PIB: Removed Not Null requirement for sample-group_id to allow for chronologies not tied to a single sample group (e.e. calibrated ages for DataArc or other projects)
Increased length of some fields.
20120504PIB: Note that the dropped age type recorded the type of dates (C14 etc) used in constructing the chronology... but is only one per chonology enough? Can a chronology not be made up of mulitple types of age? (No, years types can only be of one sort - need to calibrate if mixed?)';
COMMENT ON TABLE "public"."tbl_relative_dates" IS '20120504PIB: Added method_id to store dating method used to attribute sample to period or calendar date (e.g. strategraphic dating, typological)
20130722PIB: added field dating_uncertainty_id to cater for "from", "to" and "ca." etc. especially from import of BugsCEP
20170906PIB: removed fk physical_samples_id and replaced with analysis_entity_id';
COMMENT ON TABLE "public"."tbl_ceramics_lookup" IS 'Type=lookup';
COMMENT ON COLUMN "public"."tbl_chronologies"."relative_age_type_id" IS 'Constraint removed to obsolete table (tbl_age_types), replaced by non-binding id of relative_age_types - but not fully implemented. Notes should be used to inform on chronology years types and construction.';
COMMENT ON TABLE "public"."tbl_dendro_lookup" IS 'Type=lookup';
COMMENT ON COLUMN "public"."tbl_sites"."site_location_accuracy" IS 'Accuracy of highest location resolution level. E.g. Nearest settlement, lake, bog, ancient monument, approximate';


