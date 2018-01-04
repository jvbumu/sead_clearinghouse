--
-- PostgreSQL database dump
--

-- Dumped from database version 9.4.13
-- Dumped by pg_dump version 10.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: clearing_house; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA clearing_house;


--
-- Name: metainformation; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA metainformation;


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: tablefunc; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS tablefunc WITH SCHEMA public;


--
-- Name: EXTENSION tablefunc; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION tablefunc IS 'functions that manipulate whole tables, including crosstab';


SET search_path = public, pg_catalog;

--
-- Name: breakpoint; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE breakpoint AS (
	func oid,
	linenumber integer,
	targetname text
);


--
-- Name: dblink_pkey_results; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE dblink_pkey_results AS (
	"position" integer,
	colname text
);


--
-- Name: frame; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE frame AS (
	level integer,
	targetname text,
	func oid,
	linenumber integer,
	args text
);


--
-- Name: proxyinfo; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE proxyinfo AS (
	serverversionstr text,
	serverversionnum integer,
	proxyapiver integer,
	serverprocessid integer
);


--
-- Name: targetinfo; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE targetinfo AS (
	target oid,
	schema oid,
	nargs integer,
	argtypes oidvector,
	targetname name,
	argmodes character(1)[],
	argnames text[],
	targetlang oid,
	fqname text,
	returnsset boolean,
	returntype oid
);


--
-- Name: tbiblio; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE tbiblio AS (
	reference character varying(60),
	author character varying(255),
	title text,
	notes text
);


--
-- Name: tcountsheet; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE tcountsheet AS (
	countsheetcode character varying(10),
	countsheetname character varying(100),
	sitecode character varying(10),
	sheetcontext character varying(25),
	sheettype character varying(25)
);


--
-- Name: tfossil; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE tfossil AS (
	fossilbugscode character varying(10),
	code numeric(18,10),
	samplecode character varying(10),
	abundance integer
);


--
-- Name: tsample; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE tsample AS (
	samplecode character varying(10),
	sitecode character varying(10),
	x character varying(50),
	y character varying(50),
	zordepthtop numeric(18,10),
	zordepthbot numeric(18,10),
	refnrcontext character varying(50),
	countsheetcode character varying(10)
);


--
-- Name: var; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE var AS (
	name text,
	varclass character(1),
	linenumber integer,
	isunique boolean,
	isconst boolean,
	isnotnull boolean,
	dtype oid,
	value text
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: fn_add_new_public_db_columns(integer, character varying); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_add_new_public_db_columns(integer, character varying) RETURNS void
    LANGUAGE plpgsql
    AS $_$

	Declare xml_columns character varying(255)[];
	Declare schema_columns character varying(255)[];
	Declare sql text;
	Declare x RECORD;
	
Begin

	xml_columns := clearing_house.fn_get_submission_table_column_names($1, $2);

	If array_length(xml_columns, 1) = 0 Then
		Raise Exception 'Fatal error. Table % has unknown fields.', $2;
		Return;
	End If;
	
	If Not clearing_house.fn_table_exists($2) Then
	
		sql := 'Create Table clearing_house.' || $2 || ' (
		
			submission_id int not null,
			source_id int not null,
			
			local_db_id int not null,
			public_db_id int null,

			Constraint pk_' || $2 || '_' || xml_columns[1] || ' Primary Key (submission_id, ' || xml_columns[1] || ')
			
		) ';

		Raise Notice '%', sql;
--		Execute sql;
		
	End If;

	For x In (
		Select t.table_name_underscored, c.column_name_underscored, c.data_type
		From clearing_house.tbl_clearinghouse_submission_tables t
		Join clearing_house.tbl_clearinghouse_submission_xml_content_columns c
		  On c.table_id = t.table_id
		Left Join INFORMATION_SCHEMA.columns ic
		  On ic.table_schema = 'clearing_house'
		 And ic.table_name = t.table_name_underscored
		 And ic.column_name = c.column_name_underscored
		Where c.submission_id = $1
		  And t.table_name_underscored = $2
		  And c.column_name_underscored <> 'cloned_id'
		  And ic.table_name Is Null
	) Loop

		sql := 'Alter Table clearing_house.' || $2 || ' Add Column ' || x.column_name_underscored || ' ' || clearing_house.fn_java_type_to_PostgreSQL(x.data_type) || ' null;';

		Execute sql;

		Raise Notice 'Added new column: % % % [%]', x.table_name_underscored,  x.column_name_underscored , clearing_house.fn_java_type_to_PostgreSQL(x.data_type), sql;

	End Loop;
	
End $_$;


--
-- Name: fn_clearinghouse_info_references(); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_info_references() RETURNS TABLE(info_reference_id integer, info_reference_type character varying, display_name character varying, href character varying)
    LANGUAGE plpgsql
    AS $$
Begin
	Return Query
		Select x.info_reference_id, x.info_reference_type, x.display_name, x.href
        From clearing_house.tbl_clearinghouse_info_references x
        Order By 1;
		
End $$;


--
-- Name: fn_clearinghouse_latest_accepted_sites(); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_latest_accepted_sites() RETURNS TABLE(last_updated_sites text)
    LANGUAGE plpgsql
    AS $$
Begin
	Return Query
		Select site
		From (
			Select Distinct s.site_name || ', ' || d.dataset_name || ', ' || m.method_name as site, d.date_updated
			From public.tbl_datasets d
			Join public.tbl_analysis_entities ae
			  On ae.dataset_id = d.dataset_id
			Join public.tbl_physical_samples ps
			  On ps.physical_sample_id = ae.physical_sample_id
			Join public.tbl_sample_groups sg
			  On sg.sample_group_id = ps.sample_group_id
			Join public.tbl_sites s
			  On s.site_id = sg.site_id
			Join public.tbl_methods m
			  On m.method_id = d.method_id
			Order By d.date_updated Desc
			Limit 10
		) as x;
		
End $$;


--
-- Name: fn_clearinghouse_report_bibliographic_entries(integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_report_bibliographic_entries(integer) RETURNS TABLE(local_db_id integer, reference text, collection character varying, publisher character varying, publisher_place character varying, public_db_id integer, public_reference text, public_collection character varying, public_publisher character varying, public_publisher_place character varying, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$

Declare
    entity_type_id int;

Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_biblio');

	Return Query

		Select 
			LDB.local_db_id                            	As local_db_id,
			LDB.reference                               As reference, 
			LDB.collection                              As collection, 
			LDB.publisher                               As publisher, 
			LDB.publisher_place                         As publisher_place, 

			LDB.public_db_id                            As public_db_id,
			RDB.reference                               As public_reference, 
			RDB.collection                              As public_collection, 
			RDB.publisher                               As public_publisher, 
			RDB.publisher_place                         As public_publisher_place, 

			to_char(LDB.date_updated,'YYYY-MM-DD')		As date_updated,
			entity_type_id              				As entity_type_id
		From (
		
			Select	b.submission_id																			as submission_id,
					b.source_id																				as source_id,
					b.biblio_id																				as local_db_id,
					b.public_db_id																			as public_db_id,
					b.author || ' (' || b.year || ')'														as reference, 
					Coalesce(c.collection_or_journal_abbrev, c.collection_title_or_journal_name, '')		as collection,
					p.publisher_name 																		as publisher,
					p.place_of_publishing_house																as publisher_place,
					b.date_updated																			as date_updated
			From clearing_house.view_biblio b
			Join clearing_house.view_collections_or_journals c
			  On c.collection_or_journal_id = b.collection_or_journal_id
			 And c.submission_id In (0, b.submission_id)
			Join clearing_house.view_publishers p
			  On p.submission_id In (0, b.submission_id)
			 And p.publisher_id = c.publisher_id
		) As LDB Left Join (
			Select	b.biblio_id																				as biblio_id,
					b.author || ' (' || b.year || ')'														as reference, 
					Coalesce(c.collection_or_journal_abbrev, c.collection_title_or_journal_name, '')		as collection,
					p.publisher_name 																		as publisher,
					p.place_of_publishing_house																as publisher_place,
					b.date_updated																			as date_updated
			From public.tbl_biblio b
			Join public.tbl_collections_or_journals c
			  On c.collection_or_journal_id = b.collection_or_journal_id
			Join public.tbl_publishers p
			  On p.publisher_id = c.publisher_id
		) As RDB
		  On RDB.biblio_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1;
		  
End $_$;


--
-- Name: fn_clearinghouse_report_datasets(integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_report_datasets(integer) RETURNS TABLE(local_db_id integer, dataset_name character varying, method_name character varying, method_abbrev_or_alt_name character varying, description text, record_type_name character varying, public_db_id integer, public_dataset_name character varying, public_method_name character varying, public_method_abbrev_or_alt_name character varying, public_description text, public_record_type_name character varying, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$

Declare
    entity_type_id int;

Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_datasets ');

	Return Query

		Select 
		
			LDB.local_db_id                             			As local_db_id,

            LDB.dataset_name		                                As dataset_name,
            LDB.method_name                                         As method_name,
            LDB.method_abbrev_or_alt_name		                    As method_abbrev_or_alt_name,
            LDB.description		                                 	As description,
            LDB.record_type_name		                            As record_type_name,

			LDB.public_db_id                            			As public_db_id,

            RDB.dataset_name		                                As public_dataset_name,
            RDB.method_name                                         As public_method_name,
            RDB.method_abbrev_or_alt_name		                    As public_method_abbrev_or_alt_name,
            RDB.description		                                 	As public_description,
            RDB.record_type_name		                            As public_record_type_name,

			to_char(LDB.date_updated,'YYYY-MM-DD')					As date_updated,
            entity_type_id                             				As entity_type_id

		From (                            

			Select  d.submission_id                                 As submission_id,
                    d.source_id                                     As source_id,
                    d.local_db_id									As local_db_id,
                    d.public_db_id									As public_db_id,
                    d.dataset_name                                  As dataset_name,
                    m.method_name                                   As method_name,
                    m.method_abbrev_or_alt_name                     As method_abbrev_or_alt_name,
                    m.description                                   As description,
                    rt.record_type_name                             As record_type_name,
                    d.date_updated                                 As date_updated
            From clearing_house.view_datasets d
            Left Join clearing_house.view_methods m
              On m.merged_db_id = d.method_id
             And m.submission_id In (0, d.method_id)
            Left Join clearing_house.view_record_types rt
              On rt.merged_db_id = rt.record_type_id
             And rt.submission_id In (0, d.method_id)

		) As LDB Left Join (
		
            select  d.dataset_id                                    As dataset_id,
                    d.dataset_name                                  As dataset_name,
                    m.method_name                                   As method_name,
                    m.method_abbrev_or_alt_name                     As method_abbrev_or_alt_name,
                    m.description                                   As description,
                    rt.record_type_name                             As record_type_name
            from tbl_datasets d
            left join tbl_methods m
              on d.method_id = m.method_id
            left join tbl_record_types rt
              on m.record_type_id = rt.record_type_id
            /*
            join ( -- Unique relation dataset -> sites (om sites data ska tas med)
                select distinct d.dataset_id, s.site_id
                from tbl_datasets d
                left join tbl_analysis_entities
                  on tbl_analysis_entities.dataset_id = d.dataset_id
                join tbl_physical_samples ps
                  on tbl_analysis_entities.physical_sample_id = ps.physical_sample_id
                left join tbl_sample_groups
                  on ps.sample_group_id = tbl_sample_groups.sample_group_id
                join tbl_sites s
                  on tbl_sample_groups.site_id = s.site_id
            ) as ds
              on ds.dataset_id =  d.dataset_id
            */
              
		) As RDB
		  On RDB.dataset_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		Order By LDB.dataset_name;
		
End $_$;


--
-- Name: fn_clearinghouse_report_locations(integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_report_locations(integer) RETURNS TABLE(local_db_id integer, entity_type_id integer, location_id integer, location_name character varying, default_lat_dd numeric, default_long_dd numeric, date_updated text, location_type_id integer, location_type character varying, description text, public_location_id integer, public_location_name character varying, public_default_lat_dd numeric, public_default_long_dd numeric, public_location_type_id integer, public_location_type character varying, public_description text)
    LANGUAGE plpgsql
    AS $_$

Declare
    entity_type_id int;

Begin

	entity_type_id := clearing_house.fn_get_entity_type_for('tbl_locations');
	
	Return Query
		Select	l.local_db_id						                            as local_db_id,
				entity_type_id						                            as entity_type_id,
				l.local_db_id						                            as location_id,
				l.location_name						                            as location_name,
				l.default_lat_dd                                                as default_lat_dd,
				l.default_long_dd                                               as default_long_dd,
				to_char(l.date_updated,'YYYY-MM-DD')                            as date_updated,
				l.location_type_id                                              as location_type_id, 
				Coalesce(t.location_type, p.location_type)						as location_type, 
				t.description						                            as description,

				p.location_id						                            as public_location_id,
				p.location_name						                            as public_location_name, 
				p.default_lat_dd					                            as public_default_lat_dd, 
				p.default_long_dd					                            as public_default_long_dd, 
				p.location_type_id					                            as public_location_type_id, 
				p.location_type						                            as public_location_type, 
				p.description						                            as public_description
				
		From clearing_house.view_locations l
		Join clearing_house.view_location_types t
		  On t.merged_db_id = l.location_type_id
		 And t.submission_id In (0, l.submission_id)
		Full Outer Join(
			Select l.location_id, l.location_name, l.default_lat_dd, l.default_long_dd, t.location_type_id, t.location_type, t.description
			From public.tbl_locations l
			Join public.tbl_location_types t
			  On t.location_type_id = l.location_type_id
		) as p
		  On p.location_id = l.public_db_id
		Where l.submission_id = $1;
	
End $_$;


--
-- Name: fn_clearinghouse_report_methods(integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_report_methods(integer) RETURNS TABLE(local_db_id integer, method_name character varying, method_abbrev_or_alt_name character varying, description text, record_type_name character varying, group_name character varying, group_description text, unit_name character varying, public_db_id integer, public_method_name character varying, public_method_abbrev_or_alt_name character varying, public_description text, public_record_type_name character varying, public_group_name character varying, public_group_description text, public_unit_name character varying, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$

Declare
    entity_type_id int;

Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_datasets ');

	Return Query

		Select 
		
			LDB.local_db_id                             			As local_db_id,

            LDB.method_name                                         As method_name,
            LDB.method_abbrev_or_alt_name		                    As method_abbrev_or_alt_name,
            LDB.description		                                 	As description,
            LDB.record_type_name		                            As record_type_name,
            LDB.group_name		                           			As group_name,
            LDB.group_description		                            As group_description,
            LDB.unit_name		                            		As unit_name,

			LDB.public_db_id                            			As public_db_id,

            RDB.method_name                                         As method_name,
            RDB.method_abbrev_or_alt_name		                    As method_abbrev_or_alt_name,
            RDB.description		                                 	As description,
            RDB.record_type_name		                            As record_type_name,
            RDB.group_name		                           			As group_name,
            RDB.group_description		                            As group_description,
            RDB.unit_name		                            		As unit_name,

			to_char(LDB.date_updated,'YYYY-MM-DD')					As date_updated,
            entity_type_id                             				As entity_type_id

		From (                            

			Select  m.submission_id                                 As submission_id,
                    m.source_id                                     As source_id,
                    m.local_db_id									As local_db_id,
                    m.public_db_id									As public_db_id,
					m.method_name                                   As method_name,
					m.method_abbrev_or_alt_name                     As method_abbrev_or_alt_name,
					m.description                                   As description,
					rt.record_type_name                             As record_type_name,
					mg.group_name									As group_name,
					mg.description									As group_description,
					u.unit_name										As unit_name,
					m.date_updated									As date_updated
			From clearing_house.view_methods m
			Left Join clearing_house.view_record_types rt
			  on rt.merged_db_id = m.record_type_id
			 And rt.submission_id In (0, m.submission_id)
			Left Join clearing_house.view_method_groups mg
			  on mg.merged_db_id = m.method_group_id
			 And mg.submission_id In (0, m.submission_id)
			Left Join clearing_house.view_units u
			  On u.merged_db_id = m.unit_id
			 And u.submission_id In (0, m.submission_id)


		) As LDB Left Join (
		
			select  m.method_id                                    	As method_id,
					m.method_name                                   As method_name,
					m.method_abbrev_or_alt_name                     As method_abbrev_or_alt_name,
					m.description                                   As description,
					rt.record_type_name                             As record_type_name,
					mg.group_name									As group_name,
					mg.description									As group_description,
					u.unit_name										As unit_name
			from tbl_methods m
			left join tbl_record_types rt
			  on m.record_type_id = rt.record_type_id
			left join tbl_method_groups mg
			  on mg.method_group_id = m.method_group_id
			left join tbl_units u
			  on u.unit_id = m.unit_id
		) As RDB
		  On RDB.method_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		Order By LDB.method_name;
		
End $_$;


--
-- Name: fn_clearinghouse_report_relative_ages(integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_report_relative_ages(integer) RETURNS TABLE(local_db_id integer, sample_name character varying, abbreviation character varying, location_name character varying, uncertainty character varying, method_name character varying, c14_age_older numeric, c14_age_younger numeric, cal_age_older numeric, cal_age_younger numeric, relative_age_name character varying, notes text, reference text, public_db_id integer, public_sample_name character varying, public_abbreviation character varying, public_location_name character varying, public_uncertainty character varying, public_method_name character varying, public_c14_age_older numeric, public_c14_age_younger numeric, public_cal_age_older numeric, public_cal_age_younger numeric, public_relative_age_name character varying, public_notes text, public_reference text, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$

Declare
    entity_type_id int;

Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_relative_ages ');

	Return Query

		Select 
		
			LDB.local_db_id                             			As local_db_id,

            LDB.sample_name		                                 	As sample_name,
            LDB.abbreviation		                                As abbreviation,
            LDB.location_name		                                As location_name,
            LDB.uncertainty		                                 	As uncertainty,
            LDB.method_name		                                 	As method_name,
            LDB.C14_age_older		                                As C14_age_older,
            LDB.C14_age_younger		                                As C14_age_younger,
            LDB.CAL_age_older		                                As CAL_age_older,
            LDB.CAL_age_younger		                                As CAL_age_younger,
            LDB.relative_age_name		                            As relative_age_name,
            LDB.notes		                                 		As notes,
            LDB.reference		                                 	As reference,
		
			LDB.public_db_id                            			As public_db_id,

            LDB.sample_name		                                 	As public_sample_name,
            LDB.abbreviation		                                As public_abbreviation,
            LDB.location_name		                                As public_location_name,
            LDB.uncertainty		                                 	As public_uncertainty,
            LDB.method_name		                                 	As public_method_name,
            LDB.C14_age_older		                                As public_C14_age_older,
            LDB.C14_age_younger		                                As public_C14_age_younger,
            LDB.CAL_age_older		                                As public_CAL_age_older,
            LDB.CAL_age_younger		                                As public_CAL_age_younger,
            LDB.relative_age_name		                            As public_relative_age_name,
            LDB.notes		                                 		As public_notes,
            LDB.reference		                                 	As public_reference,

			to_char(LDB.date_updated,'YYYY-MM-DD')					As date_updated,
            entity_type_id                             				As entity_type_id

		From (                            

			select  ra.submission_id								As submission_id,
                    ra.source_id									As source_id,
                    ra.relative_age_id								As local_db_id,
                    ra.public_db_id									As public_db_id,

                    ps.sample_name                                 	As sample_name,
                    ''::character varying              				As abbreviation, /* NOTE! Missing in development schema */
                    l.location_name									As location_name,
                    du.uncertainty									As uncertainty,
                    m.method_name									As method_name,
                    ra.C14_age_older								As C14_age_older,
                    ra.C14_age_younger								As C14_age_younger,
                    ra.CAL_age_older								As CAL_age_older,
                    ra.CAL_age_younger								As CAL_age_younger,
                    ra.relative_age_name							As relative_age_name,
                    ra.notes										As notes,
                    b.author || '(' || b.year::varchar || ')'		As reference,

                    ra.date_updated									As date_updated

            From clearing_house.view_relative_dates rd
            Join clearing_house.view_physical_samples ps
              On ps.merged_db_id = rd.physical_sample_id
             And ps.submission_id In (0, rd.submission_id)
            Join clearing_house.view_relative_ages ra
              On ra.merged_db_id = rd.relative_age_id
             And ra.submission_id In (0, rd.submission_id)
            Join clearing_house.view_methods m
              On m.merged_db_id = rd.method_id
             And m.submission_id In (0, rd.submission_id)
            Join clearing_house.view_dating_uncertainty du
              On du.merged_db_id = rd.dating_uncertainty_id
             And du.submission_id In (0, rd.submission_id)
            Join clearing_house.view_relative_age_types rat
              On rat.merged_db_id = ra.relative_age_type_id
             And rat.submission_id In (0, rd.submission_id)
            Join clearing_house.view_locations l
              On l.merged_db_id = ra.location_id
             And l.submission_id In (0, rd.submission_id)
            Join clearing_house.view_relative_age_refs raf
              On raf.relative_age_id = ra.merged_db_id
             And raf.submission_id In (0, rd.submission_id)
            Join clearing_house.view_biblio b
              On b.merged_db_id = raf.biblio_id
             And b.submission_id In (0, rd.submission_id)

		) As LDB Left Join (
		
           Select 	ra.relative_age_id								As relative_age_id,
					ps.sample_name									As sample_name,
                    ra."Abbreviation"          						As abbreviation,
                    l.location_name									As location_name,
                    du.uncertainty									As uncertainty,
                    m.method_name									As method_name,
                    ra.C14_age_older								As C14_age_older,
                    ra.C14_age_younger								As C14_age_younger,
                    ra.CAL_age_older								As CAL_age_older,
                    ra.CAL_age_younger								As CAL_age_younger,
                    ra.relative_age_name							As relative_age_name,
                    ra.notes										As notes,
                    b.author || '(' || b.year::varchar || ')'		As reference
            From tbl_relative_dates rd
            Join tbl_physical_samples ps
              On ps.physical_sample_id  = rd.physical_sample_id
            Join tbl_relative_ages ra
              On ra.relative_age_id = rd.relative_age_id
            Join tbl_methods m
              On m.method_id = rd.method_id
            Join tbl_dating_uncertainty du
              On du.dating_uncertainty_id = rd.dating_uncertainty_id
            Join tbl_relative_age_types rat
              On rat.relative_age_type_id = ra.relative_age_type_id
            Join tbl_locations l
              On l.location_id = ra.location_id
            Join tbl_relative_age_refs raf
              On raf.relative_age_id = ra.relative_age_id
            Join tbl_biblio b
              On b.biblio_id = raf.biblio_id
              
		) As RDB
		  On RDB.relative_age_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		Order By LDB.sample_name;
		
End $_$;


--
-- Name: fn_clearinghouse_report_taxa_ecocodes(integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_report_taxa_ecocodes(integer) RETURNS TABLE(local_db_id integer, species text, abbreviation character varying, label character varying, definition text, notes text, group_label character varying, system_name character varying, reference text, public_db_id integer, public_species text, public_abbreviation character varying, public_label character varying, public_definition text, public_notes text, public_group_label character varying, public_system_name character varying, public_reference text, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$

Declare
    entity_type_id int;

Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_ecocodes ');

	Return Query

		Select 
			LDB.local_db_id                            	As local_db_id,

			LDB.species,
			LDB.abbreviation,
			LDB.label,
			LDB.definition, 
			LDB.notes,
			LDB.group_label,
			LDB.system_name,
			LDB.reference,
			
  			LDB.public_db_id                            As public_db_id,

			RDB.public_species,
			RDB.public_abbreviation,
			RDB.public_label,
			RDB.public_definition, 
			RDB.public_notes,
			RDB.public_group_label,
			RDB.public_system_name,
			RDB.public_reference,


			to_char(LDB.date_updated,'YYYY-MM-DD')		As date_updated,
			entity_type_id              				As entity_type_id

		From (
                                
				select t.submission_id,
					t.source_id,
					t.taxon_id As local_db_id,
					t.public_db_id As public_db_id,
					g.genus_name || ' ' || t.species || ' ' || coalesce(a.author_name, '')	As species,
					ed.abbreviation,
					ed.label,
					ed.definition,
					ed.notes,
					eg.label as group_label,
					es.name as system_name,
					b.author || '(' || b.year || ')' as reference,
					t.date_updated

				from clearing_house.view_taxa_tree_master t
				join clearing_house.view_taxa_tree_genera g
				  on t.genus_id = g.merged_db_id
				 and g.submission_id in (0, t.submission_id)
				left join clearing_house.view_taxa_tree_authors a
				  on t.author_id = a.merged_db_id
				 and a.submission_id in (0, t.submission_id)
                                join clearing_house.view_ecocodes e
                                  on e.taxon_id = t.merged_db_id
                                 and e.submission_id in (0, t.submission_id)
                                join clearing_house.view_ecocode_definitions ed
                                  on ed.merged_db_id = e.ecocode_definition_id
                                 and ed.submission_id in (0, t.submission_id)
                                join clearing_house.view_ecocode_groups eg
                                  on eg.merged_db_id = ed.ecocode_group_id
                                 and eg.submission_id in (0, t.submission_id)
                                join clearing_house.view_ecocode_systems es
                                  on es.merged_db_id = eg.ecocode_system_id
                                 and es.submission_id in (0, t.submission_id)
				Join clearing_house.view_biblio b
				  On b.merged_db_id = es.biblio_id
				 And b.submission_id in (0, t.submission_id)
                                
		
		) As LDB Left Join (

				select 
					t.taxon_id As taxon_id,
					g.genus_name || ' ' || t.species || ' ' || coalesce(a.author_name, '')	As public_species,
					ed.abbreviation as public_abbreviation,
					ed.label as public_label,
					ed.definition as public_definition,
					ed.notes as public_notes,
					eg.label as public_group_label,
					es.name as public_system_name,
					b.author || '(' || b.year || ')' as public_reference,
					t.date_updated

				from public.tbl_taxa_tree_master t
				join public.tbl_taxa_tree_genera g
				  on t.genus_id = g.genus_id
				left join public.tbl_taxa_tree_authors a
				  on t.author_id = a.author_id
				join public.tbl_ecocodes e
				  on e.taxon_id = t.taxon_id
				join public.tbl_ecocode_definitions ed
				  on ed.ecocode_definition_id = e.ecocode_definition_id
				join public.tbl_ecocode_groups eg
				  on eg.ecocode_group_id = ed.ecocode_group_id
				join public.tbl_ecocode_systems es
				  on es.ecocode_system_id = eg.ecocode_system_id
				Join public.tbl_biblio b
				  On b.biblio_id = es.biblio_id

		) As RDB
		  On RDB.taxon_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		Order By LDB.species;
End $_$;


--
-- Name: fn_clearinghouse_report_taxa_other_lists(integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_report_taxa_other_lists(integer) RETURNS TABLE(local_db_id integer, species text, distribution_text text, distribution_reference text, biology_text text, biology_reference text, taxonomy_note_text text, taxonomy_note_reference text, identification_key_text text, identification_key_reference text, public_db_id integer, public_species text, public_distribution_text text, public_distribution_reference text, public_biology_text text, public_biology_reference text, public_taxonomy_note_text text, public_taxonomy_note_reference text, public_identification_key_text text, public_identification_key_reference text, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$

Declare
    entity_type_id int;

Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_taxa_tree_master ');

	Return Query

		Select 
			LDB.local_db_id                            	As local_db_id,
			LDB.species,
			LDB.distribution_text,
			LDB.distribution_reference,
			LDB.biology_text,
			LDB.biology_reference, 
			LDB.taxonomy_note_text,
			LDB.taxonomy_note_reference,
			LDB.identification_key_text,
			LDB.identification_key_reference,
			
  			LDB.public_db_id                            As public_db_id,

            RDB.public_species,
			RDB.public_distribution_text,
			RDB.public_distribution_reference,
			RDB.public_biology_text,
			RDB.public_biology_reference, 
			RDB.public_taxonomy_note_text,
			RDB.public_taxonomy_note_reference,
			RDB.public_identification_key_text,
			RDB.public_identification_key_reference,


			to_char(LDB.date_updated,'YYYY-MM-DD')		As date_updated,
			entity_type_id              				As entity_type_id

		From (
                                
			select t.submission_id,
				t.source_id,
				t.taxon_id As local_db_id,
				t.public_db_id As public_db_id,
				g.genus_name || ' ' || t.species || ' ' || coalesce(a.author_name, '')	As species,
				d.distribution_text,
				db.author || '(' || db.year || ')' as distribution_reference,
				b.biology_text,
				bb.author || '(' || bb.year || ')' as biology_reference,
				n.taxonomy_notes as taxonomy_note_text,
				nb.author || '(' || nb.year || ')' as taxonomy_note_reference,
				ik.key_text as identification_key_text,
				ikb.author || '(' || ikb.year || ')' as identification_key_reference,
				t.date_updated
			  from clearing_house.view_taxa_tree_master t
			  join clearing_house.view_taxa_tree_genera g
			   on t.genus_id = g.merged_db_id
			   and g.submission_id in (0, t.submission_id)
			  left join clearing_house.view_taxa_tree_authors a
			   on t.author_id = a.merged_db_id
			   And a.submission_id in (0, t.submission_id)
			  --distribution
			  left join clearing_house.view_text_distribution d
			   on d.taxon_id = t.merged_db_id
			   And d.submission_id in (0, t.submission_id)
			  left Join clearing_house.view_biblio db
			   On db.merged_db_id = d.biblio_id
			   And db.submission_id in (0, t.submission_id)
			  --text biology
			  left join clearing_house.view_text_biology b
			   on b.taxon_id = t.merged_db_id
			   And b.submission_id in (0, t.submission_id)
			  left join clearing_house.view_biblio bb
			   on b.biblio_id = bb.merged_db_id
			   And bb.submission_id in (0, t.submission_id)
			  --taxonomy notes
			  left join clearing_house.view_taxonomy_notes n
			   on n.taxon_id = t.merged_db_id
			   And n.submission_id in (0, t.submission_id)
			  left join clearing_house.view_biblio nb
			   on n.biblio_id = nb.merged_db_id
			   And nb.submission_id in (0, t.submission_id)
			  --identification keys
			  left join clearing_house.view_text_identification_keys ik
			   on ik.taxon_id = t.merged_db_id
			   And ik.submission_id in (0, t.submission_id)
			  left join clearing_house.view_biblio ikb
			   on ik.biblio_id = ikb.merged_db_id
			   And ikb.submission_id in (0, t.submission_id)
		
		) As LDB Left Join (
				select 
				t.taxon_id As taxon_id,
				g.genus_name || ' ' || t.species || ' ' || coalesce(a.author_name, '')	As public_species,
				d.distribution_text as public_distribution_text,
				db.author || '(' || db.year || ')' as public_distribution_reference,
				b.biology_text as public_biology_text,
				bb.author || '(' || bb.year || ')' as public_biology_reference,
				n.taxonomy_notes as public_taxonomy_note_text,
				nb.author || '(' || nb.year || ')' as public_taxonomy_note_reference,
				ik.key_text as public_identification_key_text,
				ikb.author || '(' || ikb.year || ')' as public_identification_key_reference,
				t.date_updated
			  from public.tbl_taxa_tree_master t
			  join public.tbl_taxa_tree_genera g
			   on t.genus_id = g.genus_id
			  left join public.tbl_taxa_tree_authors a
			   on t.author_id = a.author_id
			  --distribution
			  left join public.tbl_text_distribution d
			   on d.taxon_id = t.taxon_id
			  left Join public.tbl_biblio db
			   On db.biblio_id = d.biblio_id
			  --text biology
			  left join public.tbl_text_biology b
			   on b.taxon_id = t.taxon_id
			  left join public.tbl_biblio bb
			   on b.biblio_id = bb.biblio_id
			  --taxonomy notes
			  left join public.tbl_taxonomy_notes n
			   on n.taxon_id = t.taxon_id
			  left join public.tbl_biblio nb
			   on n.biblio_id = nb.biblio_id
			  --identification keys
			  left join public.tbl_text_identification_keys ik
			   on ik.taxon_id = t.taxon_id
			  left join public.tbl_biblio ikb
			   on ik.biblio_id = ikb.biblio_id

		) As RDB
		  On RDB.taxon_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		Order By LDB.species;
End $_$;


--
-- Name: fn_clearinghouse_report_taxa_rdb(integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_report_taxa_rdb(integer) RETURNS TABLE(local_db_id integer, species text, location_name character varying, rdb_category character varying, rdb_definition character varying, rdb_system character varying, reference text, public_db_id integer, public_species text, public_location_name character varying, public_rdb_category character varying, public_rdb_definition character varying, public_rdb_system character varying, public_reference text, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$

Declare
    entity_type_id int;

Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_rdb ');

	Return Query

		Select 
			LDB.local_db_id                            	As local_db_id,

			LDB.species,
			LDB.location_name,
			LDB.rdb_category,
			LDB.rdb_definition,
			LDB.rdb_system,
			LDB.reference,
			
  			LDB.public_db_id                            As public_db_id,

			RDB.public_species,
			RDB.public_location_name,
			RDB.public_rdb_category,
			RDB.public_rdb_definition,
			RDB.public_rdb_system,
			RDB.public_reference,


			to_char(LDB.date_updated,'YYYY-MM-DD')		As date_updated,
			entity_type_id              				As entity_type_id

		From (
                                
				select t.submission_id,
					t.source_id,
					t.taxon_id As local_db_id,
					t.public_db_id As public_db_id,
					g.genus_name || ' ' || t.species || ' ' || coalesce(a.author_name, '')	As species,
					l.location_name, 
					c.rdb_category,
					c.rdb_definition,
					s.rdb_system,
					b.author || '(' || b.year || ')' as reference,
					t.date_updated

				from clearing_house.view_taxa_tree_master t
				join clearing_house.view_taxa_tree_genera g
				  on t.genus_id = g.merged_db_id
				 and g.submission_id in (0, t.submission_id)
				left join clearing_house.view_taxa_tree_authors a
				  on t.author_id = a.merged_db_id
				 and a.submission_id in (0, t.submission_id)
				join clearing_house.view_rdb r
				  on r.taxon_id = t.merged_db_id
				 and r.submission_id in (0, t.submission_id)
				join clearing_house.view_rdb_codes c
				  on c.merged_db_id = r.rdb_code_id
				 and c.submission_id in (0, t.submission_id)
				join clearing_house.view_rdb_systems s
				  on s.merged_db_id = c.rdb_system_id
				 and s.submission_id in (0, t.submission_id)
				Join clearing_house.view_biblio b
				  On b.merged_db_id = s.biblio_id
				 And b.submission_id in (0, t.submission_id)
				join clearing_house.view_locations l
				  on l.merged_db_id = r.location_id
				 and l.submission_id in (0, t.submission_id)
				
		
		) As LDB Left Join (

				select 
					t.taxon_id As taxon_id,
					g.genus_name || ' ' || t.species || ' ' || coalesce(a.author_name, '')	As public_species,
					l.location_name as public_location_name,
					c.rdb_category as public_rdb_category,
					c.rdb_definition as public_rdb_definition,
					s.rdb_system as public_rdb_system,
					b.author || '(' || b.year || ')' as public_reference,
					t.date_updated

				from clearing_house.tbl_taxa_tree_master t
				join clearing_house.tbl_taxa_tree_genera g
				  on t.genus_id = g.genus_id
				left join public.tbl_taxa_tree_authors a
				  on t.author_id = a.author_id
				join public.tbl_rdb r
				  on r.taxon_id = t.taxon_id
				join public.tbl_rdb_codes c
				  on c.rdb_code_id = r.rdb_code_id
				join public.tbl_rdb_systems s
				  on s.rdb_system_id = c.rdb_system_id
				Join public.tbl_biblio b
				  On b.biblio_id = s.biblio_id
				join public.tbl_locations l
				  on l.location_id = r.location_id

		) As RDB
		  On RDB.taxon_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		Order By LDB.species;
End $_$;


--
-- Name: fn_clearinghouse_report_taxa_seasonality(integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_report_taxa_seasonality(integer) RETURNS TABLE(local_db_id integer, species text, season_name character varying, season_type character varying, location_name character varying, activity_type character varying, public_db_id integer, public_species text, public_season_name character varying, public_season_type character varying, public_location_name character varying, public_activity_type character varying, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$

Declare
    entity_type_id int;

Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_taxa_seasonality ');

	Return Query

		Select 
			LDB.local_db_id                             As local_db_id,
			LDB.species                                 As species,
			LDB.season_name                             As season_name,
			LDB.season_type                             As season_type,
			LDB.location_name                           As location_name,
			LDB.activity_type                           As activity_type,
		
			LDB.public_db_id                            As public_db_id,

			RDB.public_species                          As public_species,
			RDB.public_season_name                      As public_season_name,
			RDB.public_season_type                      As public_season_type,
			RDB.public_location_name                    As public_location_name,
			RDB.public_activity_type                    As public_activity_type,


			to_char(LDB.date_updated,'YYYY-MM-DD')		As date_updated,
            entity_type_id                                  As entity_type_id

		From (                            
			select t.submission_id,
			   t.source_id,
			   t.taxon_id As local_db_id,
			   t.public_db_id As public_db_id,
			   g.genus_name || ' ' || t.species || ' ' || coalesce(a.author_name, '')	As species,
			   s.season_name,
			   st.season_type,
			   l.location_name,
			   at.activity_type,
			   t.date_updated
			 from clearing_house.view_taxa_tree_master t
			 join clearing_house.view_taxa_tree_genera g
			  on t.genus_id = g.merged_db_id
			  and g.submission_id in (0, t.submission_id)
			 left join clearing_house.view_taxa_tree_authors a
			  on t.author_id = a.merged_db_id
			  And a.submission_id in (0, t.submission_id)
			left join clearing_house.view_taxa_seasonality ts
			  on ts.merged_db_id = t.taxon_id
			  and ts.submission_id in (0, t.submission_id)
			join clearing_house.view_seasons s
			  on ts.season_id = s.merged_db_id
			  and s.submission_id in (0, t.submission_id)
			join clearing_house.view_season_types st
			  on s.season_type_id = st.merged_db_id
			  and st.submission_id in (0, t.submission_id)
			join clearing_house.view_activity_types at
			  on ts.activity_type_id = at.merged_db_id
			  and at.submission_id in (0, t.submission_id)
			join clearing_house.view_locations l
			  on ts.location_id = l.merged_db_id
			  and l.submission_id in (0, t.submission_id)
		
		) As LDB Left Join (
            select 
               t.taxon_id As taxon_id,
               g.genus_name || ' ' || t.species || ' ' || coalesce(a.author_name, '')	As public_species,
               s.season_name as public_season_name,
               st.season_type as public_season_type,
               l.location_name as public_location_name,
               at.activity_type as public_activity_type,
               t.date_updated
            from public.tbl_taxa_tree_master t
            join public.tbl_taxa_tree_genera g
              on t.genus_id = g.genus_id
             left join public.tbl_taxa_tree_authors a
              on t.author_id = a.author_id
            left join public.tbl_taxa_seasonality ts
              on ts.taxon_id = t.taxon_id
            join public.tbl_seasons s
              on ts.season_id = s.season_id
            join public.tbl_season_types st
              on s.season_type_id = st.season_type_id
            join public.tbl_activity_types at
              on ts.activity_type_id = at.activity_type_id
            join public.tbl_locations l
              on ts.location_id = l.location_id
		) As RDB
		  On RDB.taxon_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		Order By LDB.species;
End $_$;


--
-- Name: fn_clearinghouse_report_taxa_tree_master(integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_report_taxa_tree_master(integer) RETURNS TABLE(local_db_id integer, order_name character varying, family character varying, species text, association_type_name character varying, association_species text, common_name character varying, language_name character varying, public_db_id integer, public_order_name character varying, public_family character varying, public_species text, public_association_type_name character varying, public_association_species text, public_common_name character varying, public_language_name character varying, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$

Declare
    entity_type_id int;

Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_taxa_tree_master ');

	Return Query

		Select 
			LDB.local_db_id                            	As local_db_id,

			LDB.order_name,
			LDB.family,
			LDB.species,
			LDB.association_type_name, 
			LDB.association_species,
			LDB.common_name,
			LDB.language_name,
			
  			LDB.public_db_id                            As public_db_id,

			RDB.public_order_name,
			RDB.public_family,
			RDB.public_species,
			RDB.public_association_type_name, 
			RDB.public_association_species,
			RDB.public_common_name,
			RDB.public_language_name,


			to_char(LDB.date_updated,'YYYY-MM-DD')		As date_updated,
			entity_type_id              				As entity_type_id

		From (
                                
			select t.submission_id,
				t.source_id,
				t.taxon_id As local_db_id,
				t.public_db_id As public_db_id,
				o.order_name as order_name,
				f.family_name as family,
				g.genus_name || ' ' || t.species || ' ' || coalesce(a.author_name, '')	As species,
				sat.association_type_name, 
				sa_genera.genus_name || ' ' || sa_species.species || ' ' || coalesce(sa_authors.author_name, '') as association_species,
				cn.common_name,
				l.language_name_english as language_name,
				t.date_updated
			from clearing_house.view_taxa_tree_master t
			join clearing_house.view_taxa_tree_genera g
			 on t.genus_id = g.merged_db_id
			 and g.submission_id in (0, t.submission_id)
			join clearing_house.view_taxa_tree_families f
			 on g.family_id = f.merged_db_id
			 and f.submission_id in (0, t.submission_id)
			join clearing_house.view_taxa_tree_orders o
			 on o.order_id = f.merged_db_id
			 and o.submission_id in (0, t.submission_id)
			left join clearing_house.view_taxa_tree_authors a
			 on t.author_id = a.merged_db_id
			 and a.submission_id in (0, t.submission_id)
			-- associations
			left join clearing_house.view_species_associations sa
			 on t.taxon_id = sa.merged_db_id
			 and sa.submission_id in (0, t.submission_id)
			left join clearing_house.view_species_association_types sat
			 on sat.association_type_id = sa.merged_db_id
			 and sat.submission_id in (0, t.submission_id)
			left join clearing_house.view_taxa_tree_master sa_species
			 on sa.associated_taxon_id = sa_species.merged_db_id
			 and sa_species.submission_id in (0, t.submission_id)
			left join clearing_house.view_taxa_tree_genera sa_genera
			 on sa_species.genus_id = sa_genera.merged_db_id
			 and sa_genera.submission_id in (0, t.submission_id)
			left join clearing_house.view_taxa_tree_authors sa_authors
			 on sa_species.author_id = sa_authors.merged_db_id
			 and sa_authors.submission_id in (0, t.submission_id)
			-- // end associations
			--common names
			left join clearing_house.view_taxa_common_names cn
			 on cn.merged_db_id = t.taxon_id
			 and cn.submission_id in (0, t.submission_id)
			left join clearing_house.view_languages l
			 on cn.language_id = l.merged_db_id
			 and l.submission_id in (0, t.submission_id)
                                 -- // end common names
		
		) As LDB Left Join (
			select 
				t.taxon_id As taxon_id,
				o.order_name as public_order_name,
				f.family_name as public_family,
				g.genus_name || ' ' || t.species || ' ' || coalesce(a.author_name, '') as public_species,
				sat.association_type_name as public_association_type_name, 
				sa_genera.genus_name || ' ' || sa_species.species || ' ' || coalesce(sa_authors.author_name, '') as public_association_species,
				cn.common_name as public_common_name,
				l.language_name_english as public_language_name
			  from public.tbl_taxa_tree_master t
			  join public.tbl_taxa_tree_genera g
			   on t.genus_id = g.genus_id
			  join public.tbl_taxa_tree_families f
			   on g.family_id = f.family_id
			  join public.tbl_taxa_tree_orders o
			   on o.order_id = f.order_id
			  left join public.tbl_taxa_tree_authors a
			   on t.author_id = a.author_id
			  -- associations
			  left join public.tbl_species_associations sa
			   on t.taxon_id = sa.taxon_id
			  left join public.tbl_species_association_types sat
			   on sat.association_type_id = sa.association_type_id
			  left join public.tbl_taxa_tree_master sa_species
			   on sa.associated_taxon_id = sa_species.taxon_id
			  left join public.tbl_taxa_tree_genera sa_genera
			   on sa_species.genus_id = sa_genera.genus_id
			  left join public.tbl_taxa_tree_authors sa_authors
			   on sa_species.author_id = sa_authors.author_id
			  -- // end associations
			  --common names
			  left join public.tbl_taxa_common_names cn
			   on cn.taxon_id = t.taxon_id
			  left join public.tbl_languages l
			   on cn.language_id = l.language_id
			   -- // end common names

		) As RDB
		  On RDB.taxon_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		Order By LDB.species;
End $_$;


--
-- Name: fn_clearinghouse_report_taxonomic_order(integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_report_taxonomic_order(integer) RETURNS TABLE(local_db_id integer, species text, taxonomic_code numeric, system_name character varying, reference text, public_db_id integer, public_species text, public_taxonomic_code numeric, public_system_name character varying, public_reference text, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$

Declare
    entity_type_id int;

Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_taxonomic_order ');

	Return Query

		Select 
			LDB.local_db_id                            	As local_db_id,

			LDB.species,
			LDB.taxonomic_code,
			LDB.system_name,
			LDB.reference,
			
  			LDB.public_db_id                            As public_db_id,

			RDB.public_species,
			RDB.public_taxonomic_code,
			RDB.public_system_name,
			RDB.public_reference,


			to_char(LDB.date_updated,'YYYY-MM-DD')		As date_updated,
			entity_type_id              				As entity_type_id

		From (

				select t.submission_id,
					   t.source_id,
					   t.taxon_id																As local_db_id,
					   t.public_db_id															As public_db_id,
					   g.genus_name || ' ' || t.species || ' ' || coalesce(a.author_name, '')	As species,
					   o.taxonomic_code,
					   s.system_name,
					   b.author || '(' || b.year || ')' as reference,
					   t.date_updated

				from clearing_house.view_taxa_tree_master t
				join clearing_house.view_taxa_tree_genera g
				  on t.genus_id = g.merged_db_id
				 and g.submission_id in (0, t.submission_id)
				left join clearing_house.view_taxa_tree_authors a
				  on t.author_id = a.merged_db_id
				 and a.submission_id in (0, t.submission_id)
				Join clearing_house.view_taxonomic_order o
				  on o.taxon_id = t.merged_db_id
				 and o.submission_id in (0, t.submission_id)
				Join clearing_house.view_taxonomic_order_systems s
				  On o.taxonomic_order_system_id = s.merged_db_id
				 And s.submission_id in (0, o.submission_id)
				Join clearing_house.view_taxonomic_order_biblio bo
				  On bo.taxonomic_order_system_id = s.merged_db_id
				 And bo.submission_id in (0, o.submission_id)
				Join clearing_house.view_biblio b
				  On b.merged_db_id = bo.biblio_id
				 And b.submission_id in (0, o.submission_id)
				--Where o.submission_id = $1
				--Order by 4 /* species */
		
		) As LDB Left Join (

				select t.taxon_id As taxon_id,
					   g.genus_name || ' ' || t.species || ' ' || coalesce(a.author_name, '')	As public_species,
					   o.taxonomic_code															As public_taxonomic_code,
					   s.system_name															As public_system_name,
					   b.author || '(' || b.year || ')'											as public_reference

				from public.tbl_taxa_tree_master t
				join public.tbl_taxa_tree_genera g
				  on t.genus_id = g.genus_id
				left join public.tbl_taxa_tree_authors a
				  on t.author_id = a.author_id
				Join public.tbl_taxonomic_order o
				  on o.taxon_id = t.taxon_id
				Join public.tbl_taxonomic_order_systems s
				  On o.taxonomic_order_system_id = s.taxonomic_order_system_id
				Join public.tbl_taxonomic_order_biblio bo
				  On bo.taxonomic_order_system_id = s.taxonomic_order_system_id
				Join public.tbl_biblio b
				  On b.biblio_id = bo.biblio_id
				--Where o.submission_id = $1
				--Order by 4 /* species */

		) As RDB
		  On RDB.taxon_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		Order By LDB.species;
End $_$;


--
-- Name: fn_clearinghouse_review_dataset_abundance_values_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_dataset_abundance_values_client_data(integer, integer) RETURNS TABLE(local_db_id integer, public_db_id integer, abundance_id integer, physical_sample_id integer, taxon_id integer, genus_name character varying, species character varying, sample_name character varying, author_name character varying, element_name text, modification_type_name text, identification_level_name text, abundance integer, public_abundance integer, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$
Declare
    entity_type_id int;
    public_ds_id int;
    
Begin
			
    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_abundances');
    
	Select x.public_db_id Into public_ds_id
	From clearing_house.view_datasets x
	Where x.local_db_id = -$2;
	
	Return Query

		Select 

			LDB.local_db_id						               			As local_db_id,
			LDB.public_db_id						               		As public_db_id,
			
			LDB.abundance_id					               			As abundance_id,
			LDB.physical_sample_id				               			As physical_sample_id,
			LDB.taxon_id						               			As taxon_id,

			LDB.genus_name												As genus_name,
			LDB.species													As species,
			LDB.sample_name												As sample_name,
			LDB.author_name												As author_name,
			LDB.element_name											As element_name,
			LDB.modification_type_name									As modification_type_name,
			LDB.identification_level_name								As identification_level_name,
			
			LDB.abundance												As abundance,

			RDB.abundance												As public_abundance,
			
			entity_type_id												As entity_type_id
		-- Select LDB.*
		From clearing_house.view_clearinghouse_dataset_abundances LDB

		Left Join clearing_house.view_dataset_abundances RDB
		  On RDB.dataset_id =  LDB.public_dataset_id
		 And RDB.taxon_id = LDB.public_taxon_id
		 And RDB.abundance_id = LDB.public_db_id
		 And RDB.physical_sample_id = LDB.public_physical_sample_id

		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.local_dataset_id = -$2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_dataset_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_dataset_client_data(integer, integer) RETURNS TABLE(local_db_id integer, dataset_name character varying, data_type_name character varying, master_name character varying, previous_dataset_name character varying, method_name character varying, project_stage_name text, record_type_id integer, public_db_id integer, public_dataset_name character varying, public_data_type_name character varying, public_master_name character varying, public_previous_dataset_name character varying, public_method_name character varying, public_project_stage_name text, public_record_type_id integer, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$

Declare
    entity_type_id int;

Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_physical_samples');

	Return Query

		With sample (submission_id, source_id, local_db_id, public_db_id, merged_db_id, dataset_name, data_type_name, master_name, previous_dataset_name, method_name, project_stage_name, record_type_id) As (
            Select  d.submission_id                                         As submission_id,
                    d.source_id                                             As source_id,
                    d.local_db_id                                           As local_db_id,
                    d.public_db_id                                          As public_db_id,
                    d.merged_db_id                                          As merged_db_id,
                    d.dataset_name                                          As dataset_name,
                    dt.data_type_name                                       As data_type_name,
                    dm.master_name                                          As master_name,
                    ud.dataset_name                                         As previous_dataset_name, 
                    m.method_name                                           As method_name,
                    p.project_name || pt.project_type_name || ps.stage_name As project_stage_name,
                    m.record_type_id                                        As record_type_id
                    /* Används för att skilja proxy types: 1) measured value 2) abundance */
            From clearing_house.view_datasets d
            Join clearing_house.view_data_types dt
              On dt.data_type_id = d.data_type_id
             And dt.submission_id In (0, d.submission_id)
            Left Join clearing_house.view_dataset_masters dm
              On dm.merged_db_id = d.master_set_id
             And dm.submission_id In (0, d.submission_id)
            Left Join clearing_house.view_datasets ud
              On ud.merged_db_id = d.updated_dataset_id
             And ud.submission_id In (0, d.submission_id)
            Join clearing_house.view_methods m
              On m.merged_db_id = d.method_id
             And m.submission_id In (0, d.submission_id)
            Left Join clearing_house.view_projects p
              On p.merged_db_id = d.project_id
             And p.submission_id In (0, d.submission_id)
            Left Join clearing_house.view_project_types pt
              On pt.merged_db_id = p.project_type_id
             And pt.submission_id In (0, d.submission_id)
            Left Join clearing_house.view_project_stages ps
              On ps.merged_db_id = p.project_stage_id
             And ps.submission_id In (0, d.submission_id)
		)
			Select 
				LDB.local_db_id						As local_db_id,
				LDB.dataset_name                    As dataset_name, 
				LDB.data_type_name                  As data_type_name,
				LDB.master_name                     As master_name,
				LDB.previous_dataset_name           As previous_dataset_name,
				LDB.method_name                     As method_name,
				LDB.project_stage_name              As project_stage_name,
				LDB.record_type_id                  As record_type_id,

				LDB.public_db_id					As public_db_id,
				RDB.dataset_name                    As public_dataset_name, 
				RDB.data_type_name                  As public_data_type_name,
				RDB.master_name                     As public_master_name,
				RDB.previous_dataset_name           As public_previous_dataset_name,
				RDB.method_name                     As public_method_name,
				RDB.project_stage_name              As public_project_stage_name,
				RDB.record_type_id                  As public_record_type_id,

                entity_type_id

			From sample LDB
			Left Join sample RDB
			  On RDB.source_id = 2
			 And RDB.public_db_id = LDB.public_db_id
			Where LDB.source_id = 1
			  And LDB.submission_id = $1
			  And LDB.local_db_id = -$2
			  ;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_dataset_contacts_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_dataset_contacts_client_data(integer, integer) RETURNS TABLE(local_db_id integer, first_name character varying, last_name character varying, contact_type_name character varying, public_db_id integer, public_first_name character varying, public_last_name character varying, public_contact_type_name character varying, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$
Declare
    entity_type_id int;
Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_dataset_contacts');

	Return Query

		Select 
			LDB.local_db_id				               					As local_db_id,

			LDB.first_name												As first_name,
			LDB.last_name												As last_name,
			LDB.contact_type_name										As contact_type_name,

			LDB.public_db_id				            				As public_db_id,

			RDB.first_name												As public_first_name,
			RDB.last_name												As public_last_name,
			RDB.contact_type_name										As public_contact_type_name,

			to_char(LDB.date_updated,'YYYY-MM-DD')						As date_updated,
			entity_type_id												As entity_type_id

		From (
			Select	d.source_id                                         As source_id,
					d.submission_id                                     As submission_id,
					d.local_db_id										As dataset_id,
					
					dc.local_db_id										As local_db_id,
					dc.public_db_id										As public_db_id,
					dc.merged_db_id										As merged_db_id,

					c.first_name										As first_name,
					c.last_name											As last_name,
					t.contact_type_name									As contact_type_name,

					dc.date_updated										As date_updated
			From clearing_house.view_datasets d
			Join clearing_house.view_dataset_contacts dc
			  On dc.dataset_id = d.merged_db_id
			 And dc.submission_id In (0, d.submission_id)
			Join clearing_house.view_contacts c
			  On c.merged_db_id = dc.contact_id
			 And c.submission_id In (0, d.submission_id)
			Join clearing_house.view_contact_types t
			  On t.merged_db_id = dc.contact_type_id
			 And t.submission_id In (0, d.submission_id)
 
		) As LDB Left Join (
		
			Select	d.dataset_id										As dataset_id,
					
					dc.contact_id										As contact_id,

					c.first_name										As first_name,
					c.last_name											As last_name,
					t.contact_type_name									As contact_type_name
					
			From public.tbl_datasets d
			Join public.tbl_dataset_contacts dc
			  On dc.dataset_id = d.dataset_id
			Join public.tbl_contacts c
			  On c.contact_id = dc.contact_id
			Join public.tbl_contact_types t
			  On t.contact_type_id = dc.contact_type_id
			 
		  ) As RDB
		  On
		  RDB.contact_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.dataset_id = -$2
		;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_dataset_measured_values_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_dataset_measured_values_client_data(integer, integer) RETURNS TABLE(local_db_id integer, public_db_id integer, sample_name character varying, method_id integer, method_name character varying, prep_method_id integer, prep_method_name character varying, measured_value numeric, public_measured_value numeric, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$
Declare
    entity_type_id int;
    public_ds_id int;
    
Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_physical_samples');
    
	Select x.public_db_id Into public_ds_id
	From clearing_house.view_datasets x
	Where x.local_db_id = -$2;
	
	Return Query

		Select 

			LDB.physical_sample_id				               			As local_db_id,
			RDB.physical_sample_id				               			As public_db_id,

			LDB.sample_name												As sample_name,

			LDB.method_id												As method_id,
			LDB.method_name												As method_name,
			LDB.prep_method_id											As prep_method_id,
			LDB.prep_method_name										As prep_method_name,

			LDB.measured_value											As measured_value,

			RDB.measured_value											As public_measured_value,
			
			entity_type_id												As entity_type_id

		From clearing_house.view_clearinghouse_dataset_measured_values LDB
		Left Join clearing_house.view_dataset_measured_values RDB
		  On RDB.dataset_id = public_ds_id
		 And RDB.physical_sample_id = LDB.public_physical_sample_id
		 And RDB.method_id = LDB.public_method_id
		 And RDB.prep_method_id = LDB.public_prep_method_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.local_dataset_id = -$2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_dataset_submissions_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_dataset_submissions_client_data(integer, integer) RETURNS TABLE(local_db_id integer, first_name character varying, last_name character varying, submission_type character varying, notes text, public_db_id integer, public_first_name character varying, public_last_name character varying, public_submission_type character varying, public_notes text, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$
Declare
    entity_type_id int;
Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_dataset_submissions');

	Return Query

		Select 
		
			LDB.local_db_id				               					As local_db_id,

			LDB.first_name												As first_name,
			LDB.last_name												As last_name,
			LDB.submission_type											As submission_type,
			LDB.notes													As notes,

			LDB.public_db_id				            				As public_db_id,

			RDB.first_name												As public_first_name,
			RDB.last_name												As public_last_name,
			RDB.submission_type											As public_submission_type,
			RDB.notes													As public_notes,

			to_char(LDB.date_updated,'YYYY-MM-DD')						As date_updated,
			
			entity_type_id												As entity_type_id

		From (
		
			Select	d.source_id                                         As source_id,
					d.submission_id                                     As submission_id,
					d.local_db_id										As dataset_id,
					d.public_db_id										As public_dataset_id,
					
					ds.local_db_id										As local_db_id,
					ds.public_db_id										As public_db_id,
					ds.merged_db_id										As merged_db_id,

					c.first_name										As first_name,
					c.last_name											As last_name,
					dst.submission_type									As submission_type,
					ds.notes											As notes,

					ds.date_updated
					
			From clearing_house.view_datasets d
			Join clearing_house.view_dataset_submissions ds
			  On ds.dataset_id = d.merged_db_id
			 And ds.submission_id In (0, d.submission_id)
			Join clearing_house.view_contacts c
			  On c.merged_db_id = ds.contact_id
			 And c.submission_id In (0, d.submission_id)
			Join clearing_house.view_dataset_submission_types dst
			  On dst.merged_db_id = ds.submission_type_id
			 And dst.submission_id In (0, d.submission_id)
 
		) As LDB Left Join (
		
			Select	d.dataset_id										As dataset_id,
					
					ds.dataset_submission_id							As dataset_submission_id,

					c.first_name										As first_name,
					c.last_name											As last_name,
					dst.submission_type									As submission_type,
					ds.notes											As notes,

					ds.date_updated
					
			From public.tbl_datasets d
			Join public.tbl_dataset_submissions ds
			  On ds.dataset_id = d.dataset_id
			Join public.tbl_contacts c
			  On c.contact_id = ds.contact_id
			Join public.tbl_dataset_submission_types dst
			  On dst.submission_type_id = ds.submission_type_id
 
		  ) As RDB
		  On RDB.dataset_submission_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.dataset_id = -$2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_sample_alternative_names_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_sample_alternative_names_client_data(integer, integer) RETURNS TABLE(local_db_id integer, alt_ref character varying, alt_ref_type character varying, public_db_id integer, public_alt_ref character varying, public_alt_ref_type character varying, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$

Declare
    entity_type_id int;

Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_sample_alt_refs');

	Return Query

			Select 

				LDB.local_db_id		                    As local_db_id,
				
				LDB.alt_ref                      		As alt_ref, 
				LDB.alt_ref_type						As alt_ref_type,

				LDB.public_db_id                        As public_db_id,
				RDB.alt_ref                      		As public_alt_ref, 
				RDB.alt_ref_type 						As public_alt_ref_type,

				to_char(LDB.date_updated,'YYYY-MM-DD')	As date_updated,
				entity_type_id                 			As entity_type_id

			From (
				Select s.submission_id					As submission_id,
					   s.source_id						As source_id,
					   s.merged_db_id					As physical_sample_id,
					   a.local_db_id					As local_db_id,
					   a.public_db_id					As public_db_id,
					   a.merged_db_id					As merged_db_id,
                       a.alt_ref                        As alt_ref,
                       t.alt_ref_type                   As alt_ref_type,
                       a.date_updated					As date_updated
                From clearing_house.view_physical_samples s
                Join clearing_house.view_sample_alt_refs a
                  On a.physical_sample_id = s.merged_db_id
                 And a.submission_id in (0, s.submission_id)
                Join clearing_house.view_alt_ref_types t
                  On t.merged_db_id = a.alt_ref_type_id
                 And t.submission_id in (0, s.submission_id)
			) As LDB Left Join (
				Select a.alt_ref_type_id    			As alt_ref_type_id,
                       a.alt_ref                        As alt_ref,
                       t.alt_ref_type                   As alt_ref_type
                From public.tbl_sample_alt_refs a
                Join public.tbl_alt_ref_types t
                  On t.alt_ref_type_id = a.alt_ref_type_id
			) As RDB
			  On RDB.alt_ref_type_id = LDB.public_db_id
			Where LDB.source_id = 1
			  And LDB.submission_id = $1
			  And LDB.physical_sample_id = -$2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_sample_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_sample_client_data(integer, integer) RETURNS TABLE(local_db_id integer, date_sampled character varying, sample_name character varying, sample_name_type character varying, type_name character varying, public_db_id integer, public_date_sampled character varying, public_sample_name character varying, public_sample_name_type character varying, public_type_name character varying, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$

Declare
    entity_type_id int;

Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_physical_samples');

	Return Query

		With sample (submission_id, source_id, local_db_id, public_db_id, merged_db_id, date_sampled, sample_name, sample_name_type, sample_type) As (
            Select  s.submission_id         As submission_id,
                    s.source_id             As source_id,
                    s.local_db_id           As local_db_id,
                    s.public_db_id          As public_db_id,
                    s.merged_db_id          As merged_db_id,
                    s.date_sampled          As date_sampled,
                    s.sample_name           As sample_name,
                    r.alt_ref_type          As sample_type_type,
                    n.type_name             As sample_type
            From clearing_house.view_physical_samples s
            Left Join clearing_house.view_alt_ref_types r
              On r.merged_db_id = s.alt_ref_type_id
             And r.submission_id In (0, s.submission_id)
            Join clearing_house.view_sample_types n
              On n.merged_db_id = s.sample_type_id
             And n.submission_id In (0, s.submission_id)
		)
			Select 

				LDB.local_db_id						As local_db_id,
				LDB.date_sampled                    As date_sampled, 
				LDB.sample_name                     As sample_name,
				LDB.sample_name_type				As sample_name_type,
				LDB.sample_type                     As sample_type,

				LDB.public_db_id					As public_db_id,
				RDB.date_sampled                    As public_date_sampled, 
				RDB.sample_name                     As public_sample_name,
				RDB.sample_name_type				As public_sample_name_type,
				RDB.sample_type                     As public_sample_type,

                entity_type_id

			From sample LDB
			Left Join sample RDB
			  On RDB.source_id = 2
			 And RDB.public_db_id = LDB.public_db_id
			Where LDB.source_id = 1
			  And LDB.submission_id = $1
			  And LDB.local_db_id = -$2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_sample_colours_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_sample_colours_client_data(integer, integer) RETURNS TABLE(local_db_id integer, colour_name character varying, rgb integer, method_name character varying, public_db_id integer, public_colour_name character varying, public_rgb integer, public_method_name character varying, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$
Declare
    entity_type_id int;
Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_colours');

	Return Query

		Select 
			LDB.local_db_id				               	As local_db_id, /* Alt: Use colour_id instead */
			LDB.colour_name                             As colour_name, 
			LDB.rgb                                     As rgb, 
			LDB.method_name                       		As method_name, 

			LDB.public_db_id				            As public_db_id,
			RDB.colour_name                             As public_colour_name, 
			RDB.rgb                                     As public_rgb, 
			RDB.method_name                       		As public_method_name, 

			to_char(LDB.date_updated,'YYYY-MM-DD')		As date_updated,
			entity_type_id								As entity_type_id

		From (
			Select	s.source_id                         As source_id,
					s.submission_id                     As submission_id,
					s.local_db_id						As physical_sample_id,
					sc.local_db_id						As local_db_id,
					sc.public_db_id						As public_db_id,
					sc.merged_db_id						As merged_db_id,
                    --c.merged_db_id                    As colour_id, /* alternative review entity */
                    c.colour_name                       As colour_name,
                    c.rgb                               As rgb,
                    m.method_name                       As method_name,
                    sc.date_updated                     As date_updated
            From clearing_house.view_physical_samples s
            Join clearing_house.view_sample_colours sc
              On sc.physical_sample_id = s.merged_db_id
             And sc.submission_id in (0, s.submission_id)
            Join clearing_house.view_colours c
              On c.merged_db_id = sc.colour_id
             And c.submission_id in (0, s.submission_id)
            Join clearing_house.view_methods m
              On m.merged_db_id = c.method_id
             And m.submission_id in (0, s.submission_id)
		) As LDB Left Join (
            Select	sc.sample_colour_id					As sample_colour_id,
                    c.colour_id                         As colour_id, /* alternative review entity */
                    c.colour_name                       As colour_name,
                    c.rgb                               As rgb,
                    m.method_name                       As method_name
            From public.tbl_sample_colours sc
            Join public.tbl_colours c
              On c.colour_id = sc.colour_id
            Join public.tbl_methods m
              On m.method_id = c.method_id
		) As RDB
		  On RDB.sample_colour_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.physical_sample_id = -$2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_sample_descriptions_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_sample_descriptions_client_data(integer, integer) RETURNS TABLE(local_db_id integer, type_name character varying, type_description text, public_db_id integer, public_type_name character varying, public_type_description text, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$
Declare
    entity_type_id int;
Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_sample_descriptions');

	Return Query

		Select 
			LDB.local_db_id				               					As local_db_id,

			LDB.type_name                         						As type_name, 
			LDB.type_description                       					As type_description, 

			LDB.public_db_id				            				As public_db_id,

			RDB.type_name                         						As public_type_name, 
			RDB.type_description                       					As public_type_description, 

			to_char(LDB.date_updated,'YYYY-MM-DD')						As date_updated,
			entity_type_id												As entity_type_id

		From (
			Select	s.source_id                                         As source_id,
					s.submission_id                                     As submission_id,
					s.local_db_id										As physical_sample_id,
					sd.local_db_id										As local_db_id,
					sd.public_db_id										As public_db_id,
					sd.merged_db_id										As merged_db_id,
                    sd.description                                      As description,
                    t.type_name                                         As type_name,
                    t.type_description                                  As type_description,
                    sd.date_updated                                     As date_updated
            From clearing_house.view_physical_samples s
            Join clearing_house.view_sample_descriptions sd
              On sd.sample_description_id = s.merged_db_id
             And sd.submission_id in (0, s.submission_id)
            Join clearing_house.view_sample_description_types t
              On t.merged_db_id = sd.sample_description_type_id
             And t.submission_id in (0, s.submission_id)
		) As LDB Left Join (
			Select	sd.sample_description_id							As sample_description_id,
                    sd.description                                      As description,
                    t.type_name                                         As type_name,
                    t.type_description                                  As type_description
            From public.tbl_sample_descriptions sd
            Join public.tbl_sample_description_types t
              On t.sample_description_type_id = sd.sample_description_type_id
		  ) As RDB
		  On RDB.sample_description_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.physical_sample_id = -$2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_sample_dimensions_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_sample_dimensions_client_data(integer, integer) RETURNS TABLE(local_db_id integer, dimension_value numeric, dimension_name character varying, method_name character varying, public_db_id integer, public_dimension_value numeric, public_dimension_name character varying, public_method_name character varying, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$
Declare
    entity_type_id int;
Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_sample_dimensions');

	Return Query

		Select 
			LDB.local_db_id				               					As local_db_id,
			LDB.dimension_value                         				As dimension_value, 
			LDB.dimension_name                         					As dimension_name, 
			LDB.method_name                         					As method_name, 
			LDB.public_db_id				            				As public_db_id,
			RDB.dimension_value                         				As public_dimension_value, 
			RDB.dimension_name                         					As public_dimension_name, 
			RDB.method_name                         					As public_method_name, 
			to_char(LDB.date_updated,'YYYY-MM-DD')						As date_updated,
			entity_type_id												As entity_type_id
		From (
			Select	s.source_id                                         As source_id,
					s.submission_id                                     As submission_id,
					s.local_db_id										As physical_sample_id,
					sd.local_db_id 										As local_db_id,
					sd.public_db_id 									As public_db_id,
					sd.merged_db_id 									As merged_db_id,
                    sd.dimension_value                                  As dimension_value,
                    Coalesce(t.dimension_abbrev, t.dimension_name, '')  As dimension_name,
                    m.method_name                                       As method_name,
                    sd.date_updated                                     As date_updated
            From clearing_house.view_physical_samples s
            Join clearing_house.view_sample_dimensions sd
              On sd.physical_sample_id = s.merged_db_id
             And sd.submission_id in (0, s.submission_id)
            Join clearing_house.view_dimensions t
              On t.merged_db_id = sd.dimension_id
             And t.submission_id in (0, s.submission_id)
            Join clearing_house.view_methods m
              On m.merged_db_id = sd.method_id
             And m.submission_id in (0, s.submission_id)
		) As LDB Left Join (
			Select	sd.sample_dimension_id 								As sample_dimension_id,
                    sd.dimension_value                                  As dimension_value,
                    Coalesce(t.dimension_abbrev, t.dimension_name, '')  As dimension_name,
                    m.method_name                                       As method_name
            From public.tbl_sample_dimensions sd
            Join public.tbl_dimensions t
              On t.dimension_id = sd.dimension_id
            Join public.tbl_methods m
              On m.method_id = sd.method_id
		  ) As RDB
		  On RDB.sample_dimension_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.physical_sample_id = -$2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_sample_features_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_sample_features_client_data(integer, integer) RETURNS TABLE(local_db_id integer, feature_name character varying, feature_description text, feature_type_name character varying, public_db_id integer, public_feature_name character varying, public_feature_description text, public_feature_type_name character varying, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$
Declare
    sample_group_references_entity_type_id int;
Begin

    sample_group_references_entity_type_id := clearing_house.fn_get_entity_type_for('tbl_physical_sample_features');

	Return Query

		Select 
			LDB.local_db_id                             As local_db_id,
			LDB.feature_name                            As feature_name, 
			LDB.feature_description                     As feature_description,
			LDB.feature_type_name                       As feature_type_name,
			LDB.public_db_id                            As public_db_id,
			RDB.feature_name                            As public_feature_name, 
			RDB.feature_description                     As public_feature_description,
			RDB.feature_type_name                       As public_feature_type_name,
			to_char(LDB.date_updated,'YYYY-MM-DD')		As date_updated,
			sample_group_references_entity_type_id		As entity_type_id
		From (
			Select	s.source_id                         As source_id,
					s.submission_id                     As submission_id,
					s.merged_db_id                      As physical_sample_id,
					fs.local_db_id						As local_db_id,
					fs.public_db_id						As public_db_id,
                    fs.merged_db_id						As merged_db_id,
                    f.feature_name						As feature_name,
                    f.feature_description				As feature_description,
                    t.feature_type_name					As feature_type_name,
                    fs.date_updated                     As date_updated
            From clearing_house.view_physical_samples s
            Join clearing_house.view_physical_sample_features fs
              On fs.physical_sample_id = s.merged_db_id
             And fs.submission_id in (0, s.submission_id)
            Join clearing_house.view_features f
              On f.merged_db_id = fs.feature_id
             And f.submission_id in (0, s.submission_id)
            Join clearing_house.view_feature_types t
              On t.merged_db_id = f.feature_type_id
             And t.submission_id in (0, s.submission_id)
		) As LDB Left Join (
			Select	fs.feature_id						As feature_id,
                    f.feature_name						As feature_name,
                    f.feature_description				As feature_description,
                    t.feature_type_name					As feature_type_name
            From public.tbl_physical_sample_features fs
            Join public.tbl_features f
              On f.feature_id = fs.feature_id
            Join public.tbl_feature_types t
              On t.feature_type_id = f.feature_type_id
		) As RDB
		  On RDB.feature_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.physical_sample_id = -$2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_sample_group_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_sample_group_client_data(integer, integer) RETURNS TABLE(local_db_id integer, sample_group_name character varying, sampling_method character varying, sampling_context character varying, public_db_id integer, public_sample_group_name character varying, public_sampling_method character varying, public_sampling_context character varying, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$

Declare
    entity_type_id int;

Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_sample_groups');

	Return Query

		With sample_group (submission_id, source_id, local_db_id, public_db_id, merged_db_id, sample_group_name, sampling_method, sampling_context) As (
            Select sg.submission_id                 As submission_id,
                   sg.source_id                     As source_id,
                   sg.local_db_id                   As local_db_id,
                   sg.public_db_id                  As public_db_id,
                   sg.merged_db_id                  As merged_db_id,
                   sg.sample_group_name             As sample_group_name,
                   m.method_name                    As sampling_method,
                   c.sampling_context				As sampling_context
            From clearing_house.view_sample_groups sg
            Join clearing_house.view_methods m
              On m.merged_db_id = sg.method_id
             And m.submission_id in (0, sg.submission_id)
            Join clearing_house.view_sample_group_sampling_contexts c
              On c.merged_db_id = sg.sampling_context_id
             And c.submission_id in (0, sg.submission_id)
		)
			Select 

				LDB.local_db_id						As local_db_id,
				
				LDB.sample_group_name				As sample_group_name, 
				LDB.sampling_method					As sampling_method,
				LDB.sampling_context				As sampling_context,

				LDB.public_db_id					As public_db_id,

				RDB.sample_group_name				As public_sample_group_name, 
				RDB.sampling_method					As public_sampling_method,
				RDB.sampling_context				As public_sampling_context,

                entity_type_id

			From sample_group LDB
			Left Join sample_group RDB
			  On RDB.source_id = 2
			 And RDB.public_db_id = LDB.public_db_id
			Where LDB.source_id = 1
			  And LDB.submission_id = $1
			  And LDB.local_db_id = -$2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_sample_group_descriptions_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_sample_group_descriptions_client_data(integer, integer) RETURNS TABLE(local_db_id integer, group_description character varying, type_name character varying, type_description character varying, public_db_id integer, public_group_description character varying, public_type_name character varying, public_type_description character varying, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$
Declare
    entity_type_id int;
Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_sample_group_descriptions');

	Return Query

		Select 
			LDB.local_db_id				               					As local_db_id,
			LDB.group_description                       				As group_description, 
			LDB.type_name                         						As type_name, 
			LDB.type_description                       					As type_description, 
			LDB.public_db_id				            				As public_db_id,
			RDB.group_description                      					As public_group_description, 
			RDB.type_name                         						As public_type_name, 
			RDB.type_description                       					As public_type_description, 
			entity_type_id												As entity_type_id
		From (
			Select	sg.source_id										As source_id,
					sg.submission_id									As submission_id,
					sg.local_db_id										As sample_group_id,
					d.local_db_id										As local_db_id,
					d.public_db_id										As public_db_id,
					d.merged_db_id										As merged_db_id,
					d.group_description									As group_description,
					t.type_name											As type_name,
					t.type_description									As type_description
			From clearing_house.view_sample_groups sg
			Join clearing_house.view_sample_group_descriptions d
			  On d.sample_group_description_id = sg.merged_db_id
			 And d.submission_id in (0, sg.submission_id)
			Join clearing_house.view_sample_group_description_types t
			  On t.merged_db_id = d.sample_group_description_type_id
			 And t.submission_id in (0, sg.submission_id)
		) As LDB Left Join (
			Select	d.sample_group_description_id						As sample_group_description_id,
					d.group_description									As group_description,
					t.type_name											As type_name,
					t.type_description									As type_description
			From public.tbl_sample_groups sg
			Join public.tbl_sample_group_descriptions d
			  On d.sample_group_id = sg.sample_group_id
			Join public.tbl_sample_group_description_types t
			  On t.sample_group_description_type_id = d.sample_group_description_type_id
		  ) As RDB
		  On RDB.sample_group_description_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.sample_group_id = -$2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_sample_group_dimensions_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_sample_group_dimensions_client_data(integer, integer) RETURNS TABLE(local_db_id integer, dimension_value numeric, dimension_name character varying, public_db_id integer, public_dimension_value numeric, public_dimension_name character varying, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$
Declare
    entity_type_id int;
Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_sample_group_dimensions');

	Return Query

		Select 
			LDB.local_db_id				               					As local_db_id,
			LDB.dimension_value                         				As dimension_value, 
			LDB.dimension_name                         					As dimension_name, 
			LDB.public_db_id				            				As public_db_id,
			RDB.dimension_value                         				As public_dimension_value, 
			RDB.dimension_name                         					As public_dimension_name, 
			to_char(LDB.date_updated,'YYYY-MM-DD')						As date_updated,
			entity_type_id												As entity_type_id
		From (
			Select	sg.source_id										As source_id,
					sg.submission_id									As submission_id,
					sg.local_db_id										As sample_group_id,
					d.local_db_id 										As local_db_id,
					d.public_db_id 										As public_db_id,
					d.merged_db_id 										As merged_db_id,
					d.dimension_value									As dimension_value,
					Coalesce(t.dimension_abbrev, t.dimension_name, '')	As dimension_name,
					d.date_updated										As date_updated
			From clearing_house.view_sample_groups sg
			Join clearing_house.view_sample_group_dimensions d
			  On d.sample_group_id = sg.merged_db_id
			 And d.submission_id in (0, sg.submission_id)
			Join clearing_house.view_dimensions t
			  On t.merged_db_id = d.dimension_id
			 And d.submission_id in (0, sg.submission_id)
		) As LDB Left Join (
			Select	d.sample_group_dimension_id 						As sample_group_dimension_id,
					d.dimension_value									As dimension_value,
					Coalesce(t.dimension_abbrev, t.dimension_name, '')	As dimension_name
			From public.tbl_sample_group_dimensions d
			Join public.tbl_dimensions t
			  On t.dimension_id = d.dimension_id
		  ) As RDB
		  On RDB.sample_group_dimension_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.sample_group_id = -$2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_sample_group_lithology_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_sample_group_lithology_client_data(integer, integer) RETURNS TABLE(local_db_id integer, depth_top numeric, depth_bottom numeric, description text, lower_boundary character varying, public_db_id integer, public_depth_top numeric, public_depth_bottom numeric, public_description text, public_lower_boundary character varying, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$

Declare
    entity_type_id int;

Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_site_locations');

	Return Query

			Select 

				LDB.local_db_id		                    As local_db_id,
				
				LDB.depth_top                      		As depth_top, 
				LDB.depth_bottom						As depth_bottom,
				LDB.description                  		As description,
				LDB.lower_boundary                 		As lower_boundary,

				LDB.public_db_id                        As public_db_id,
				RDB.depth_top                      		As public_depth_top, 
				RDB.depth_bottom						As public_depth_bottom,
				RDB.description                  		As public_description,
				RDB.lower_boundary                 		As public_lower_boundary,

				entity_type_id              			As entity_type_id

			From (
				Select sg.submission_id					As submission_id,
					   sg.source_id						As source_id,
					   sg.merged_db_id					As sample_group_id,
					   l.local_db_id					As local_db_id,
					   l.public_db_id					As public_db_id,
					   l.merged_db_id					As lithology_id,
					   l.depth_top						As depth_top,
					   l.depth_bottom					As depth_bottom,
					   l.description					As description,
					   l.lower_boundary					As lower_boundary
				From clearing_house.view_sample_groups sg
				Join clearing_house.view_lithology l
				  On l.sample_group_id = sg.merged_db_id
				 And l.submission_id in (0, sg.submission_id)
			) As LDB Left Join (
				Select sg.sample_group_id				As sample_group_id,
					   l.lithology_id					As lithology_id,
					   l.depth_top						As depth_top,
					   l.depth_bottom					As depth_bottom,
					   l.description					As description,
					   l.lower_boundary					As lower_boundary
				From public.tbl_sample_groups sg
				Join public.tbl_lithology l
				  On l.sample_group_id = sg.sample_group_id
			) As RDB
			  On RDB.lithology_id = LDB.public_db_id
			Where LDB.source_id = 1
			  And LDB.submission_id = $1
			  And LDB.sample_group_id = -$2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_sample_group_notes_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_sample_group_notes_client_data(integer, integer) RETURNS TABLE(local_db_id integer, note character varying, public_db_id integer, public_note character varying, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$
Declare
    entity_type_id int;
Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_sample_group_notes');

	Return Query

		Select 
			LDB.local_db_id					            As local_db_id,
			LDB.note                              		As note, 
			LDB.public_db_id                            As public_db_id,
			RDB.note                               		As public_note, 
			to_char(LDB.date_updated,'YYYY-MM-DD')		As date_updated,
			entity_type_id                  			As entity_type_id
		From (
			Select	sg.source_id						As source_id,
					sg.submission_id					As submission_id,
					sg.local_db_id						As sample_group_id,
					n.local_db_id						As local_db_id, 
					n.public_db_id						As public_db_id, 
					n.merged_db_id						As merged_db_id, 
					n.note								As note,
					n.date_updated						As date_updated
			From clearing_house.view_sample_groups sg
			Join clearing_house.view_sample_group_notes n
			  On n.sample_group_id = sg.merged_db_id
			 And n.submission_id in (0, sg.submission_id)
		) As LDB Left Join (
			Select	n.sample_group_note_id				As sample_group_note_id, 
					n.note								As note
			From public.tbl_sample_group_notes n
		) As RDB
		  On RDB.sample_group_note_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.sample_group_id = -$2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_sample_group_positions_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_sample_group_positions_client_data(integer, integer) RETURNS TABLE(local_db_id integer, sample_group_position numeric, position_accuracy character varying, method_name character varying, dimension_name character varying, public_db_id integer, public_sample_group_position numeric, public_position_accuracy character varying, public_method_name character varying, public_dimension_name character varying, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$
Declare
    entity_type_id int;
Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_sample_group_coordinates');

	Return Query

		Select 
			LDB.local_db_id				               	As local_db_id,
			LDB.sample_group_position                   As sample_group_position, 
			LDB.position_accuracy                       As position_accuracy, 
			LDB.method_name                       		As method_name, 
			LDB.dimension_name                       	As dimension_name, 
			LDB.public_db_id				            As public_db_id,
			RDB.sample_group_position                   As public_sample_group_position, 
			RDB.position_accuracy                       As public_position_accuracy, 
			RDB.method_name                       		As public_method_name, 
			RDB.dimension_name                       	As public_dimension_name, 
			entity_type_id								As entity_type_id
		From (
			Select	sg.source_id						As source_id,
					sg.submission_id					As submission_id,
					sg.local_db_id						As sample_group_id,
					d.local_db_id						As local_db_id,
					d.public_db_id						As public_db_id,
					d.merged_db_id						As merged_db_id,
					c.sample_group_position				As sample_group_position,
					c.position_accuracy					As position_accuracy,
					m.method_name						As method_name,
					d.dimension_name					As dimension_name
			From clearing_house.view_sample_groups sg
			Join clearing_house.view_sample_group_coordinates c
			  On c.sample_group_id = sg.merged_db_id
			 And c.submission_id In (0, sg.submission_id)
			Join clearing_house.view_coordinate_method_dimensions md
			  On md.merged_db_id = c.coordinate_method_dimension_id
			 And md.submission_id In (0, sg.submission_id)
			Join clearing_house.view_methods m
			  On m.merged_db_id = md.method_id
			 And m.submission_id In (0, sg.submission_id)
			Join clearing_house.view_dimensions d
			  On d.merged_db_id = md.dimension_id
			 And d.submission_id In (0, sg.submission_id)
			Where 1 = 1
		) As LDB Left Join (
			Select	c.sample_group_position_id			As sample_group_position_id,
					c.sample_group_position				As sample_group_position,
					c.position_accuracy					As position_accuracy,
					m.method_name						As method_name,
					d.dimension_name					As dimension_name
			From public.tbl_sample_group_coordinates c
			Join public.tbl_coordinate_method_dimensions md
			  On md.coordinate_method_dimension_id = c.coordinate_method_dimension_id
			Join public.tbl_methods m
			  On m.method_id = md.method_id
			Join public.tbl_dimensions d
			  On d.dimension_id = md.dimension_id
		) As RDB
		  On RDB.sample_group_position_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.sample_group_id = -$2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_sample_group_references_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_sample_group_references_client_data(integer, integer) RETURNS TABLE(local_db_id integer, reference text, public_db_id integer, public_reference text, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$
Declare
    entity_type_id int;
Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_sample_group_references');

	Return Query

		Select 
			LDB.sample_group_reference_id               As local_db_id,
			LDB.reference                               As reference, 
			LDB.public_db_id                            As public_db_id,
			RDB.reference                               As public_reference, 
			to_char(LDB.date_updated,'YYYY-MM-DD')		As date_updated,
			entity_type_id                      		As entity_type_id
		From (
			Select	sg.source_id						As source_id,
					sg.submission_id					As submission_id,
					sg.local_db_id						As sample_group_id,
					sr.local_db_id						As sample_group_reference_id,
					b.local_db_id						As local_db_id, 
					b.public_db_id						As public_db_id, 
					b.merged_db_id						As merged_db_id, 
					b.author || ' (' || b.year || ')'	As reference,
					sr.date_updated						As date_updated
			From clearing_house.view_sample_groups sg
			Join clearing_house.view_sample_group_references sr
			  On sr.sample_group_id = sg.merged_db_id
			 And sr.submission_id In (0, sg.submission_id)
			Join clearing_house.view_biblio b
			  On b.merged_db_id = sr.biblio_id
			 And b.submission_id In (0, sg.submission_id)
		) As LDB Left Join (
			Select	b.biblio_id							As biblio_id,
					b.author || ' (' || b.year || ')'	As reference
			From public.tbl_biblio b
		) As RDB
		  On RDB.biblio_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.sample_group_id = -$2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_sample_horizons_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_sample_horizons_client_data(integer, integer) RETURNS TABLE(local_db_id integer, horizon_name character varying, description text, method_name character varying, public_db_id integer, public_horizon_name character varying, public_description text, public_method_name character varying, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$
Declare
    entity_type_id int;
Begin
    -- Entity in focus should perhaps be tbl_samples instead. In such case return ids from h (and join LDB & RDB on horizon id)
    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_sample_horizons');

	Return Query

		Select 
			LDB.local_db_id				               	As local_db_id, --> use horizon_id instead?
			LDB.horizon_name                            As horizon_name, 
			LDB.description                             As description, 
			LDB.method_name                       		As method_name, 
			LDB.public_db_id				            As public_db_id,
			RDB.horizon_name                            As public_horizon_name, 
			RDB.description                             As public_description, 
			RDB.method_name                       		As public_method_name, 
			to_char(LDB.date_updated,'YYYY-MM-DD')		As date_updated,
			entity_type_id								As entity_type_id
		From (
			Select	s.source_id                         As source_id,
					s.submission_id                     As submission_id,
					s.local_db_id						As physical_sample_id,
					sh.local_db_id						As local_db_id,
					sh.public_db_id						As public_db_id,
					sh.merged_db_id						As merged_db_id,
                    --h.merged_db_id                    As horizon_id,/* alternative review entity */
                    h.horizon_name                      As horizon_name,
                    h.description                       As description,
                    m.method_name                       As method_name,
                    sh.date_updated                     As date_updated
            From clearing_house.view_physical_samples s
            Join clearing_house.view_sample_horizons sh
              On sh.physical_sample_id = s.merged_db_id
             And sh.submission_id in (0, s.submission_id)
            Join clearing_house.view_horizons h
              On h.merged_db_id = sh.horizon_id
             And h.submission_id in (0, s.submission_id)
            Join clearing_house.view_methods m
              On m.merged_db_id = h.method_id
             And m.submission_id in (0, s.submission_id)
			Where 1 = 1
		) As LDB Left Join (
            Select	sh.sample_horizon_id				As sample_horizon_id,
                    h.horizon_name                      As horizon_name,
                    h.description                       As description,
                    m.method_name                       As method_name
            From public.tbl_sample_horizons sh
            Join public.tbl_horizons h
              On h.horizon_id = sh.horizon_id
            Join public.tbl_methods m
              On m.method_id = h.method_id
		) As RDB
		  On RDB.sample_horizon_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.physical_sample_id = -$2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_sample_images_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_sample_images_client_data(integer, integer) RETURNS TABLE(local_db_id integer, image_name character varying, description text, image_type character varying, public_db_id integer, public_image_name character varying, public_description text, public_image_type character varying, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$
Declare
    entity_type_id int;
Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_sample_images');

	Return Query

		Select 
			LDB.local_db_id				               	As local_db_id,

			LDB.image_name                              As image_name, 
			LDB.description                             As description, 
			LDB.image_type                       		As image_type, 

			LDB.public_db_id				            As public_db_id,

			RDB.image_name                              As public_image_name, 
			RDB.description                             As public_description, 
			RDB.image_type                       		As public_image_type, 

			to_char(LDB.date_updated,'YYYY-MM-DD')		As date_updated,
			entity_type_id								As entity_type_id

		From (
			Select	s.source_id                         As source_id,
					s.submission_id                     As submission_id,
					s.local_db_id						As physical_sample_id,
					si.local_db_id						As local_db_id,
					si.public_db_id						As public_db_id,
					si.merged_db_id						As merged_db_id,
                    si.image_name                       As image_name,
                    si.description                      As description,
                    it.image_type                       As image_type,
                    si.date_updated                     As date_updated
            From clearing_house.view_physical_samples s
            Join clearing_house.view_sample_images si
              On si.physical_sample_id = s.merged_db_id
             And si.submission_id in (0, s.submission_id)
            Join clearing_house.view_image_types it
              On it.merged_db_id = si.image_type_id
             And it.submission_id in (0, s.submission_id)
		) As LDB Left Join (
			Select	si.sample_image_id					As sample_image_id,
                    si.image_name                       As image_name,
                    si.description                      As description,
                    it.image_type                       As image_type
            From public.tbl_sample_images si
            Join public.tbl_image_types it
              On it.image_type_id = si.image_type_id
		) As RDB
		  On RDB.sample_image_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.physical_sample_id = -$2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_sample_locations_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_sample_locations_client_data(integer, integer) RETURNS TABLE(local_db_id integer, location character varying, location_type character varying, description text, public_db_id integer, public_location character varying, public_location_type character varying, public_description text, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$

Declare
    entity_type_id int;

Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_sample_locations');

	Return Query

			Select 

				LDB.local_db_id                   		As local_db_id,
				
				LDB.location                            As location, 
				LDB.location_type                       As location_type,
				LDB.description                         As description,

				LDB.public_db_id                        As public_db_id,

				RDB.location                            As public_location, 
				RDB.location_type                       As public_location_type,
				RDB.description                         As public_description,

				to_char(LDB.date_updated,'YYYY-MM-DD')	As date_updated,
				entity_type_id              			As entity_type_id

			From (
                Select	s.source_id                         As source_id,
                        s.submission_id                     As submission_id,
                        s.local_db_id						As physical_sample_id,
                        sl.local_db_id						As local_db_id,
                        sl.public_db_id						As public_db_id,
                        sl.merged_db_id						As merged_db_id,
                        sl.location                         As location,
                        t.location_type                     As location_type,
                        t.location_type_description         As description,
                        sl.date_updated						As date_updated
                From clearing_house.view_physical_samples s
                Join clearing_house.view_sample_locations sl
                  On sl.physical_sample_id = s.merged_db_id
                 And sl.submission_id in (0, s.submission_id)
                Join clearing_house.view_sample_location_types t
                  On t.merged_db_id = sl.sample_location_type_id
                 And t.submission_id in (0, s.submission_id)
			) As LDB Left Join (
                Select	sl.sample_location_id				As sample_location_id,
                        sl.location                         As location,
                        t.location_type                     As location_type,
                        t.location_type_description         As description
                From public.tbl_sample_locations sl
                Join public.tbl_sample_location_types t
                  On t.sample_location_type_id = sl.sample_location_type_id
			) As RDB
			  On RDB.sample_location_id = LDB.public_db_id
			Where LDB.source_id = 1
			  And LDB.submission_id = $1
			  And LDB.physical_sample_id = -$2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_sample_notes_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_sample_notes_client_data(integer, integer) RETURNS TABLE(local_db_id integer, note text, note_type character varying, public_db_id integer, public_note text, public_note_type character varying, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$
Declare
    entity_type_id int;
Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_sample_notes');

	Return Query

		Select 
			LDB.local_db_id					            As local_db_id,
			LDB.note                              		As note, 
			LDB.note_type                          		As note_type, 
			LDB.public_db_id                            As public_db_id,
			RDB.note                               		As public_note, 
			RDB.note_type                          		As note_type, 
			to_char(LDB.date_updated,'YYYY-MM-DD')		As date_updated,
			entity_type_id                              As entity_type_id
		From (
			Select	s.source_id                         As source_id,
					s.submission_id                     As submission_id,
					s.local_db_id						As physical_sample_id,
					n.local_db_id						As local_db_id, 
					n.public_db_id						As public_db_id, 
					n.merged_db_id						As merged_db_id, 
					n.note								As note,
					n.note_type							As note_type,
					n.date_updated						As date_updated
			From clearing_house.view_physical_samples s
			Join clearing_house.view_sample_notes n
			  On n.physical_sample_id = s.merged_db_id
			 And n.submission_id in (0, s.submission_id)
		) As LDB Left Join (
			Select	n.sample_note_id                    As sample_note_id, 
					n.note								As note,
					n.note_type							As note_type
			From public.tbl_sample_notes n
		) As RDB
		  On RDB.sample_note_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.physical_sample_id = -$2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_site_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_site_client_data(integer, integer) RETURNS TABLE(local_db_id integer, latitude_dd numeric, longitude_dd numeric, altitude numeric, national_site_identifier character varying, site_name character varying, site_description text, preservation_status_or_threat character varying, public_db_id integer, public_latitude_dd numeric, public_longitude_dd numeric, public_altitude numeric, public_national_site_identifier character varying, public_site_name character varying, public_site_description text, public_preservation_status_or_threat character varying, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$

Declare
    site_entity_type_id int;

Begin

    site_entity_type_id := clearing_house.fn_get_entity_type_for('tbl_sites');

	Return Query
		With site_data (submission_id, source_id, site_id, local_db_id, public_db_id, latitude_dd, longitude_dd, altitude, national_site_identifier, site_name, site_description, preservation_status_or_threat) As (
			Select  s.submission_id,
					s.source_id,
					s.site_id,
					s.local_db_id,
					s.public_db_id,
					s.latitude_dd, 
					s.longitude_dd,
					s.altitude,
					s.national_site_identifier,
					s.site_name,
					s.site_description,
					t.preservation_status_or_threat
			From clearing_house.view_sites s
			Left Join clearing_house.view_site_preservation_status t
			  On t.merged_db_id = s.site_preservation_status_id
		)
			Select 

				LDB.local_db_id						As local_db_id,
				
				LDB.latitude_dd						As latitude_dd, 
				LDB.longitude_dd					As longitude_dd,
				LDB.altitude						As altitude,
				LDB.national_site_identifier		As national_site_identifier,
				LDB.site_name						As site_name,
				LDB.site_description				As site_description,
				LDB.preservation_status_or_threat	As preservation_status_or_threat,

				LDB.public_db_id					As public_db_id,
				RDB.latitude_dd						As public_latitude_dd, 
				RDB.longitude_dd					As public_longitude_dd, 
				RDB.altitude						As public_altitude, 
				RDB.national_site_identifier		As public_national_site_identifier, 
				RDB.site_name						As public_site_name, 
				RDB.site_description				As public_site_description,
				RDB.preservation_status_or_threat	As public_preservation_status_or_threat,

                site_entity_type_id


			From site_data LDB
			Left Join site_data RDB
			  On RDB.source_id = 2
			 And RDB.site_id = LDB.public_db_id
			Where LDB.source_id = 1
			  And LDB.submission_id = $1
			  And LDB.site_id = $2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_site_locations_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_site_locations_client_data(integer, integer) RETURNS TABLE(local_db_id integer, location_name character varying, location_type character varying, default_lat_dd numeric, default_long_dd numeric, public_db_id integer, public_location_name character varying, public_location_type character varying, public_default_lat_dd numeric, public_default_long_dd numeric, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$

Declare
    entity_type_id int;

Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_site_locations');

	Return Query

			Select 

				LDB.site_location_id                    As local_db_id,
				
				LDB.location_name                       As location_name, 
				LDB.location_type                       As location_type,
				LDB.default_lat_dd                  	As default_lat_dd,
				LDB.default_long_dd                 	As default_long_dd,

				LDB.public_db_id                        As public_db_id,

				RDB.location_name                   	As public_location_name, 
				RDB.location_type               		As public_location_type,
				RDB.default_lat_dd              		As public_default_lat_dd,
				RDB.default_long_dd                     As public_default_long_dd,

				to_char(LDB.date_updated,'YYYY-MM-DD')	As date_updated,

				entity_type_id			As entity_type_id

			From (
				Select s.submission_id, sl.site_location_id, s.source_id, s.site_id, l.location_id, l.local_db_id, l.public_db_id, l.location_name, l.date_updated, t.location_type, l.default_lat_dd, l.default_long_dd
				From clearing_house.view_sites s
				Left Join clearing_house.view_site_locations sl
				  On sl.site_id = s.merged_db_id
				 And sl.submission_id In (0, $1)
				Left Join clearing_house.view_locations l
				  On l.merged_db_id = sl.location_id
				 And sl.submission_id In (0, $1)
				Join clearing_house.view_location_types t
				  On t.merged_db_id = l.location_type_id
				 And t.submission_id In (0, $1)
				Where 1 = 1
			) As LDB Left Join (
				Select l.location_id, l.location_name, l.date_updated, t.location_type, l.default_lat_dd, l.default_long_dd
				From public.tbl_locations l
				Join public.tbl_location_types t
				  On t.location_type_id = l.location_type_id
				Where 1 = 1
			) As RDB
			  On RDB.location_id = LDB.public_db_id
			Where LDB.source_id = 1
			  And LDB.submission_id = $1
			  And LDB.site_id = $2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_site_natgridrefs_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_site_natgridrefs_client_data(integer, integer) RETURNS TABLE(local_db_id integer, method_name character varying, natgridref character varying, public_db_id integer, public_method_name character varying, public_natgridref character varying, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$

Declare
    entity_type_id int;

Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_site_natgridrefs');

	Return Query

		Select 
			LDB.site_natgridref_id			As local_db_id,
			LDB.method_name					As method_name, 
			LDB.natgridref					As natgridref, 
			LDB.public_db_id				As public_db_id,
			RDB.method_name					As public_method_name, 
			RDB.natgridref					As public_natgridref,
			entity_type_id          		As entity_type_id
		From (
			Select s.source_id, sg.site_natgridref_id, s.submission_id, s.site_id, sg.site_natgridref_id as local_db_id, sg.public_db_id, m.method_name, sg.natgridref
			From clearing_house.view_sites s
			Join clearing_house.view_site_natgridrefs sg
			  On sg.site_id = s.merged_db_id
			 And sg.submission_id In (0, $1)
			Join clearing_house.view_methods m
			  On m.merged_db_id = sg.method_id
			 And m.submission_id In (0, $1)
			Where 1 = 1
		) As LDB Left Join (
			Select sg.site_natgridref_id, m.method_name, sg.natgridref
			From public.tbl_site_natgridrefs sg
			Join public.tbl_methods m
			  On m.method_id = sg.method_id
			Where 1 = 1
		) As RDB
		  On RDB.site_natgridref_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.site_id = $2;
		  
End $_$;


--
-- Name: fn_clearinghouse_review_site_references_client_data(integer, integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_clearinghouse_review_site_references_client_data(integer, integer) RETURNS TABLE(local_db_id integer, reference text, public_db_id integer, public_reference text, date_updated text, entity_type_id integer)
    LANGUAGE plpgsql
    AS $_$

Declare
    entity_type_id int;

Begin

    entity_type_id := clearing_house.fn_get_entity_type_for('tbl_site_references');

	Return Query

		Select 
			LDB.site_reference_id                       As local_db_id,
			LDB.reference                               As reference, 
			LDB.public_db_id                            As public_db_id,
			RDB.reference                               As public_reference, 
			to_char(LDB.date_updated,'YYYY-MM-DD')		As date_updated,
			entity_type_id              				As entity_type_id
		From (
			Select s.source_id, s.submission_id, sr.site_reference_id, s.site_id, b.biblio_id as local_db_id, b.public_db_id, b.author || ' (' || b.year || ')' as reference, b.date_updated
			From clearing_house.view_sites s
			Join clearing_house.view_site_references sr
			  On sr.site_id = s.merged_db_id
			 And sr.submission_id In (0, $1)
			Join clearing_house.view_biblio b
			  On b.merged_db_id = sr.biblio_id
			 And b.submission_id In (0, $1)
		) As LDB Left Join (
			Select b.biblio_id, b.author || ' (' || b.year || ')' as reference
			From public.tbl_biblio b
		) As RDB
		  On RDB.biblio_id = LDB.public_db_id
		Where LDB.source_id = 1
		  And LDB.submission_id = $1
		  And LDB.site_id = $2;
		  
End $_$;


--
-- Name: fn_copy_extracted_values_to_entity_table(integer, character varying); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_copy_extracted_values_to_entity_table(integer, character varying) RETURNS text
    LANGUAGE plpgsql
    AS $_$

	Declare schema_columns character varying(255)[];
	Declare submission_columns character varying(255)[];
	Declare submission_column_types character varying(255)[];
	
	Declare insert_columns_string text;
	Declare select_columns_string text;
	Declare public_columns_string text;
	Declare public_key_columns_string text;
	
	Declare sql text;
	Declare i integer;
	
Begin

	If clearing_house.fn_table_exists($2) = false Then
		Raise Exception 'Table does not exist: %', $2;
		Return Null;
	End If;  

	sql := 'Delete From clearing_house.' || $2 || ' Where submission_id = ' || $1::character varying(20) || ';';
	
	--Execute sql;

	submission_columns := clearing_house.fn_get_submission_table_column_names($1, $2);

	If Not (submission_columns is Null or array_length(submission_columns, 1) = 0) Then

		submission_column_types := clearing_house.fn_get_submission_table_column_types($1, $2);

		insert_columns_string := array_to_string(submission_columns, ', ');
		
		select_columns_string := '';
		For i In array_lower(submission_columns, 1) .. array_upper(submission_columns, 1)
		Loop

			select_columns_string := select_columns_string || ' v.values[' || i::text || ']::' || submission_column_types[i] || Case When i < array_upper(submission_columns, 1) Then ', ' Else '' End;

		End Loop;

		/*
		If Not submission_columns <@ clearing_house.fn_get_schema_table_column_names($2) Then
			Raise Exception 'XML contains unknown columns for table % [%] [%]', $2, array_to_string(submission_columns, ','), array_to_string(clearing_house.fn_get_schema_table_column_names($2), ',');
			Return Null;
		End If;
		*/

		insert_columns_string := replace(insert_columns_string, 'cloned_id', 'public_db_id');

		/* Insert values to entity tables. Insert Local DB id attribute (ref_id) if the attribute is a FK */
		sql := sql || 'Insert Into clearing_house.' || $2 || ' (submission_id, source_id, local_db_id, ' || insert_columns_string || ') 
			Select v.submission_id, 1 as source_id, -local_db_id, ' || select_columns_string || '
			From (
				Select v.submission_id, t.table_name, local_db_id, array_agg(
					   Case when v.fk_flag = TRUE Then
							Case When Not v.fk_public_db_id Is Null And r.fk_local_db_id Is Null Then v.fk_public_db_id::text Else (-v.fk_local_db_id)::text End
					   Else v.value End
					Order by c.column_id asc
				) as values
				From clearing_house.tbl_clearinghouse_submission_xml_content_values v

				Join clearing_house.tbl_clearinghouse_submission_tables t
				  On t.table_id = v.table_id

				Join clearing_house.tbl_clearinghouse_submission_xml_content_columns c
				  On c.submission_id = v.submission_id
				 And c.table_id = t.table_id
				 And c.column_id = v.column_id

                /* Check if public record pointed to by FK exists in local DB. In such case set FK value to -fk_local_db_id */
                Left Join clearing_house.view_clearinghouse_local_fk_references r
                  On v.fk_flag = TRUE
                 And r.submission_id = v.submission_id
                 And r.table_id = t.table_id
                 And r.column_id = c.column_id
                 And r.local_db_id = v.local_db_id
                 And r.fk_local_db_id = v.fk_local_db_id

				Where 1 = 1
				  And v.submission_id = ' || $1::character varying(20) || '
				  And t.table_name_underscored = ''' || $2 || '''
				Group By v.submission_id, t.table_name, v.local_db_id
			) as v
		';



		Raise Notice 'Inserted %', sql;
		
		Execute sql;
	
	End If;  


	/* Insert explicilty referenced public data */
	
/*
	public_columns_string := array_to_string(clearing_house.fn_get_public_table_column_names('public', $2), ', ');
	public_key_columns_string := clearing_house.fn_get_public_table_key_column_name('public', $2);
	
	sql := 'Insert Into clearing_house.' || $2 || ' (submission_id, source_id, local_db_id, public_db_id, ' || public_columns_string || ') 
		Select ' || $1::text || ' as submission_id, 2 as source_id, r.local_db_id, e.' || public_key_columns_string || ', ' || public_columns_string || '
		From public.' || $2 || ' e
		Join clearing_house.tbl_clearinghouse_submission_xml_content_records r
		  On r.submission_id = ' || $1::text || '
		 And r.public_db_id = e.' || public_key_columns_string || '
		Join clearing_house.tbl_clearinghouse_submission_tables t
		  On t.table_id = r.table_id
		Where r.submission_id = ' || $1::text || '
		  And t.table_name_underscored = ''' || $2 || ''' 
		  And Not r.public_db_id Is NULL
	';
*/

	Execute sql;

	--Raise Notice 'Copied data: %', sql;

	Return sql;
	
End $_$;


--
-- Name: fn_copy_extracted_values_to_entity_tables(integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_copy_extracted_values_to_entity_tables(integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$
	Declare x RECORD;
Begin

	For x In (Select t.*
			  From clearing_house.tbl_clearinghouse_submission_tables t
			  Join clearing_house.tbl_clearinghouse_submission_xml_content_tables c
			    On c.table_id = t.table_id
			  Where c.submission_id = $1
	) Loop

		--Raise Notice 'Executing table: %', x.table_name_underscored;

		Perform clearing_house.fn_add_new_public_db_columns($1, x.table_name_underscored);
		Perform clearing_house.fn_copy_extracted_values_to_entity_table($1, x.table_name_underscored);

	End Loop;	
	
	--Raise Notice 'XML entity field values extracted and stored for submission id %', $1;
	
End $_$;


--
-- Name: fn_create_local_union_public_entity_views(character varying, character varying); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_create_local_union_public_entity_views(target_schema character varying, local_schema character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
	
	Declare x RECORD;
	Declare drop_script text;
	Declare create_script text;
	
Begin

	Drop Table If Exists clearing_house.tbl_clearinghouse_SEAD_Create_View_Log;
	
	Create Table clearing_house.tbl_clearinghouse_SEAD_Create_View_Log (create_script text, drop_script text);
	
	For x In (
		Select distinct table_schema As public_schema, table_name, replace(table_name, 'tbl_', 'view_') As view_name
		From clearing_house.tbl_clearinghouse_SEAD_rdb_schema
		Where table_schema Not In ('information_schema', 'pg_catalog', 'clearing_house', 'metainformation')
		  And table_name Like 'tbl%'
		  And is_pk = 'YES' /* Måste finnas PK */
	)
	Loop

		drop_script = 'Drop View If Exists ' || target_schema || '.' || x.view_name || ';';

		create_script := clearing_house.fn_script_local_union_public_entity_view(target_schema, local_schema, x.public_schema, x.table_name);

		If (create_script <> '') Then

			Insert Into clearing_house.tbl_clearinghouse_SEAD_Create_View_Log (create_script, drop_script) Values (create_script, drop_script);

			Execute drop_script || ' ' || create_script;
			

		Else
			Insert Into clearing_house.tbl_clearinghouse_SEAD_Create_View_Log (create_script, drop_script) Values ('--Failed: ' || target_schema || '.' || x.table_name, '');
		End If;

		
	End Loop;
	
End $$;


--
-- Name: fn_create_public_db_entity_tables(character varying); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_create_public_db_entity_tables(target_schema character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
	
	Declare x RECORD;
	Declare create_script text;
	Declare drop_script text;
	
Begin

	Drop Table If Exists clearing_house.tbl_clearinghouse_SEAD_Create_Table_Log;
	
	Create Table clearing_house.tbl_clearinghouse_SEAD_Create_Table_Log (create_script text, drop_script text);
	
	For x In (
		Select distinct table_schema As source_schema, table_name
		From clearing_house.tbl_clearinghouse_SEAD_rdb_schema
		Where table_schema Not In ('information_schema', 'pg_catalog', 'clearing_house')
		  And table_name Like 'tbl%'
	)
	Loop

		If clearing_house.fn_table_exists(target_schema || '.' || x.table_name) Then

			Raise Exception 'Skipped: % since table already exists. ', target_schema || '.' || x.table_name;
			
		Else
	
			create_script := clearing_house.fn_script_public_db_entity_table(x.source_schema, target_schema, x.table_name);
			drop_script := 'Drop Table If Exists ' || target_schema || '.' ||  x.table_name || ';';

			If (create_script <> '') Then

				Execute drop_script;
				Execute create_script;

				Insert Into clearing_house.tbl_clearinghouse_SEAD_Create_Table_Log (create_script, drop_script) Values (create_script, drop_script);

			Else
				Insert Into clearing_house.tbl_clearinghouse_SEAD_Create_Table_Log (create_script, drop_script) Values ('--Failed: ' || target_schema || '.' || x.table_name, '');
			End If;


		End If;
		
	End Loop;
	
End $$;


--
-- Name: fn_create_schema_type_string(character varying, integer, integer, integer, character varying); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_create_schema_type_string(data_type character varying, character_maximum_length integer, numeric_precision integer, numeric_scale integer, is_nullable character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
	Declare type_string text;
Begin
	type_string :=  data_type
		||	Case When data_type = 'character varying' Then '(' || Coalesce(character_maximum_length::text, '255') || ')'
				 When data_type = 'numeric' Then
					Case When numeric_precision Is Null And numeric_scale Is Null Then  ''
						 When numeric_scale Is Null Then  '(' || numeric_precision::text || ')'
						 Else '(' || numeric_precision::text || ', ' || numeric_scale::text || ')'
					End
				 Else '' End || ' '|| Case When Coalesce(is_nullable,'') = 'YES' Then 'null' Else 'not null' End;					 
	return type_string;

End $$;


--
-- Name: fn_dba_create_clearing_house_db_model(); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_dba_create_clearing_house_db_model() RETURNS void
    LANGUAGE plpgsql
    AS $$

Begin



    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_settings') Then

        -- Drop Table clearing_house.tbl_clearinghouse_settings
        Create Table If Not Exists clearing_house.tbl_clearinghouse_settings (
            setting_id serial not null,
            setting_group character varying(255) not null,
            setting_key character varying(255) not null,
            setting_value text not null,
            setting_datatype text not null,
            Constraint pk_tbl_clearinghouse_settings Primary Key (setting_id)
        );

        create unique index idx_tbl_clearinghouse_settings_key On clearing_house.tbl_clearinghouse_settings (setting_key);
        create index idx_tbl_clearinghouse_settings_group On clearing_house.tbl_clearinghouse_settings (setting_group);

    End If;

    If (Select Count(*) From clearing_house.tbl_clearinghouse_settings) = 0 Then

        
        Insert Into clearing_house.tbl_clearinghouse_settings (setting_group, setting_key, setting_value, setting_datatype) 
            Values
                ('logger', 'folder', '/tmp/', 'string'),
                ('', 'max_execution_time', '120', 'numeric'),
                ('mailer', 'smtp-server', 'mail.acc.umu.se', 'string'),
                ('mailer', 'reply-address', 'noreply@sead.se', 'string'),
                ('mailer', 'sender-name', 'SEAD Clearing House', 'string'),
                ('mailer', 'smtp-auth', 'false', 'bool'),
                ('mailer', 'smtp-username', '', 'string'),
                ('mailer', 'smtp-password', '', 'string'),

                ('signal-templates', 'reject-subject', 'SEAD Clearing House: submission has been rejected', 'string'),
                ('signal-templates', 'reject-body',
'
Your submission to SEAD Clearing House has been rejected!

Reject causes:

#REJECT-CAUSES#

This is an auto-generated mail from the SEAD Clearing House system

', 'string'),
 
                ('signal-templates', 'reject-cause',
'
            
Entity type: #ENTITY-TYPE# 
Error scope: #ERROR-SCOPE# 
Entities: #ENTITY-ID-LIST# 
Note:  #ERROR-DESCRIPTION# 

--------------------------------------------------------------------

', 'string'),

                ('signal-templates', 'accept-subject', 'SEAD Clearing House: submission has been accepted', 'string'),
        
                ('signal-templates', 'accept-body',
'
            
Your submission to SEAD Clearing House has been accepted!

This is an auto-generated mail from the SEAD Clearing House system

', 'string'),

                ('signal-templates', 'reclaim-subject', 'SEAD Clearing House notfication: Submission #SUBMISSION-ID# has been transfered to pending', 'string'),
        
                ('signal-templates', 'reclaim-body', '
            
Status of submission #SUBMISSION-ID# has been reset to pending due to inactivity.

A submission is automatically reset to pending status when #DAYS-UNTIL-RECLAIM# days have passed since the submission
was claimed for review, and if no activity during has been registered during last #DAYS-WITHOUT-ACTIVITY# days.

This is an auto-generated mail from the SEAD Clearing House system.

', 'string'),
 
                ('signal-templates', 'reminder-subject', 'SEAD Clearing House reminder: Submission #SUBMISSION-ID#', 'string'),
        
                ('signal-templates', 'reminder-body', '
            
Status of submission #SUBMISSION-ID# has been reset to pending due to inactivity.

A reminder is automatically send when #DAYS-UNTIL-REMINDER# have passed since the submission
was claimed for review.

This is an auto-generated mail from the SEAD Clearing House system.

', 'string'),
    
                ('reminder', 'days_until_first_reminder', '14', 'numeric'),
                ('reminder', 'days_since_claimed_until_transfer_back_to_pending', '28', 'numeric'),
                ('reminder', 'days_without_activity_until_transfer_back_to_pending', '14', 'numeric');

    
    End If;



    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_info_references') Then

        -- Drop Table clearing_house.tbl_clearinghouse_info_references
        Create Table If Not Exists clearing_house.tbl_clearinghouse_info_references (
            info_reference_id serial not null,
            info_reference_type character varying(255) not null,
            display_name character varying(255) not null,
            href character varying(255),
            Constraint pk_tbl_clearinghouse_info_references Primary Key (info_reference_id)
        );

    End If;

    If (Select Count(*) From clearing_house.tbl_clearinghouse_info_references) = 0 Then

        Insert Into clearing_house.tbl_clearinghouse_info_references (info_reference_type, display_name, href)
            Values
                ('link', 'SEAD overview article',  'http://bugscep.com/phil/publications/Buckland2010_jns.pdf'),
                ('link', 'Popular science description of SEAD aims',  'http://bugscep.com/phil/publications/buckland2011_international_innovation.pdf');

    End If;

    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_sessions') Then

        Create Table If Not Exists clearing_house.tbl_clearinghouse_sessions (
            session_id serial not null,
            user_id int not null default(0),
            ip character varying(255),
            start_time date not null,
            stop_time date,
            Constraint pk_tbl_clearinghouse_sessions_session_id Primary Key (session_id)
        );

    End If;
    
    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_signals') Then

        Create Table If Not Exists clearing_house.tbl_clearinghouse_signals (
            signal_id serial not null,
            use_case_id int not null default(0),
            recipient_user_id int not null default(0),
            recipient_address text not null,
            signal_time date not null,
            subject text,
            body text,
            status text,
            Constraint pk_clearinghouse_signals_signal_id Primary Key (signal_id)
        );

    End If;

    /*
    Create Table If Not Exists tbl_error_id_types (
        error_id int not null,
        description character varying(255) not null,
        Constraint pk_error_id Primary Key (error_id),
        Constraint fk_tbl_user_roles_role_id Foreign Key (role_id)
            References tbl_user_roles (role_id) Match Simple
                On Update No Action On Delete No Action
    );


    Insert Into tbl_error_id_types (error_id, description) Values (0, 'Not specified');

    Create Table If Not Exists tbl_error_log (
        error_log_id serial not null,
        error_id int not null,
        error_type character varying(32) not null,
        error_message text not null,
        error_file character varying(255) not null,
        error_line int not null,
        error_time date not null,
        error_user character varying(255) not null,
        Constraint pk_tbl_error_log Primary Key (error_log_id)
    );
    */

	if (false) Then

		Drop Table If Exists clearing_house.tbl_clearinghouse_activity_log;
		Drop Table If Exists clearing_house.tbl_clearinghouse_submissions;
		Drop Table If Exists clearing_house.tbl_clearinghouse_signal_log;

		Drop Table If Exists clearing_house.tbl_clearinghouse_submissions;
		Drop Table If Exists clearing_house.tbl_clearinghouse_reject_cause_types;
		Drop Table If Exists clearing_house.tbl_clearinghouse_reject_causes;
		Drop Table If Exists clearing_house.tbl_clearinghouse_users;
		Drop Table If Exists clearing_house.tbl_clearinghouse_user_roles;
		Drop Table If Exists clearing_house.tbl_clearinghouse_data_provider_grades;
		Drop Table If Exists clearing_house.tbl_clearinghouse_submission_states;
		
	End If;

    /*********************************************************************************************************************************
    ** Activity
    **********************************************************************************************************************************/

    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_use_cases') Then

		-- Drop Table clearing_house.tbl_clearinghouse_use_cases
		-- Alter Table clearing_house.tbl_clearinghouse_use_cases Add Column entity_type_id int not null default(0)
		Create Table clearing_house.tbl_clearinghouse_use_cases (
			use_case_id int not null,
			use_case_name character varying(255) not null,
			entity_type_id int not null default(0),
			Constraint pk_tbl_clearinghouse_use_cases PRIMARY KEY (use_case_id)
		);
		
	End If;

    If (Select Count(*) From clearing_house.tbl_clearinghouse_use_cases) = 0 Then

        -- Update clearing_house.tbl_clearinghouse_use_cases Set entity_type_id = 1 Where use_case_id In (1,2,20,21) 
        Insert Into clearing_house.tbl_clearinghouse_use_cases (use_case_id, use_case_name, entity_type_id) 
            Values (0, 'General', 0),
				   (1, 'Login', 1),
				   (2, 'Logout', 1),
				   (3, 'Upload submission', 2),
				   (4, 'Accept submission', 2),
				   (5, 'Reject submission', 2),
				   (6, 'Open submission', 2),
				   (7, 'Process submission', 2),
				   (8, 'Transfer submission', 2),
				   (9, 'Add reject cause', 2),
				   (10, 'Delete reject cause', 2),
				   (11, 'Claim submission', 2),
				   (12, 'Unclaim submission', 2),
				   (13, 'Execute report', 2),
				   (20, 'Add user', 1),
				   (21, 'Change user', 1),
                   (22, 'Send reminder', 2),
                   (23, 'Reclaim submission', 2),
                   (24, 'Nag', 0)

        ;

    End If;

    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_activity_log') Then

		-- Drop Table clearing_house.tbl_clearinghouse_activity_log
		-- Alter Table clearing_house.tbl_clearinghouse_activity_log add column entity_type_id int not null default(0)
		Create Table clearing_house.tbl_clearinghouse_activity_log (
			activity_log_id serial not null,
			use_case_id int not null default(0),
			user_id int not null default(0),
			session_id int not null default(0),
			entity_type_id int not null default(0),
			entity_id int not null default(0),
			execute_start_time date not null,
			execute_stop_time date,
			status_id int not null default(0),
			activity_data text null,
			message text not null default(''),
			Constraint pk_activity_log_id PRIMARY KEY (activity_log_id)
		);

		Create Index idx_clearinghouse_activity_entity_id
			On clearing_house.tbl_clearinghouse_activity_log (entity_type_id, entity_id);

	End If;


	
    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_signal_log') Then
    
		Create Table clearing_house.tbl_clearinghouse_signal_log (
			signal_log_id serial not null,
			use_case_id int not null,
			signal_time date not null,
			email text not null,
			cc text not null,
			subject text not null,
			body text not null,
			Constraint pk_signal_log_id PRIMARY KEY (signal_log_id)		
		);
		
	End If;

    /*********************************************************************************************************************************
    ** Users
    **********************************************************************************************************************************/

    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_data_provider_grades') Then

        Create Table clearing_house.tbl_clearinghouse_data_provider_grades (
            grade_id int not null,
            description character varying(255) not null,
            Constraint pk_grade_id PRIMARY KEY (grade_id)
        );

	End If;

    If (Select Count(*) From clearing_house.tbl_clearinghouse_data_provider_grades) = 0 Then

        Insert Into clearing_house.tbl_clearinghouse_data_provider_grades (grade_id, description)
			Values (0, 'n/a'), (1, 'Normal'), (2, 'Good'), (3, 'Excellent');

    End If;

    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_user_roles') Then

        Create Table clearing_house.tbl_clearinghouse_user_roles (
            role_id int not null,
            role_name character varying(255) not null,
            Constraint pk_role_id PRIMARY KEY (role_id)
        );

    End If;
    
    If (Select Count(*) From clearing_house.tbl_clearinghouse_user_roles) = 0 Then

        Insert Into clearing_house.tbl_clearinghouse_user_roles (role_id, role_name) 
            Values (0, 'Undefined'),
				   (1, 'Reader'),
				   (2, 'Normal'),
				   (3, 'Administrator'),
				   (4, 'Data Provider');

    End If;

    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_users') Then
		-- Drop Table clearing_house.tbl_clearinghouse_users
        Create Table clearing_house.tbl_clearinghouse_users (
            user_id serial not null,
            user_name character varying(255) not null,
            full_name character varying(255) not null default(''),
            password character varying(255) not null,
            email character varying(1024) not null default (''),
            signal_receiver boolean not null default(false),
            role_id int not null default(1),
            data_provider_grade_id int not null default(2),
            is_data_provider boolean not null default(false),
            create_date date not null,
            Constraint pk_user_id PRIMARY KEY (user_id),
            Constraint fk_tbl_user_roles_role_id FOREIGN KEY (role_id)
                References clearing_house.tbl_clearinghouse_user_roles (role_id) MATCH SIMPLE
                    ON Update NO Action ON DELETE NO ACTION,
            Constraint fk_tbl_data_provider_grades_grade_id FOREIGN KEY (data_provider_grade_id)
                References clearing_house.tbl_clearinghouse_data_provider_grades (grade_id) MATCH SIMPLE
                    ON Update NO Action ON DELETE NO ACTION
        );

		-- Alter table clearing_house.tbl_clearinghouse_users Add column is_data_provider boolean not null default(false)
    End If;

    If (Select Count(*) From clearing_house.tbl_clearinghouse_users) = 0 Then

		-- update clearing_house.tbl_clearinghouse_users set signal_receiver = true where user_id = 2
        Insert Into clearing_house.tbl_clearinghouse_users (user_name, password, full_name, role_id, data_provider_grade_id, create_date, email, signal_receiver) 
            Values ('test_reader', 'secret', 'Test Reader', 1, 0, '2013-10-08', 'roger.mahler@umu.se', false),
                   ('test_normal', 'secret', 'Test Normal', 2, 0, '2013-10-08', 'roger.mahler@umu.se', false),
                   ('test_admin', 'secret', 'Test Administrator', 3, 0, '2013-10-08', 'roger.mahler@umu.se', true),
                   ('test_provider', 'secret', 'Test Provider', 3, 3, '2013-10-08', 'roger.mahler@umu.se', true);

    End If;

    /*********************************************************************************************************************************
    ** XML content tables - intermediate tables using during process
    **********************************************************************************************************************************/

	If (false) Then

		Drop Table If Exists clearing_house.tbl_clearinghouse_submission_xml_content_values;
		Drop Table If Exists clearing_house.tbl_clearinghouse_submission_xml_content_records;
		Drop Table If Exists clearing_house.tbl_clearinghouse_submission_xml_content_columns;
		Drop Table If Exists clearing_house.tbl_clearinghouse_submission_xml_content_tables;
		Drop Table If Exists clearing_house.tbl_clearinghouse_submission_tables;
	
	End If;

    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_submission_tables') Then
	
		Create Table clearing_house.tbl_clearinghouse_submission_tables (
			table_id serial not null,
			table_name character varying(255) not null,
			table_name_underscored character varying(255) not null,
			Constraint pk_tbl_clearinghouse_submission_tables Primary Key (table_id) 
		);

		Create Unique Index idx_tbl_clearinghouse_submission_tables_name1
			On clearing_house.tbl_clearinghouse_submission_tables (table_name);

		Create Unique Index idx_tbl_clearinghouse_submission_tables_name2
			On clearing_house.tbl_clearinghouse_submission_tables (table_name_underscored);


		Insert Into clearing_house.tbl_clearinghouse_submission_tables (table_name, table_name_underscored)
			Select replace(initcap(replace(s.table_name, '_', ' ')), ' ', '') , s.table_name
			From (
				Select distinct table_name
				From clearing_house.tbl_clearinghouse_sead_rdb_schema
				Where table_schema = 'public'
			) As s
			Left Join clearing_house.tbl_clearinghouse_submission_tables t
			  On t.table_name_underscored = s.table_name
			Where t.table_id is NULL
			  And s.table_name Like 'tbl_%';

	End If;
	
    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_submission_xml_content_tables') Then

	
		Create Table clearing_house.tbl_clearinghouse_submission_xml_content_tables (
			content_table_id serial not null,
			submission_id int not null,
			table_id int not null,
			record_count int not null,
			Constraint pk_tbl_submission_xml_content_meta_tables_table_id Primary Key (content_table_id),
			Constraint fk_tbl_clearinghouse_submission_xml_content_tables Foreign Key (table_id)
			  References clearing_house.tbl_clearinghouse_submission_tables (table_id) Match Simple
				On Update NO ACTION ON DELETE Cascade
		);


		Create Unique Index fk_idx_tbl_submission_xml_content_tables_table_name
			On clearing_house.tbl_clearinghouse_submission_xml_content_tables (submission_id, table_id);

	End If;

    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_submission_xml_content_columns') Then

		Create Table clearing_house.tbl_clearinghouse_submission_xml_content_columns (
			column_id serial not null,
			submission_id int not null,
			table_id int not null,
			column_name character varying(255) not null,
			column_name_underscored character varying(255) not null,
			data_type character varying(255) not null,
			fk_flag boolean not null,
			fk_table character varying(255) null,
			fk_table_underscored character varying(255) null,
			Constraint pk_tbl_submission_xml_content_columns_column_id Primary Key (column_id),
			Constraint fk_tbl_submission_xml_content_columns_table_id Foreign Key (table_id)
			  References clearing_house.tbl_clearinghouse_submission_tables (table_id) Match Simple
				On Update NO ACTION ON DELETE Cascade
		); 

		Create Unique Index idx_tbl_submission_xml_content_columns_submission_id
			On clearing_house.tbl_clearinghouse_submission_xml_content_columns (submission_id, table_id, column_name);

	End If;

    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_submission_xml_content_records') Then

		Create Table clearing_house.tbl_clearinghouse_submission_xml_content_records (
			record_id serial not null,
			submission_id int not null,
			table_id int not null,
			local_db_id int null,
			public_db_id int null,
			Constraint pk_tbl_submission_xml_content_records_record_id Primary Key (record_id),
			Constraint fk_tbl_submission_xml_content_records_table_id Foreign Key (table_id)
			  References clearing_house.tbl_clearinghouse_submission_tables (table_id) Match Simple
				On Update NO ACTION ON DELETE Cascade
			
		);

		Create Unique Index idx_tbl_submission_xml_content_records_submission_id
			On clearing_house.tbl_clearinghouse_submission_xml_content_records (submission_id, table_id, local_db_id);

	End If;

    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_submission_xml_content_values') Then

		-- Drop Table tbl_submission_xml_content_record_values
		Create Table clearing_house.tbl_clearinghouse_submission_xml_content_values (
			value_id serial not null,
			submission_id int not null,
			table_id int not null,
			local_db_id int not null,
			column_id int not null,
			fk_flag boolean null,
			fk_local_db_id int null,
			fk_public_db_id int null,
			value text null,
			Constraint pk_tbl_submission_xml_content_record_values_value_id Primary Key (value_id),
			Constraint fk_tbl_submission_xml_content_meta_record_values_table_id Foreign Key (table_id)
			  References clearing_house.tbl_clearinghouse_submission_tables (table_id) Match Simple
				On Update NO ACTION ON DELETE Cascade
			
		);

		Create Unique Index idx_tbl_submission_xml_content_record_values_column_id
			On clearing_house.tbl_clearinghouse_submission_xml_content_values (submission_id, table_id, local_db_id, column_id);

	End If;
	
    /*********************************************************************************************************************************
    ** Submissions
    **********************************************************************************************************************************/

     -- ALTER TABLE metainformation.tbl_upload_contents
     --  OWNER TO seadworker;

    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_submission_states') Then

        Create Table clearing_house.tbl_clearinghouse_submission_states (
            submission_state_id int not null,
            submission_state_name character varying(255) not null,
            CONSTRAINT pk_submission_state_id PRIMARY KEY (submission_state_id)
        );

    End If;

    If (Select Count(*) From clearing_house.tbl_clearinghouse_submission_states) = 0 Then

        Insert Into clearing_house.tbl_clearinghouse_submission_states (submission_state_id, submission_state_name)
            Values	(0, 'Undefined'),
                    (1, 'New'),
                    (2, 'Pending'),
                    (3, 'In progress'),
                    (4, 'Accepted'),
                    (5, 'Rejected'),
                    (9, 'Error');

    End If;

    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_submissions') Then

		--Alter Table clearing_house.tbl_clearinghouse_submissions Drop Column upload_date
		--Alter Table clearing_house.tbl_clearinghouse_submissions Add Column upload_date Date Not Null default now()
		-- Drop table clearing_house.tbl_clearinghouse_users

        Create Table clearing_house.tbl_clearinghouse_submissions
        (
          submission_id serial NOT NULL,
          submission_state_id integer NOT NULL,
          data_types character varying(255), 
          upload_user_id integer NOT NULL,
          upload_date Date Not Null default now(),
          upload_content text,
          xml xml, 
          status_text text,
          claim_user_id integer,
          claim_date_time date,
          Constraint pk_submission_id PRIMARY KEY (submission_id),
          Constraint fk_tbl_submissions_user_id_user_id FOREIGN KEY (claim_user_id)
              References clearing_house.tbl_clearinghouse_users (user_id) MATCH SIMPLE
                ON UPDATE NO ACTION ON DELETE NO ACTION,
          Constraint fk_tbl_submissions_state_id_state_id FOREIGN KEY (submission_state_id)
              References clearing_house.tbl_clearinghouse_submission_states (submission_state_id) MATCH SIMPLE
                ON UPDATE NO ACTION ON DELETE NO ACTION
        );

        --GRANT ALL ON TABLE metainformation.tbl_upload_contents TO seadworker;
        --COMMENT ON TABLE metainformation.tbl_upload_contents IS 'Table for storing information about an upload. The actual upload is stored in a file separately.';
        --COMMENT ON COLUMN metainformation.tbl_upload_contents.upload_data_types IS 'A series of data types contained in the uploaded data. This list should be separated by something.';

    End If;

    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_accepted_submissions') Then

        Create Table clearing_house.tbl_clearinghouse_accepted_submissions
        (
          accepted_submission_id serial NOT NULL,
          process_state_id bool NOT NULL,
          submission_id int,
          upload_file text,
          accept_user_id integer,
          Constraint pk_tbl_clearinghouse_accepted_submissions PRIMARY KEY (accepted_submission_id)
        );

    End If;

    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_reject_entity_types') Then

        Drop Table If Exists clearing_house.tbl_clearinghouse_reject_entity_types;

        Create Table clearing_house.tbl_clearinghouse_reject_entity_types
        (
			entity_type_id int NOT NULL,
			table_id int NULL,
			entity_type character varying(255) NOT NULL,
			Constraint pk_tbl_clearinghouse_reject_entity_types PRIMARY KEY (entity_type_id)
        );

        Create Index fk_clearinghouse_reject_entity_types On clearing_house.tbl_clearinghouse_reject_entity_types (table_id);

    End If;

     If (Select Count(*) From clearing_house.tbl_clearinghouse_reject_entity_types) = 0 Then

		--Delete From clearing_house.tbl_clearinghouse_reject_entity_types
        Insert Into clearing_house.tbl_clearinghouse_reject_entity_types (entity_type_id, table_id, entity_type)

            Select 0,  0, 'Not specified'
			Union
            Select row_number() over (ORDER BY table_name),  table_id, left(substring(table_name,4),Length(table_name)-4) 
            From clearing_house.tbl_clearinghouse_submission_tables
            Where table_name Like 'Tbl%s'
            Order by 1;

        /* Komplettera med nya */
        Insert Into clearing_house.tbl_clearinghouse_reject_entity_types (entity_type_id, table_id, entity_type)

            Select (Select Max(entity_type_id) From clearing_house.tbl_clearinghouse_reject_entity_types) + row_number() over (ORDER BY table_name),  t.table_id, left(substring(table_name,4),Length(table_name)-3) 
            From clearing_house.tbl_clearinghouse_submission_tables t
			Left Join clearing_house.tbl_clearinghouse_reject_entity_types x
			  On x.table_id = t.table_id
            Where x.table_id Is Null
            Order by 1;


        /* Fixa beskrivningstext */
        Update clearing_house.tbl_clearinghouse_reject_entity_types as x
			set entity_type = replace(trim(replace(regexp_replace(t.table_name, E'([A-Z])', E'\_\\1','g'), '_', ' ')), 'Tbl ', '')
        From clearing_house.tbl_clearinghouse_submission_tables t
        Where t.table_id = x.table_id
          And replace(trim(replace(regexp_replace(t.table_name, E'([A-Z])', E'\_\\1','g'), '_', ' ')), 'Tbl ', '') <> x.entity_type;

    End If;

    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_submission_rejects') Then

        -- alter table clearing_house.tbl_clearinghouse_submission_rejects add column site_id int NOT NULL default(0)
        Create Table clearing_house.tbl_clearinghouse_submission_rejects
        (
			submission_reject_id serial NOT NULL,
			submission_id int NOT NULL,
			site_id int NOT NULL default(0),
			entity_type_id int NOT NULL,
			reject_scope_id int NOT NULL, /* 0, 1=specific, 2=General */
			reject_description text NULL,
			Constraint pk_tbl_clearinghouse_submission_rejects PRIMARY KEY (submission_reject_id),
			Constraint fk_tbl_clearinghouse_submission_rejects_submission_id Foreign Key (submission_id)
			  References clearing_house.tbl_clearinghouse_submissions (submission_id) Match Simple
				On Update NO ACTION ON DELETE Cascade
		);

        Create Index fk_clearinghouse_submission_rejects On clearing_house.tbl_clearinghouse_submission_rejects (submission_id);

    End If;
    

    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_submission_reject_entities') Then

        Create Table clearing_house.tbl_clearinghouse_submission_reject_entities
        (
			reject_entity_id serial NOT NULL,
			submission_reject_id int NOT NULL,
			local_db_id int NOT NULL,
			Constraint pk_tbl_clearinghouse_submission_reject_entities PRIMARY KEY (reject_entity_id),
			Constraint fk_tbl_clearinghouse_submission_reject_entities Foreign Key (submission_reject_id)
			  References clearing_house.tbl_clearinghouse_submission_rejects (submission_reject_id) Match Simple
				On Update NO ACTION ON DELETE Cascade
		);

        Create Index fk_clearinghouse_submission_reject_entities_submission On clearing_house.tbl_clearinghouse_submission_reject_entities (submission_reject_id);
        Create Index fk_clearinghouse_submission_reject_entities_local_db_id On clearing_house.tbl_clearinghouse_submission_reject_entities (local_db_id);

    End If;

    If Not Exists (Select * From INFORMATION_SCHEMA.tables Where table_catalog = CURRENT_CATALOG And table_schema = 'clearing_house' And table_name = 'tbl_clearinghouse_reports') Then

        --Drop Table clearing_house.tbl_clearinghouse_reports

        Create Table clearing_house.tbl_clearinghouse_reports
        (
            report_id int NOT NULL,
            report_name character varying(255), 
            report_procedure text not null,
            Constraint pk_tbl_clearinghouse_reports PRIMARY KEY (report_id)
        );

    End If;



End $$;


--
-- Name: fn_dd2dms(double precision, character varying, character varying, character varying); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_dd2dms(p_ddecdeg double precision, p_sdegreesymbol character varying DEFAULT 'd'::character varying, p_sminutesymbol character varying DEFAULT 'm'::character varying, p_ssecondsymbol character varying DEFAULT 's'::character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
   v_iDeg INT;
   v_iMin INT;
   v_dSec FLOAT;
Begin

   v_iDeg := Trunc(p_dDecDeg)::INT;
   v_iMin := Trunc((Abs(p_dDecDeg) - Abs(v_iDeg)) * 60)::int;
   v_dSec := Round(((((Abs(p_dDecDeg) - Abs(v_iDeg)) * 60) - v_iMin) * 60)::numeric, 3)::float;
   
   Return trim(to_char(v_iDeg,'9999')) || p_sDegreeSymbol::text || trim(to_char(v_iMin,'99')) || p_sMinuteSymbol::text ||
          Case When v_dSec = 0::FLOAT Then '0' Else replace(trim(to_char(v_dSec,'99.999')),'.000','') End || p_sSecondSymbol::text;
          
End $$;


--
-- Name: fn_explode_submission_xml_to_rdb(integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_explode_submission_xml_to_rdb(integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$

Begin

	Perform clearing_house.fn_extract_and_store_submission_tables($1);
	Perform clearing_house.fn_extract_and_store_submission_columns($1);
	Perform clearing_house.fn_extract_and_store_submission_records($1);
	Perform clearing_house.fn_extract_and_store_submission_values($1);

	Perform clearing_house.fn_copy_extracted_values_to_entity_tables($1);

End $_$;


--
-- Name: fn_extract_and_store_submission_columns(integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_extract_and_store_submission_columns(integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$

Begin

	Delete From clearing_house.tbl_clearinghouse_submission_xml_content_columns
		Where submission_id = $1;
		
	/* Extract all unique column names */
	Insert Into clearing_house.tbl_clearinghouse_submission_xml_content_columns (submission_id, table_id, column_name, column_name_underscored, data_type, fk_flag, fk_table, fk_table_underscored)
		Select	c.submission_id,
				t.table_id,
				c.column_name,
				clearing_house.fn_pascal_case_to_underscore(c.column_name),
				c.column_type,
				left(c.column_type, 18) = 'com.sead.database.',
				Case When left(c.column_type, 18) = 'com.sead.database.' Then substring(c.column_type from 19) Else Null End,
				''
		From  clearing_house.fn_select_xml_content_columns($1) c
		Join clearing_house.tbl_clearinghouse_submission_tables t
		  On t.table_name = c.table_name
		Where c.submission_id = $1;

	Update clearing_house.tbl_clearinghouse_submission_xml_content_columns
		Set fk_table_underscored = clearing_house.fn_pascal_case_to_underscore(fk_table)
	Where submission_id = $1;

	--Raise Notice 'XML columns extracted and stored for submission id %', $1;
	
End $_$;


--
-- Name: fn_extract_and_store_submission_records(integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_extract_and_store_submission_records(integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$

Begin

	/* Extract all unique records */
	Insert Into clearing_house.tbl_clearinghouse_submission_xml_content_records (submission_id, table_id, local_db_id, public_db_id)
		Select r.submission_id, t.table_id, r.local_db_id, coalesce(r.public_db_id_tag, public_db_id_attr)
		From clearing_house.fn_select_xml_content_records($1) r
		Join clearing_house.tbl_clearinghouse_submission_tables t
		  On t.table_name = r.table_name
		Where r.submission_id = $1;
		
	--Raise Notice 'XML record headers extracted and stored for submission id %', $1;
	
End $_$;


--
-- Name: fn_extract_and_store_submission_tables(integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_extract_and_store_submission_tables(integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$

Begin

	/* Delete existing data (cascade) */
	Delete From clearing_house.tbl_clearinghouse_submission_xml_content_values
		Where submission_id = $1;

	Delete From clearing_house.tbl_clearinghouse_submission_xml_content_columns
		Where submission_id = $1;

	Delete From clearing_house.tbl_clearinghouse_submission_xml_content_records
		Where submission_id = $1;

	Delete From clearing_house.tbl_clearinghouse_submission_xml_content_tables
		Where submission_id = $1;

	/* Register new tables not previously encountered */
	Insert Into clearing_house.tbl_clearinghouse_submission_tables (table_name, table_name_underscored)
		Select t.table_name, clearing_house.fn_pascal_case_to_underscore(t.table_name)
		From  clearing_house.fn_select_xml_content_tables($1) t
		Left Join clearing_house.tbl_clearinghouse_submission_tables x
		  On x.table_name = t.table_name
		Where x.table_name Is NULL;
	
	/* Store all tables that att exists in submission */
	Insert Into clearing_house.tbl_clearinghouse_submission_xml_content_tables (submission_id, table_id, record_count)
		Select t.submission_id, x.table_id, t.row_count
		From  clearing_house.fn_select_xml_content_tables($1) t
		Join clearing_house.tbl_clearinghouse_submission_tables x
		  On x.table_name = t.table_name
		;

	--Raise Notice 'XML entity tables extracted and stored for submission id %', $1;
	
End $_$;


--
-- Name: fn_extract_and_store_submission_values(integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_extract_and_store_submission_values(integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$
	Declare x RECORD;
Begin

	For x In (Select t.*
			  From clearing_house.tbl_clearinghouse_submission_tables t
			  Join clearing_house.tbl_clearinghouse_submission_xml_content_tables c
			    On c.table_id = t.table_id
			  Where c.submission_id = $1)
	Loop

		Insert Into clearing_house.tbl_clearinghouse_submission_xml_content_values (submission_id, table_id, local_db_id, column_id, fk_flag, fk_local_db_id, fk_public_db_id, value)
			Select	$1,
					t.table_id,
					v.local_db_id,
					c.column_id,
					Not (v.fk_local_db_id Is Null),
					v.fk_local_db_id,
					v.fk_public_db_id,
					Case When v.value = 'NULL' Then NULL Else v.value End
			From clearing_house.fn_select_xml_content_values($1, x.table_name) v
			Join clearing_house.tbl_clearinghouse_submission_tables t
			  On t.table_name = v.table_name
			Join clearing_house.tbl_clearinghouse_submission_xml_content_columns c
			  On c.submission_id = v.submission_id
			 And c.table_id = t.table_id
			 And c.column_name = v.column_name;

	End Loop;		
	
	--Raise Notice 'XML entity field values extracted and stored for submission id %', $1;
	
End $_$;


--
-- Name: fn_get_entity_type_for(character varying); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_get_entity_type_for(character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
Declare
    table_entity_type_id int;
Begin
    Select x.entity_type_id Into table_entity_type_id
    From clearing_house.tbl_clearinghouse_reject_entity_types x
    Join clearing_house.tbl_clearinghouse_submission_tables t
      On x.table_id = t.table_id
    Where table_name_underscored = $1;

    Return Coalesce(table_entity_type_id,0);	
End $_$;


--
-- Name: fn_get_public_table_column_names(character varying, character varying); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_get_public_table_column_names(sourceschema character varying, tablename character varying) RETURNS character varying[]
    LANGUAGE plpgsql
    AS $$
	Declare columns character varying(255)[];
Begin
	Select array_agg(c.column_name order by ordinal_position asc) Into columns
	From clearing_house.tbl_clearinghouse_SEAD_rdb_schema c
	Where c.table_schema = sourceschema
	  And c.table_name = tablename;
	return columns;
End $$;


--
-- Name: fn_get_public_table_key_column_name(character varying, character varying); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_get_public_table_key_column_name(sourceschema character varying, tablename character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
	Declare key_column character varying(255);
Begin
	Select c.column_name Into key_column
	From clearing_house.tbl_clearinghouse_SEAD_rdb_schema c
	Where c.table_schema = sourceschema
	  And c.table_name = tablename
	  And c.is_pk = 'YES'
	Limit 1;
	return key_column;
End $$;


--
-- Name: fn_get_schema_table_column_names(character varying); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_get_schema_table_column_names(character varying) RETURNS character varying[]
    LANGUAGE plpgsql
    AS $_$
	Declare columns character varying(255)[];
Begin

	Select array_agg(column_name::character varying(255)) Into columns
		From information_schema.columns 
		Where table_catalog = CURRENT_CATALOG
		  And table_schema = CURRENT_SCHEMA
		  And table_name = $1;
	
	return columns;
	
End $_$;


--
-- Name: fn_get_submission_table_column_names(integer, character varying); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_get_submission_table_column_names(integer, character varying) RETURNS character varying[]
    LANGUAGE plpgsql
    AS $_$
	Declare columns character varying(255)[];
Begin

	Select array_agg(c.column_name_underscored order by c.column_id asc) Into columns
	From clearing_house.tbl_clearinghouse_submission_tables t
    Join clearing_house.tbl_clearinghouse_submission_xml_content_columns c
	  On c.table_id = t.table_id
	Where c.submission_id = $1
	  And t.table_name_underscored = $2
	Group By c.submission_id, t.table_name;
	
	return columns;
	
End $_$;


--
-- Name: fn_get_submission_table_column_types(integer, character varying); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_get_submission_table_column_types(integer, character varying) RETURNS character varying[]
    LANGUAGE plpgsql
    AS $_$
	Declare columns character varying(255)[];
Begin

	Select array_agg(clearing_house.fn_java_type_to_PostgreSQL(c.data_type) order by c.column_id asc) Into columns
	From clearing_house.tbl_clearinghouse_submission_tables t
	Join clearing_house.tbl_clearinghouse_submission_xml_content_columns c
	  On c.table_id = t.table_id
	Where c.submission_id = $1
	  And t.table_name_underscored = $2
	Group By c.submission_id, t.table_name;
	
	return columns;
	
End $_$;


--
-- Name: fn_java_type_to_postgresql(character varying); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_java_type_to_postgresql(character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
Begin
	If ($1 = 'java.util.Date') Then
		return 'date';
	End If;
	
	If ($1 = 'java.math.BigDecimal') Then
		return 'numeric';
	End If;
	
	If ($1 = 'java.lang.Integer') Then
		return 'integer';
	End If;

	If ($1 = 'java.lang.Boolean') Then
		return 'boolean';
	End If;

	If ($1 = 'java.lang.String') Then
		return 'text';
	End If;

	If ($1 Like 'com.sead.database.%') Then
		return 'integer'; /* FK */
	End If;

	Raise Exception 'Fatal error: Java type % encountered in XML not expected', $1;
	
End $_$;


--
-- Name: fn_pascal_case_to_underscore(character varying); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_pascal_case_to_underscore(character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
Begin

	return lower(Left($1, 1) || regexp_replace(substring($1 from 2), E'([A-Z])', E'\_\\1','g'));

End $_$;


--
-- Name: fn_script_local_union_public_entity_view(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_script_local_union_public_entity_view(target_schema character varying, local_schema character varying, public_schema character varying, table_name character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
	#variable_conflict use_variable
	Declare sql_template text;
	Declare sql text;
	Declare column_list text;
	Declare pk_field text;	
Begin

	sql_template =
'/*****************************************************************************************************************************
**	Function	#VIEW-NAME#
**	Who			THIS VIEW IS AUTO-GENERATED BY fn_create_local_union_public_entity_views / Roger Mähler
**	When		#DATE#
**	What		Returns union of local and public versions of #TABLE-NAME#
**  Uses        clearing_house.tbl_clearinghouse_SEAD_rdb_schema
**	Note		Plase re-run fn_create_local_union_public_entity_views whenever public schema is changed
**  Used By     SEAD Clearing House 
******************************************************************************************************************************/

Create Or Replace View #TARGET-SCHEMA#.#VIEW-NAME# As 

	Select submission_id, source_id, local_db_id as merged_db_id, local_db_id, public_db_id, #COLUMN-LIST#
	From #LOCAL-SCHEMA#.#TABLE-NAME#
	Union
	Select 0 As submission_id, 2 As source_id, #PK-COLUMN# as merged_db_id, 0 As local_db_id, #PK-COLUMN# As public_db_id, #COLUMN-LIST#
	From #PUBLIC-SCHEMA#.#TABLE-NAME#
	
;';

	Select array_to_string(array_agg(s.column_name Order By s.ordinal_position), ',') Into column_list
	From clearing_house.tbl_clearinghouse_SEAD_rdb_schema s
	Join information_schema.columns c /* Ta endast med kolumner som finns i båda */
	  On c.table_schema = local_schema
	 And c.table_name = table_name
	 And c.column_name = s.column_name
	Where s.table_schema = public_schema
	  And s.table_name = table_name;

	Select column_name Into pk_field
	From clearing_house.tbl_clearinghouse_SEAD_rdb_schema s
	Where s.table_schema = public_schema
	  And s.table_name = table_name
	  And s.is_pk = 'YES';
	  
	sql := sql_template;
	sql := replace(sql, '#DATE#', to_char(now(), 'YYYY-MM-DD HH24:MI:SS'));
	sql := replace(sql, '#COLUMN-LIST#', column_list);
	sql := replace(sql, '#PK-COLUMN#', pk_field);
	sql := replace(sql, '#TARGET-SCHEMA#', target_schema);
	sql := replace(sql, '#LOCAL-SCHEMA#', local_schema);
	sql := replace(sql, '#PUBLIC-SCHEMA#', public_schema);
	sql := replace(sql, '#VIEW-NAME#', replace(table_name, 'tbl_', 'view_'));
	sql := replace(sql, '#TABLE-NAME#', table_name);

	Return sql;
	
End $$;


--
-- Name: fn_script_public_db_entity_table(character varying, character varying, character varying); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_script_public_db_entity_table(source_schema character varying, target_schema character varying, table_name character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
	#variable_conflict use_variable
	Declare sql_template text;
	Declare sql text;
	Declare column_list text;
	Declare pk_fields text;
	Declare x clearing_house.tbl_clearinghouse_SEAD_rdb_schema%rowtype;
	
Begin

	sql_template = '	Create Table #TABLE-NAME# (

		submission_id int not null,
		source_id int not null,
		
		local_db_id int not null,
		public_db_id int null,

		#COLUMN-LIST#

		#PK-CONSTRAINT#

	);';

	column_list := '';
	pk_fields := '';
	
	For x In (
		Select *
		From clearing_house.tbl_clearinghouse_SEAD_rdb_schema s
		Where s.table_schema = source_schema
		  And s.table_name = table_name
		Order By ordinal_position)
	Loop

		column_list := column_list || Case When column_list = '' Then '' Else ',
		'
		End;
		
		column_list := column_list || x.column_name || ' ' || clearing_house.fn_create_schema_type_string(x.data_type, x.character_maximum_length, x.numeric_precision, x.numeric_scale, x.is_nullable) || '';

		If x.is_pk = 'YES' Then
			pk_fields := pk_fields || Case When pk_fields = '' Then '' Else ', ' End || x.column_name;
		End If;
		
	End Loop;

	sql := sql_template;
	
	sql := replace(sql, '#TABLE-NAME#', target_schema || '.' || table_name);
	sql := replace(sql, '#COLUMN-LIST#', column_list);

	If pk_fields <> '' Then
		sql := replace(sql, '#PK-CONSTRAINT#', replace(',Constraint pk_' || table_name || ' Primary Key (submission_id, source_id, #PK-FIELDS#)', '#PK-FIELDS#', pk_fields));
	Else
		sql := replace(sql, '#PK-CONSTRAINT#', '');
	End If;


	Return sql;
	
End $$;


--
-- Name: fn_select_xml_content_columns(integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_select_xml_content_columns(integer) RETURNS TABLE(submission_id integer, table_name character varying, column_name character varying, column_type character varying)
    LANGUAGE plpgsql
    AS $_$
Begin

    Return Query

        Select	d.submission_id                                   							as submission_id,
                d.table_name																as table_name,
                substring(d.xml::text from '^<([[:alnum:]]+).*>')::character varying(255)	as column_name,
                (xpath('./@class[1]', d.xml))[1]::character varying(255)					as column_type
        From (
            Select x.submission_id, t.table_name, unnest(xpath('/sead-data-upload/' || t.table_name || '/*[not(@clonedId)][1]/*', xml)) As xml
            From clearing_house.tbl_clearinghouse_submissions x
            Join clearing_house.fn_select_xml_content_tables($1) t
              On t.submission_id = x.submission_id
            Where 1 = 1
              And x.submission_id = $1
              And Not xml Is Null
              And xml Is Document
        ) as d;

End $_$;


--
-- Name: fn_select_xml_content_records(integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_select_xml_content_records(integer) RETURNS TABLE(submission_id integer, table_name character varying, local_db_id integer, public_db_id_attr integer, public_db_id_tag integer)
    LANGUAGE plpgsql
    AS $_$
Begin

    Return Query

        With submission_xml_data_rows As (
        
            Select x.submission_id,
				   unnest(xpath('/sead-data-upload/*/*', x.xml)) As xml
            From clearing_house.tbl_clearinghouse_submissions x
            Where Not xml Is Null
              And xml Is Document
              And x.submission_id = $1
        )
            Select v.submission_id,
                   v.table_name::character varying(255),
                   Case When v.local_db_id ~ '^[0-9]+$' Then v.local_db_id::int Else Null End,
                   Case When v.public_db_id_attribute ~ '^[0-9]+$' Then v.public_db_id_attribute::int Else Null End,
                   Case When v.public_db_id_value ~ '^[0-9]+$' Then v.public_db_id_value::int Else Null End
            From (
                Select	d.submission_id																			as submission_id,
                        replace(substring(d.xml::text from '^<([[:alnum:]\.]+).*>'), 'com.sead.database.', '')	as table_name,
                        ((xpath('./@id[1]', d.xml))[1])::character varying(255)									as local_db_id,
                        ((xpath('./@clonedId[1]', d.xml))[1])::character varying(255)							as public_db_id_attribute,
                        ((xpath('./clonedId/text()', d.xml))[1])::character varying(255)						as public_db_id_value
                From submission_xml_data_rows as d
            ) As v;

End $_$;


--
-- Name: fn_select_xml_content_tables(integer); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_select_xml_content_tables(integer) RETURNS TABLE(submission_id integer, table_name character varying, row_count integer)
    LANGUAGE plpgsql
    AS $_$
Begin

    Return Query

        Select	d.submission_id																	as submission_id,
                --xnode(xml)																	as table_name,
                substring(d.xml::text from '^<([[:alnum:]]+).*>')::character varying(255)		as table_name,
                (xpath('./@length[1]', d.xml))[1]::text::int									as row_count
        From (
            Select x.submission_id, unnest(xpath('/sead-data-upload/*', x.xml)) As xml
            From clearing_house.tbl_clearinghouse_submissions as x
            Where 1 = 1
              And x.submission_id = $1
              And Not xml Is Null
              And xml Is Document
              
        ) d;

End $_$;


--
-- Name: fn_select_xml_content_values(integer, character varying); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_select_xml_content_values(integer, character varying) RETURNS TABLE(submission_id integer, table_name character varying, local_db_id integer, public_db_id integer, column_name character varying, column_type character varying, fk_local_db_id integer, fk_public_db_id integer, value text)
    LANGUAGE plpgsql
    AS $_$
Begin

	Return Query 

		Select	$1,
				$2,
				x.local_db_id																				as local_db_id,
				x.public_db_id																				as public_db_id,
				substring(xml::character varying(255) from '^<([[:alnum:]]+).*>')::character varying(255)	as column_name,
				(xpath('./@class[1]', xml))[1]::character varying(255)										as column_type,
				(xpath('./@id[1]', xml))[1]::character varying(255)::int									as fk_local_db_id,
				(xpath('./@clonedId[1]', xml))[1]::character varying(255)::int								as fk_public_db_id,
				(xpath('./text()', xml))[1]::text															as value
		From (
			Select	r.submission_id,
					r.table_name,
					r.local_db_id,
					r.public_db_id,
					unnest(xpath( '/*/*', r.xml)) As xml
			From (
				Select	d.submission_id																			as submission_id,
						replace(substring(xml::text from '^<([[:alnum:]\.]+).*>'), 'com.sead.database.', '')	as table_name,
						((xpath('./@id[1]', xml))[1])::character varying(255)::int								as local_db_id,
						((xpath('./@clonedId[1]', xml))[1])::character varying(255)::int						as public_db_id,
						xml																						as xml
				From (
					Select x.submission_id, unnest(xpath('/sead-data-upload/' || $2 || '/*', xml)) As xml
					From clearing_house.tbl_clearinghouse_submissions x
					Where 1 = 1
					  And x.submission_id = $1
					  And Not xml Is Null
					  And xml Is Document
				) as d
			) as r
		) as x;


End $_$;


--
-- Name: fn_table_exists(character varying); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_table_exists(character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
	Declare exists Boolean;
Begin

	Select Count(*) > 0 Into exists 
		From information_schema.tables 
		Where table_catalog = CURRENT_CATALOG
		  And table_schema = CURRENT_SCHEMA
		  And table_name = $1;

	return exists;
	
End $_$;


--
-- Name: fn_to_integer(character varying); Type: FUNCTION; Schema: clearing_house; Owner: -
--

CREATE FUNCTION fn_to_integer(character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
Begin
	Return Case When ($1 ~ '^[0-9]+$') Then $1::int Else null End;	
End $_$;


SET search_path = public, pg_catalog;

--
-- Name: create_sample_position_view(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION create_sample_position_view() RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
	methods record;
	pos_cols text;
	sub_select_clause text := '';
	select_clause text := '';
	point_clause varchar;
	normalized_method_name varchar := '';
	transform_string varchar;
begin

	for methods in (select *
			from tbl_methods m
			where m.method_group_id = 17) loop

	normalized_method_name := replace(methods.method_name, ' ', '_');
	normalized_method_name := replace(normalized_method_name, '.', '_');
	normalized_method_name := replace(normalized_method_name, '(', '_');
	normalized_method_name := replace(normalized_method_name, ')', '_');

	transform_string := get_transform_string(normalized_method_name);
	if transform_string = '-1' then
		continue;
	end if;

	if select_clause != '' then
		select_clause := select_clause || ',';
	end if;
	
	select_clause := select_clause || ' '
		|| transform_string
		|| 'as "' || methods.method_name || '"';
	
	sub_select_clause := sub_select_clause || ' ' ||
	  'left join (select x.measurement as x, y.measurement as y, sc.physical_sample_id as sample
		from 
		tbl_sample_coordinates sc
		join tbl_coordinate_method_dimensions cmd
		on cmd.coordinate_method_dimension_id = sc.coordinate_method_dimension_id
		join
		(select 
		sc.physical_sample_id as id,
		sc.measurement as measurement,
		cmd.method_id as method_id 
		from tbl_sample_coordinates sc
		join tbl_coordinate_method_dimensions cmd
		on sc.coordinate_method_dimension_id = cmd.coordinate_method_dimension_id
		join tbl_dimensions d
		on d.dimension_id = cmd.dimension_id
		where d.dimension_name like ''Y%'') as y
		on y.id = sc.physical_sample_id
		and y.method_id = cmd.method_id

		join
		(select 
		sc.physical_sample_id as id,
		sc.measurement as measurement,
		cmd.method_id as method_id 
		from tbl_sample_coordinates sc
		join tbl_coordinate_method_dimensions cmd
		on sc.coordinate_method_dimension_id = cmd.coordinate_method_dimension_id
		join tbl_dimensions d
		on d.dimension_id = cmd.dimension_id
		where d.dimension_name like ''X%'') as x
		on x.id = sc.physical_sample_id
		and x.method_id = cmd.method_id

		where cmd.method_id = ' || methods.method_id || 
		') as ' || normalized_method_name ||
		' on ' || normalized_method_name || '.sample = sc.physical_sample_id';
		
	end loop;
	select_clause :=
		'select sc.physical_sample_id, '
		||select_clause || ' from tbl_sample_coordinates sc '
		|| sub_select_clause;
	raise info '%', select_clause;
end;$$;


--
-- Name: get_transform_string(character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_transform_string(method_name character varying, target_srid integer DEFAULT 4326) RETURNS text
    LANGUAGE plpgsql
    AS $$
declare
   srid		integer := -1;
   n_adj	integer := 0;
   e_adj	integer := 0;
   result_string text := '';
begin
   case
	when method_name = 'WGS84_UTM_zone_32' then
	  srid := 32632;
	when method_name = 'EPSG:4326' then 
	  srid := 4326;
	when method_name = 'UTM_U32_euref89' then
	  srid := 4647;
	when method_name = 'Swedish_RT90[2.5_gon_V]' then
	  srid := 3021;
	when method_name = 'RT90_5_gon_V' then 
	  srid := 3020;
	when method_name = 'SWEREF_99_TM_(Swedish)' then 
	  srid := 3006;
	when method_name = 'Truncated_RT90_5_gon_V_(6M,_1M_adjustment)' then
	  srid := 3020;
	  n_adj := 6000000;
	  e_adj := 1000000;
	when method_name = 'WGS84_UTM_zone_33N' then
	  srid := 32633;
	else
	  raise warning 'no matching coordinate method id found for method %', method_name;
	  return '-1';
   end case;

	result_string :=
		'st_transform(st_setsrid(st_point('
		|| method_name || '.y + ' || n_adj || ',' 
		|| method_name || '.x + ' || e_adj
		|| '), '
		|| srid
		|| '), ' 
		|| target_srid
		|| ')';
	return result_string;
		
   
end;
$$;


--
-- Name: requiredtablestructurechanges(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION requiredtablestructurechanges() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	ALTER TABLE tbl_bugs_tsite ALTER COLUMN "Country" TYPE character varying(255);
	Perform BugsTransferLog('tbl_bugs_tsite', 'U', 'alter table, alter column "Country" type character varying(255)');

	Perform NumericifyColumn(
		t_name :=    'tbl_bugs_tspeciesassociations', 
		col_name :=  'CODE');
	Perform NumericifyColumn(
		t_name :=    'tbl_bugs_tspeciesassociations', 
		col_name :=  'AssociatedSpeciesCODE');
	Perform NumericifyColumn(
		t_name :=    'tbl_bugs_tecodefbugs', 
		col_name :=  'SortOrder',
		numeric_type := 'smallint');
	Perform NumericifyColumn(
		t_name :=    'tbl_bugs_tecobugs', 
		col_name :=  'CODE');
	Perform NumericifyColumn(
		t_name :=    'tbl_bugs_tecokoch', 
		col_name :=  'CODE');
	Perform NumericifyColumn(
		t_name :=    'tbl_bugs_tseasonactiveadult', 
		col_name :=  'CODE');
	Perform NumericifyColumn(
		t_name :=    'tbl_bugs_tperiods', 
		col_name :=  'Begin');
	Perform NumericifyColumn(
		t_name :=    'tbl_bugs_tperiods', 
		col_name :=  'End');		
END;
$$;


--
-- Name: smallbiblioupdates(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION smallbiblioupdates() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	cnt_Lott2010 integer := -1;
BEGIN
	select count(*) from tbl_bugs_tbiblio 
		where "REFERENCE" like 'Lott 2010%'
		into cnt_Lott2010;
	if cnt_Lott2010 = 1 then
		-- small fix to handle the current state of 
		-- bugs, this should be ineffective after 
		-- fixes in original data.
		update tbl_bugs_tbiblio
		set "REFERENCE" = 'Lott 2010'
		where "REFERENCE" = 'Lott 2010a';
	end if;
END;
$$;


--
-- Name: syncsequences(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION syncsequences() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	sql record;
BEGIN
	FOR sql in SELECT 'SELECT SETVAL(' ||
				quote_literal(quote_ident(PGT.schemaname)|| 
				'.'||quote_ident(S.relname))|| 
				', MAX(' ||quote_ident(C.attname)|| 
				') ) FROM ' ||
				quote_ident(PGT.schemaname)|| '.'||quote_ident(T.relname)|| ';' as fix_query
			FROM pg_class AS S, pg_depend AS D, pg_class AS T, pg_attribute AS C, pg_tables AS PGT
			WHERE S.relkind = 'S'
			    AND S.oid = D.objid
			    AND D.refobjid = T.oid
			    AND D.refobjid = C.attrelid
			    AND D.refobjsubid = C.attnum
			    AND T.relname = PGT.tablename
			ORDER BY S.relname LOOP
		EXECUTE sql.fix_query;
	END LOOP;	
END;
$$;


SET search_path = clearing_house, pg_catalog;

SET default_with_oids = false;

--
-- Name: tbl_abundance_elements; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_abundance_elements (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    abundance_element_id integer NOT NULL,
    record_type_id integer,
    element_name character varying(100) NOT NULL,
    element_description text,
    date_updated timestamp with time zone
);


--
-- Name: tbl_abundance_ident_levels; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_abundance_ident_levels (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    abundance_ident_level_id integer NOT NULL,
    abundance_id integer NOT NULL,
    identification_level_id integer NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_abundance_modifications; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_abundance_modifications (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    abundance_modification_id integer NOT NULL,
    abundance_id integer NOT NULL,
    modification_type_id integer NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_abundances; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_abundances (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    abundance_id integer NOT NULL,
    taxon_id integer NOT NULL,
    analysis_entity_id integer NOT NULL,
    abundance_element_id integer,
    abundance integer NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_activity_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_activity_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    activity_type_id integer NOT NULL,
    activity_type character varying(50),
    description text,
    date_updated timestamp with time zone
);


--
-- Name: tbl_aggregate_datasets; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_aggregate_datasets (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    aggregate_dataset_id integer NOT NULL,
    aggregate_order_type_id integer NOT NULL,
    biblio_id integer,
    aggregate_dataset_name character varying(255),
    date_updated timestamp with time zone,
    description text
);


--
-- Name: tbl_aggregate_order_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_aggregate_order_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    aggregate_order_type_id integer NOT NULL,
    aggregate_order_type character varying(60) NOT NULL,
    date_updated timestamp with time zone,
    description text
);


--
-- Name: tbl_aggregate_sample_ages; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_aggregate_sample_ages (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    aggregate_sample_age_id integer NOT NULL,
    aggregate_dataset_id integer NOT NULL,
    analysis_entity_age_id integer NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_aggregate_samples; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_aggregate_samples (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    aggregate_sample_id integer NOT NULL,
    aggregate_dataset_id integer NOT NULL,
    analysis_entity_id integer NOT NULL,
    aggregate_sample_name character varying(50),
    date_updated timestamp with time zone
);


--
-- Name: tbl_alt_ref_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_alt_ref_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    alt_ref_type_id integer NOT NULL,
    alt_ref_type character varying(50) NOT NULL,
    date_updated timestamp with time zone,
    description text
);


--
-- Name: tbl_analysis_entities; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_analysis_entities (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    analysis_entity_id integer NOT NULL,
    physical_sample_id integer,
    dataset_id integer,
    date_updated timestamp with time zone
);


--
-- Name: tbl_analysis_entity_ages; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_analysis_entity_ages (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    analysis_entity_age_id integer NOT NULL,
    age numeric(20,10) NOT NULL,
    age_older numeric(15,5),
    age_younger numeric(15,5),
    analysis_entity_id integer,
    chronology_id integer,
    date_updated timestamp with time zone
);


--
-- Name: tbl_analysis_entity_dimensions; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_analysis_entity_dimensions (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    analysis_entity_dimension_id integer NOT NULL,
    analysis_entity_id integer NOT NULL,
    dimension_id integer NOT NULL,
    dimension_value numeric NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_analysis_entity_prep_methods; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_analysis_entity_prep_methods (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    analysis_entity_prep_method_id integer NOT NULL,
    analysis_entity_id integer NOT NULL,
    method_id integer NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_biblio; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_biblio (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    biblio_id integer NOT NULL,
    author character varying(255),
    biblio_keyword_id integer,
    bugs_author character varying(255),
    bugs_biblio_id integer,
    bugs_reference character varying(60),
    bugs_title character varying(255),
    collection_or_journal_id integer,
    date_updated timestamp with time zone,
    doi character varying(255),
    edition character varying(128),
    isbn character varying(128),
    keywords character varying(255),
    notes text,
    number character varying(128),
    pages character varying(50),
    pdf_link character varying(255),
    publication_type_id integer,
    publisher_id integer,
    title character varying(255),
    volume character varying(128),
    year character varying(255)
);


--
-- Name: tbl_biblio_keywords; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_biblio_keywords (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    biblio_keyword_id integer NOT NULL,
    biblio_id integer NOT NULL,
    date_updated timestamp with time zone,
    keyword_id integer NOT NULL
);


--
-- Name: tbl_bugs_abundance_codes; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_bugs_abundance_codes (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    bugs_abundance_code_id integer NOT NULL,
    abundance_id integer,
    bugs_fossilbugscode character varying(10),
    bugs_samplecode character varying(10),
    date_updated timestamp with time zone
);


--
-- Name: tbl_bugs_biblio; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_bugs_biblio (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    bugs_biblio_id integer NOT NULL,
    biblio_id integer NOT NULL,
    bugs_reference character varying(255) NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_bugs_dates_calendar; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_bugs_dates_calendar (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    bugs_dates_calendar_id integer NOT NULL,
    relative_date_id integer NOT NULL,
    date_updated timestamp with time zone,
    bugs_calendarcode character varying(255) NOT NULL,
    bugs_samplecode character varying(255)
);


--
-- Name: tbl_bugs_dates_period; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_bugs_dates_period (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    bugs_dates_period_id integer NOT NULL,
    relative_date_id integer NOT NULL,
    bugs_perioddatecode character varying(255) NOT NULL,
    date_updated timestamp with time zone,
    bugs_samplecode character varying(255)
);


--
-- Name: tbl_bugs_dates_radio; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_bugs_dates_radio (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    bugs_dates_radio_id integer NOT NULL,
    bugs_datecode character varying(255) NOT NULL,
    date_updated timestamp with time zone,
    geochron_id integer NOT NULL,
    bugs_samplecode character varying(255),
    bugs_materialtype text
);


--
-- Name: tbl_bugs_datesmethods; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_bugs_datesmethods (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    bugs_datesmethods_id integer NOT NULL,
    method_id integer,
    bugs_abbrev character varying(255),
    bugs_method character varying(255),
    date_updated timestamp with time zone
);


--
-- Name: tbl_bugs_periods; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_bugs_periods (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    bugs_dates_relative_id integer NOT NULL,
    bugs_periodcode character varying(255) NOT NULL,
    date_updated timestamp with time zone,
    relative_age_id integer NOT NULL
);


--
-- Name: tbl_bugs_physical_samples; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_bugs_physical_samples (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    bugs_physical_sample_id integer NOT NULL,
    physical_sample_id integer NOT NULL,
    bugs_samplecode character varying(10),
    date_updated timestamp with time zone
);


--
-- Name: tbl_bugs_sample_groups; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_bugs_sample_groups (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    bugs_sample_group_id integer NOT NULL,
    sample_group_id integer NOT NULL,
    bugs_countsheetcode character varying(10),
    date_updated timestamp with time zone
);


--
-- Name: tbl_bugs_sites; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_bugs_sites (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    bugs_sites_id integer NOT NULL,
    site_id integer NOT NULL,
    bugs_sitecode character varying(10),
    date_updated timestamp with time zone
);


--
-- Name: tbl_ceramics; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_ceramics (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    ceramics_id integer NOT NULL,
    analysis_entity_id integer NOT NULL,
    ceramics_measurement_id integer NOT NULL,
    measurement_value character varying(255) NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_ceramics_measurement_lookup; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_ceramics_measurement_lookup (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    ceramics_measurement_lookup_id integer NOT NULL,
    ceramics_measurement_id integer NOT NULL,
    value character varying(255) NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_ceramics_measurements; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_ceramics_measurements (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    ceramics_measurement_id integer NOT NULL,
    date_updated timestamp with time zone,
    method_id integer
);


--
-- Name: tbl_chron_control_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_chron_control_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    chron_control_type_id integer NOT NULL,
    chron_control_type character varying(50),
    date_updated timestamp with time zone
);


--
-- Name: tbl_chron_controls; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_chron_controls (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    chron_control_id integer NOT NULL,
    age numeric(20,5),
    age_limit_older numeric(20,5),
    age_limit_younger numeric(20,5),
    chron_control_type_id integer,
    chronology_id integer NOT NULL,
    date_updated timestamp with time zone,
    depth_bottom numeric(20,5),
    depth_top numeric(20,5),
    notes text
);


--
-- Name: tbl_chronologies; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_chronologies (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    chronology_id integer NOT NULL,
    age_bound_older integer,
    age_bound_younger integer,
    age_model character varying(80),
    age_type_id integer NOT NULL,
    chronology_name character varying(80),
    contact_id integer,
    date_prepared timestamp without time zone,
    date_updated timestamp with time zone,
    is_default boolean NOT NULL,
    notes text,
    sample_group_id integer NOT NULL
);


--
-- Name: tbl_clearinghouse_accepted_submissions; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_accepted_submissions (
    accepted_submission_id integer NOT NULL,
    process_state_id boolean NOT NULL,
    submission_id integer,
    upload_file text,
    accept_user_id integer
);


--
-- Name: tbl_clearinghouse_accepted_submissio_accepted_submission_id_seq; Type: SEQUENCE; Schema: clearing_house; Owner: -
--

CREATE SEQUENCE tbl_clearinghouse_accepted_submissio_accepted_submission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_clearinghouse_accepted_submissio_accepted_submission_id_seq; Type: SEQUENCE OWNED BY; Schema: clearing_house; Owner: -
--

ALTER SEQUENCE tbl_clearinghouse_accepted_submissio_accepted_submission_id_seq OWNED BY tbl_clearinghouse_accepted_submissions.accepted_submission_id;


--
-- Name: tbl_clearinghouse_activity_log; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_activity_log (
    activity_log_id integer NOT NULL,
    use_case_id integer DEFAULT 0 NOT NULL,
    user_id integer DEFAULT 0 NOT NULL,
    session_id integer DEFAULT 0 NOT NULL,
    entity_type_id integer DEFAULT 0 NOT NULL,
    entity_id integer DEFAULT 0 NOT NULL,
    execute_start_time date NOT NULL,
    execute_stop_time date,
    status_id integer DEFAULT 0 NOT NULL,
    activity_data text,
    message text DEFAULT ''::text NOT NULL
);


--
-- Name: tbl_clearinghouse_activity_log_activity_log_id_seq; Type: SEQUENCE; Schema: clearing_house; Owner: -
--

CREATE SEQUENCE tbl_clearinghouse_activity_log_activity_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_clearinghouse_activity_log_activity_log_id_seq; Type: SEQUENCE OWNED BY; Schema: clearing_house; Owner: -
--

ALTER SEQUENCE tbl_clearinghouse_activity_log_activity_log_id_seq OWNED BY tbl_clearinghouse_activity_log.activity_log_id;


--
-- Name: tbl_clearinghouse_data_provider_grades; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_data_provider_grades (
    grade_id integer NOT NULL,
    description character varying(255) NOT NULL
);


--
-- Name: tbl_clearinghouse_info_references; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_info_references (
    info_reference_id integer NOT NULL,
    info_reference_type character varying(255) NOT NULL,
    display_name character varying(255) NOT NULL,
    href character varying(255)
);


--
-- Name: tbl_clearinghouse_info_references_info_reference_id_seq; Type: SEQUENCE; Schema: clearing_house; Owner: -
--

CREATE SEQUENCE tbl_clearinghouse_info_references_info_reference_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_clearinghouse_info_references_info_reference_id_seq; Type: SEQUENCE OWNED BY; Schema: clearing_house; Owner: -
--

ALTER SEQUENCE tbl_clearinghouse_info_references_info_reference_id_seq OWNED BY tbl_clearinghouse_info_references.info_reference_id;


--
-- Name: tbl_clearinghouse_reject_entity_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_reject_entity_types (
    entity_type_id integer NOT NULL,
    table_id integer,
    entity_type character varying(255) NOT NULL
);


--
-- Name: tbl_clearinghouse_reports; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_reports (
    report_id integer NOT NULL,
    report_name character varying(255),
    report_procedure text NOT NULL
);


--
-- Name: tbl_clearinghouse_sead_create_table_log; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_sead_create_table_log (
    create_script text,
    drop_script text
);


--
-- Name: tbl_clearinghouse_sead_create_view_log; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_sead_create_view_log (
    create_script text,
    drop_script text
);


--
-- Name: tbl_clearinghouse_sead_rdb_schema; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_sead_rdb_schema (
    table_schema character varying(255) NOT NULL,
    table_name character varying(255) NOT NULL,
    column_name character varying(255) NOT NULL,
    ordinal_position integer NOT NULL,
    data_type character varying(255) NOT NULL,
    numeric_precision integer,
    numeric_scale integer,
    character_maximum_length integer,
    is_nullable character varying(10) NOT NULL,
    is_pk character varying(10) NOT NULL
);


--
-- Name: tbl_clearinghouse_sessions; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_sessions (
    session_id integer NOT NULL,
    user_id integer DEFAULT 0 NOT NULL,
    ip character varying(255),
    start_time date NOT NULL,
    stop_time date
);


--
-- Name: tbl_clearinghouse_sessions_session_id_seq; Type: SEQUENCE; Schema: clearing_house; Owner: -
--

CREATE SEQUENCE tbl_clearinghouse_sessions_session_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_clearinghouse_sessions_session_id_seq; Type: SEQUENCE OWNED BY; Schema: clearing_house; Owner: -
--

ALTER SEQUENCE tbl_clearinghouse_sessions_session_id_seq OWNED BY tbl_clearinghouse_sessions.session_id;


--
-- Name: tbl_clearinghouse_settings; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_settings (
    setting_id integer NOT NULL,
    setting_group character varying(255) NOT NULL,
    setting_key character varying(255) NOT NULL,
    setting_value text NOT NULL,
    setting_datatype text NOT NULL
);


--
-- Name: tbl_clearinghouse_settings_setting_id_seq; Type: SEQUENCE; Schema: clearing_house; Owner: -
--

CREATE SEQUENCE tbl_clearinghouse_settings_setting_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_clearinghouse_settings_setting_id_seq; Type: SEQUENCE OWNED BY; Schema: clearing_house; Owner: -
--

ALTER SEQUENCE tbl_clearinghouse_settings_setting_id_seq OWNED BY tbl_clearinghouse_settings.setting_id;


--
-- Name: tbl_clearinghouse_signal_log; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_signal_log (
    signal_log_id integer NOT NULL,
    use_case_id integer NOT NULL,
    signal_time date NOT NULL,
    email text NOT NULL,
    cc text NOT NULL,
    subject text NOT NULL,
    body text NOT NULL
);


--
-- Name: tbl_clearinghouse_signal_log_signal_log_id_seq; Type: SEQUENCE; Schema: clearing_house; Owner: -
--

CREATE SEQUENCE tbl_clearinghouse_signal_log_signal_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_clearinghouse_signal_log_signal_log_id_seq; Type: SEQUENCE OWNED BY; Schema: clearing_house; Owner: -
--

ALTER SEQUENCE tbl_clearinghouse_signal_log_signal_log_id_seq OWNED BY tbl_clearinghouse_signal_log.signal_log_id;


--
-- Name: tbl_clearinghouse_signals; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_signals (
    signal_id integer NOT NULL,
    use_case_id integer DEFAULT 0 NOT NULL,
    recipient_user_id integer DEFAULT 0 NOT NULL,
    recipient_address text NOT NULL,
    signal_time date NOT NULL,
    subject text,
    body text,
    status text
);


--
-- Name: tbl_clearinghouse_signals_signal_id_seq; Type: SEQUENCE; Schema: clearing_house; Owner: -
--

CREATE SEQUENCE tbl_clearinghouse_signals_signal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_clearinghouse_signals_signal_id_seq; Type: SEQUENCE OWNED BY; Schema: clearing_house; Owner: -
--

ALTER SEQUENCE tbl_clearinghouse_signals_signal_id_seq OWNED BY tbl_clearinghouse_signals.signal_id;


--
-- Name: tbl_clearinghouse_submission_reject_entities; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_submission_reject_entities (
    reject_entity_id integer NOT NULL,
    submission_reject_id integer NOT NULL,
    local_db_id integer NOT NULL
);


--
-- Name: tbl_clearinghouse_submission_reject_entiti_reject_entity_id_seq; Type: SEQUENCE; Schema: clearing_house; Owner: -
--

CREATE SEQUENCE tbl_clearinghouse_submission_reject_entiti_reject_entity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_clearinghouse_submission_reject_entiti_reject_entity_id_seq; Type: SEQUENCE OWNED BY; Schema: clearing_house; Owner: -
--

ALTER SEQUENCE tbl_clearinghouse_submission_reject_entiti_reject_entity_id_seq OWNED BY tbl_clearinghouse_submission_reject_entities.reject_entity_id;


--
-- Name: tbl_clearinghouse_submission_rejects; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_submission_rejects (
    submission_reject_id integer NOT NULL,
    submission_id integer NOT NULL,
    site_id integer DEFAULT 0 NOT NULL,
    entity_type_id integer NOT NULL,
    reject_scope_id integer NOT NULL,
    reject_description text
);


--
-- Name: tbl_clearinghouse_submission_rejects_submission_reject_id_seq; Type: SEQUENCE; Schema: clearing_house; Owner: -
--

CREATE SEQUENCE tbl_clearinghouse_submission_rejects_submission_reject_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_clearinghouse_submission_rejects_submission_reject_id_seq; Type: SEQUENCE OWNED BY; Schema: clearing_house; Owner: -
--

ALTER SEQUENCE tbl_clearinghouse_submission_rejects_submission_reject_id_seq OWNED BY tbl_clearinghouse_submission_rejects.submission_reject_id;


--
-- Name: tbl_clearinghouse_submission_states; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_submission_states (
    submission_state_id integer NOT NULL,
    submission_state_name character varying(255) NOT NULL
);


--
-- Name: tbl_clearinghouse_submission_tables; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_submission_tables (
    table_id integer NOT NULL,
    table_name character varying(255) NOT NULL,
    table_name_underscored character varying(255) NOT NULL
);


--
-- Name: tbl_clearinghouse_submission_tables_table_id_seq; Type: SEQUENCE; Schema: clearing_house; Owner: -
--

CREATE SEQUENCE tbl_clearinghouse_submission_tables_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_clearinghouse_submission_tables_table_id_seq; Type: SEQUENCE OWNED BY; Schema: clearing_house; Owner: -
--

ALTER SEQUENCE tbl_clearinghouse_submission_tables_table_id_seq OWNED BY tbl_clearinghouse_submission_tables.table_id;


--
-- Name: tbl_clearinghouse_submission_xml_content_columns; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_submission_xml_content_columns (
    column_id integer NOT NULL,
    submission_id integer NOT NULL,
    table_id integer NOT NULL,
    column_name character varying(255) NOT NULL,
    column_name_underscored character varying(255) NOT NULL,
    data_type character varying(255) NOT NULL,
    fk_flag boolean NOT NULL,
    fk_table character varying(255),
    fk_table_underscored character varying(255)
);


--
-- Name: tbl_clearinghouse_submission_xml_content_columns_column_id_seq; Type: SEQUENCE; Schema: clearing_house; Owner: -
--

CREATE SEQUENCE tbl_clearinghouse_submission_xml_content_columns_column_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_clearinghouse_submission_xml_content_columns_column_id_seq; Type: SEQUENCE OWNED BY; Schema: clearing_house; Owner: -
--

ALTER SEQUENCE tbl_clearinghouse_submission_xml_content_columns_column_id_seq OWNED BY tbl_clearinghouse_submission_xml_content_columns.column_id;


--
-- Name: tbl_clearinghouse_submission_xml_content_records; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_submission_xml_content_records (
    record_id integer NOT NULL,
    submission_id integer NOT NULL,
    table_id integer NOT NULL,
    local_db_id integer,
    public_db_id integer
);


--
-- Name: tbl_clearinghouse_submission_xml_content_records_record_id_seq; Type: SEQUENCE; Schema: clearing_house; Owner: -
--

CREATE SEQUENCE tbl_clearinghouse_submission_xml_content_records_record_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_clearinghouse_submission_xml_content_records_record_id_seq; Type: SEQUENCE OWNED BY; Schema: clearing_house; Owner: -
--

ALTER SEQUENCE tbl_clearinghouse_submission_xml_content_records_record_id_seq OWNED BY tbl_clearinghouse_submission_xml_content_records.record_id;


--
-- Name: tbl_clearinghouse_submission_xml_content_tables; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_submission_xml_content_tables (
    content_table_id integer NOT NULL,
    submission_id integer NOT NULL,
    table_id integer NOT NULL,
    record_count integer NOT NULL
);


--
-- Name: tbl_clearinghouse_submission_xml_content_t_content_table_id_seq; Type: SEQUENCE; Schema: clearing_house; Owner: -
--

CREATE SEQUENCE tbl_clearinghouse_submission_xml_content_t_content_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_clearinghouse_submission_xml_content_t_content_table_id_seq; Type: SEQUENCE OWNED BY; Schema: clearing_house; Owner: -
--

ALTER SEQUENCE tbl_clearinghouse_submission_xml_content_t_content_table_id_seq OWNED BY tbl_clearinghouse_submission_xml_content_tables.content_table_id;


--
-- Name: tbl_clearinghouse_submission_xml_content_values; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_submission_xml_content_values (
    value_id integer NOT NULL,
    submission_id integer NOT NULL,
    table_id integer NOT NULL,
    local_db_id integer NOT NULL,
    column_id integer NOT NULL,
    fk_flag boolean,
    fk_local_db_id integer,
    fk_public_db_id integer,
    value text
);


--
-- Name: tbl_clearinghouse_submission_xml_content_values_value_id_seq; Type: SEQUENCE; Schema: clearing_house; Owner: -
--

CREATE SEQUENCE tbl_clearinghouse_submission_xml_content_values_value_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_clearinghouse_submission_xml_content_values_value_id_seq; Type: SEQUENCE OWNED BY; Schema: clearing_house; Owner: -
--

ALTER SEQUENCE tbl_clearinghouse_submission_xml_content_values_value_id_seq OWNED BY tbl_clearinghouse_submission_xml_content_values.value_id;


--
-- Name: tbl_clearinghouse_submissions; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_submissions (
    submission_id integer NOT NULL,
    submission_state_id integer NOT NULL,
    data_types character varying(255),
    upload_user_id integer NOT NULL,
    upload_date date DEFAULT now() NOT NULL,
    upload_content text,
    xml xml,
    status_text text,
    claim_user_id integer,
    claim_date_time date
);


--
-- Name: tbl_clearinghouse_submissions_submission_id_seq; Type: SEQUENCE; Schema: clearing_house; Owner: -
--

CREATE SEQUENCE tbl_clearinghouse_submissions_submission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_clearinghouse_submissions_submission_id_seq; Type: SEQUENCE OWNED BY; Schema: clearing_house; Owner: -
--

ALTER SEQUENCE tbl_clearinghouse_submissions_submission_id_seq OWNED BY tbl_clearinghouse_submissions.submission_id;


--
-- Name: tbl_clearinghouse_use_cases; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_use_cases (
    use_case_id integer NOT NULL,
    use_case_name character varying(255) NOT NULL,
    entity_type_id integer DEFAULT 0 NOT NULL
);


--
-- Name: tbl_clearinghouse_user_roles; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_user_roles (
    role_id integer NOT NULL,
    role_name character varying(255) NOT NULL
);


--
-- Name: tbl_clearinghouse_users; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_clearinghouse_users (
    user_id integer NOT NULL,
    user_name character varying(255) NOT NULL,
    full_name character varying(255) DEFAULT ''::character varying NOT NULL,
    password character varying(255) NOT NULL,
    email character varying(1024) DEFAULT ''::character varying NOT NULL,
    signal_receiver boolean DEFAULT false NOT NULL,
    role_id integer DEFAULT 1 NOT NULL,
    data_provider_grade_id integer DEFAULT 2 NOT NULL,
    is_data_provider boolean DEFAULT false NOT NULL,
    create_date date NOT NULL
);


--
-- Name: tbl_clearinghouse_users_user_id_seq; Type: SEQUENCE; Schema: clearing_house; Owner: -
--

CREATE SEQUENCE tbl_clearinghouse_users_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_clearinghouse_users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: clearing_house; Owner: -
--

ALTER SEQUENCE tbl_clearinghouse_users_user_id_seq OWNED BY tbl_clearinghouse_users.user_id;


--
-- Name: tbl_collections_or_journals; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_collections_or_journals (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    collection_or_journal_id integer NOT NULL,
    collection_or_journal_abbrev character varying(128),
    collection_title_or_journal_name character varying(255),
    date_updated timestamp with time zone,
    issn character varying(128),
    number_of_volumes character varying(50),
    publisher_id integer,
    series_editor character varying(255),
    series_title character varying(255),
    volume_editor character varying(255)
);


--
-- Name: tbl_colours; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_colours (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    colour_id integer NOT NULL,
    colour_name character varying(30) NOT NULL,
    date_updated timestamp with time zone,
    method_id integer NOT NULL,
    rgb integer
);


--
-- Name: tbl_contact_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_contact_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    contact_type_id integer NOT NULL,
    contact_type_name character varying(150) NOT NULL,
    date_updated timestamp with time zone,
    description text
);


--
-- Name: tbl_contacts; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_contacts (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    contact_id integer NOT NULL,
    address_1 character varying(255),
    address_2 character varying(255),
    location_id integer,
    email character varying(255),
    first_name character varying(50),
    last_name character varying(100),
    phone_number character varying(50),
    url text,
    date_updated timestamp with time zone
);


--
-- Name: tbl_coordinate_method_dimensions; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_coordinate_method_dimensions (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    coordinate_method_dimension_id integer NOT NULL,
    dimension_id integer NOT NULL,
    method_id integer NOT NULL,
    limit_upper numeric(18,10),
    limit_lower numeric(18,10),
    date_updated timestamp with time zone
);


--
-- Name: tbl_data_type_groups; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_data_type_groups (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    data_type_group_id integer NOT NULL,
    data_type_group_name character varying(25),
    date_updated timestamp with time zone,
    description text
);


--
-- Name: tbl_data_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_data_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    data_type_id integer NOT NULL,
    data_type_group_id integer NOT NULL,
    data_type_name character varying(25),
    date_updated timestamp with time zone,
    definition text
);


--
-- Name: tbl_dataset_contacts; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_dataset_contacts (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    dataset_contact_id integer NOT NULL,
    contact_id integer NOT NULL,
    contact_type_id integer NOT NULL,
    dataset_id integer NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_dataset_masters; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_dataset_masters (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    master_set_id integer NOT NULL,
    contact_id integer,
    biblio_id integer,
    master_name character varying(100),
    master_notes text,
    url text,
    date_updated timestamp with time zone
);


--
-- Name: tbl_dataset_submission_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_dataset_submission_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    submission_type_id integer NOT NULL,
    submission_type character varying(60) NOT NULL,
    description text,
    date_updated timestamp with time zone
);


--
-- Name: tbl_dataset_submissions; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_dataset_submissions (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    dataset_submission_id integer NOT NULL,
    dataset_id integer NOT NULL,
    submission_type_id integer NOT NULL,
    contact_id integer NOT NULL,
    date_submitted date NOT NULL,
    notes text,
    date_updated timestamp with time zone
);


--
-- Name: tbl_datasets; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_datasets (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    dataset_id integer NOT NULL,
    master_set_id integer,
    data_type_id integer NOT NULL,
    method_id integer,
    biblio_id integer,
    updated_dataset_id integer,
    project_id integer,
    dataset_name character varying(50) NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_dating_labs; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_dating_labs (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    dating_lab_id integer NOT NULL,
    contact_id integer,
    international_lab_id character varying(10) NOT NULL,
    lab_name character varying(100),
    country_id integer,
    date_updated timestamp with time zone
);


--
-- Name: tbl_dating_material; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_dating_material (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    dating_material_id integer NOT NULL,
    geochron_id integer NOT NULL,
    taxon_id integer,
    material_dated character varying(255),
    description text,
    abundance_element_id integer,
    date_updated timestamp with time zone
);


--
-- Name: tbl_dating_uncertainty; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_dating_uncertainty (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    dating_uncertainty_id integer NOT NULL,
    date_updated timestamp with time zone,
    description text,
    uncertainty character varying(255)
);


--
-- Name: tbl_dendro; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_dendro (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    dendro_id integer NOT NULL,
    analysis_entity_id integer NOT NULL,
    dendro_measurement_id integer NOT NULL,
    measurement_value character varying(255) NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_dendro_date_notes; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_dendro_date_notes (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    dendro_date_note_id integer NOT NULL,
    dendro_date_id integer NOT NULL,
    note text,
    date_updated timestamp with time zone
);


--
-- Name: tbl_dendro_dates; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_dendro_dates (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    dendro_date_id integer NOT NULL,
    analysis_entity_id integer NOT NULL,
    cal_age_younger integer,
    dating_uncertainty_id integer,
    years_type_id integer,
    error integer,
    season_or_qualifier_id integer,
    date_updated timestamp with time zone,
    cal_age_older integer
);


--
-- Name: tbl_dendro_measurement_lookup; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_dendro_measurement_lookup (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    dendro_measurement_lookup_id integer NOT NULL,
    dendro_measurement_id integer NOT NULL,
    value character varying(255) NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_dendro_measurements; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_dendro_measurements (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    dendro_measurement_id integer NOT NULL,
    date_updated timestamp with time zone,
    method_id integer
);


--
-- Name: tbl_dimensions; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_dimensions (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    dimension_id integer NOT NULL,
    date_updated timestamp with time zone,
    dimension_abbrev character varying(10),
    dimension_description text,
    dimension_name character varying(50) NOT NULL,
    unit_id integer,
    method_group_id integer
);


--
-- Name: tbl_ecocode_definitions; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_ecocode_definitions (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    ecocode_definition_id integer NOT NULL,
    abbreviation character varying(10),
    date_updated timestamp with time zone,
    definition text,
    ecocode_group_id integer,
    label character varying(150),
    notes text,
    sort_order smallint
);


--
-- Name: tbl_ecocode_groups; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_ecocode_groups (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    ecocode_group_id integer NOT NULL,
    date_updated timestamp with time zone,
    definition text,
    ecocode_system_id integer,
    label character varying(150)
);


--
-- Name: tbl_ecocode_systems; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_ecocode_systems (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    ecocode_system_id integer NOT NULL,
    biblio_id integer,
    date_updated timestamp with time zone,
    definition text,
    name character varying(50),
    notes text
);


--
-- Name: tbl_ecocodes; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_ecocodes (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    ecocode_id integer NOT NULL,
    date_updated timestamp with time zone,
    ecocode_definition_id integer,
    taxon_id integer
);


--
-- Name: tbl_feature_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_feature_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    feature_type_id integer NOT NULL,
    feature_type_name character varying(128),
    feature_type_description text,
    date_updated timestamp with time zone
);


--
-- Name: tbl_features; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_features (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    feature_id integer NOT NULL,
    feature_type_id integer NOT NULL,
    feature_name character varying(255),
    feature_description text,
    date_updated timestamp with time zone
);


--
-- Name: tbl_foreign_relations; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_foreign_relations (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    source_table character varying(255) NOT NULL,
    source_column character varying(255) NOT NULL,
    target_table character varying(255) NOT NULL,
    target_column character varying(255) NOT NULL,
    weight integer,
    source_target_logic text,
    target_source_logic text
);


--
-- Name: tbl_geochron_refs; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_geochron_refs (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    geochron_ref_id integer NOT NULL,
    geochron_id integer NOT NULL,
    biblio_id integer NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_geochronology; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_geochronology (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    geochron_id integer NOT NULL,
    analysis_entity_id integer NOT NULL,
    dating_lab_id integer,
    lab_number character varying(40),
    age numeric(20,5),
    error_older numeric(20,5),
    error_younger numeric(20,5),
    delta_13c numeric(10,5),
    notes text,
    date_updated timestamp with time zone,
    dating_uncertainty_id integer
);


--
-- Name: tbl_horizons; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_horizons (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    horizon_id integer NOT NULL,
    date_updated timestamp with time zone,
    description text,
    horizon_name character varying(15) NOT NULL,
    method_id integer NOT NULL
);


--
-- Name: tbl_identification_levels; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_identification_levels (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    identification_level_id integer NOT NULL,
    identification_level_abbrev character varying(50),
    identification_level_name character varying(50),
    notes text,
    date_updated timestamp with time zone
);


--
-- Name: tbl_image_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_image_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    image_type_id integer NOT NULL,
    date_updated timestamp with time zone,
    description text,
    image_type character varying(40) NOT NULL
);


--
-- Name: tbl_imported_taxa_replacements; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_imported_taxa_replacements (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    imported_taxa_replacement_id integer NOT NULL,
    date_updated timestamp with time zone,
    imported_name_replaced character varying(100) NOT NULL,
    taxon_id integer NOT NULL
);


--
-- Name: tbl_keywords; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_keywords (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    keyword_id integer NOT NULL,
    date_updated timestamp with time zone,
    definition text,
    keyword character varying(255)
);


--
-- Name: tbl_languages; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_languages (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    language_id integer NOT NULL,
    date_updated timestamp with time zone,
    language_name_english character varying(100),
    language_name_native character varying(100)
);


--
-- Name: tbl_lithology; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_lithology (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    lithology_id integer NOT NULL,
    date_updated timestamp with time zone,
    depth_bottom numeric(20,5),
    depth_top numeric(20,5) NOT NULL,
    description text NOT NULL,
    lower_boundary character varying(255),
    sample_group_id integer NOT NULL
);


--
-- Name: tbl_location_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_location_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    location_type_id integer NOT NULL,
    date_updated timestamp with time zone,
    description text,
    location_type character varying(40)
);


--
-- Name: tbl_locations; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_locations (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    location_id integer NOT NULL,
    location_name character varying(255) NOT NULL,
    location_type_id integer NOT NULL,
    default_lat_dd numeric(18,10),
    default_long_dd numeric(18,10),
    date_updated timestamp with time zone
);


--
-- Name: tbl_mcr_names; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_mcr_names (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    taxon_id integer NOT NULL,
    comparison_notes character varying(255),
    date_updated timestamp with time zone,
    mcr_name_trim character varying(80),
    mcr_number smallint,
    mcr_species_name character varying(200)
);


--
-- Name: tbl_mcr_summary_data; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_mcr_summary_data (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    mcr_summary_data_id integer NOT NULL,
    cog_mid_tmax smallint,
    cog_mid_trange smallint,
    date_updated timestamp with time zone,
    taxon_id integer NOT NULL,
    tmax_hi smallint,
    tmax_lo smallint,
    tmin_hi smallint,
    tmin_lo smallint,
    trange_hi smallint,
    trange_lo smallint
);


--
-- Name: tbl_mcrdata_birmbeetledat; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_mcrdata_birmbeetledat (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    mcrdata_birmbeetledat_id integer NOT NULL,
    date_updated timestamp with time zone,
    mcr_data text,
    mcr_row smallint NOT NULL,
    taxon_id integer NOT NULL
);


--
-- Name: tbl_measured_value_dimensions; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_measured_value_dimensions (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    measured_value_dimension_id integer NOT NULL,
    date_updated timestamp with time zone,
    dimension_id integer NOT NULL,
    dimension_value numeric(18,10) NOT NULL,
    measured_value_id integer NOT NULL
);


--
-- Name: tbl_measured_values; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_measured_values (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    measured_value_id integer NOT NULL,
    analysis_entity_id integer NOT NULL,
    date_updated timestamp with time zone,
    measured_value numeric(20,10) NOT NULL
);


--
-- Name: tbl_method_groups; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_method_groups (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    method_group_id integer NOT NULL,
    date_updated timestamp with time zone,
    description text NOT NULL,
    group_name character varying(100) NOT NULL
);


--
-- Name: tbl_methods; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_methods (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    method_id integer NOT NULL,
    biblio_id integer,
    date_updated timestamp with time zone,
    description text NOT NULL,
    method_abbrev_or_alt_name character varying(50),
    method_group_id integer NOT NULL,
    method_name character varying(50) NOT NULL,
    record_type_id integer,
    unit_id integer
);


--
-- Name: tbl_modification_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_modification_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    modification_type_id integer NOT NULL,
    modification_type_name character varying(128),
    modification_type_description text,
    date_updated timestamp with time zone
);


--
-- Name: tbl_physical_sample_features; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_physical_sample_features (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    physical_sample_feature_id integer NOT NULL,
    date_updated timestamp with time zone,
    feature_id integer NOT NULL,
    physical_sample_id integer NOT NULL
);


--
-- Name: tbl_physical_samples; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_physical_samples (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    physical_sample_id integer NOT NULL,
    sample_group_id integer NOT NULL,
    alt_ref_type_id integer,
    sample_type_id integer NOT NULL,
    sample_name character varying(50) NOT NULL,
    date_updated timestamp with time zone,
    date_sampled character varying(255)
);


--
-- Name: tbl_project_stages; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_project_stages (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    project_stage_id integer NOT NULL,
    stage_name character varying(255),
    description text,
    date_updated timestamp with time zone
);


--
-- Name: tbl_project_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_project_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    project_type_id integer NOT NULL,
    project_type_name character varying(255),
    description text,
    date_updated timestamp with time zone
);


--
-- Name: tbl_projects; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_projects (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    project_id integer NOT NULL,
    project_type_id integer,
    project_stage_id integer,
    project_name character varying(150),
    project_abbrev_name character varying(25),
    description text,
    date_updated timestamp with time zone
);


--
-- Name: tbl_publication_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_publication_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    publication_type_id integer NOT NULL,
    date_updated timestamp with time zone,
    publication_type character varying(30)
);


--
-- Name: tbl_publishers; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_publishers (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    publisher_id integer NOT NULL,
    date_updated timestamp with time zone,
    place_of_publishing_house character varying(255),
    publisher_name character varying(255)
);


--
-- Name: tbl_radiocarbon_calibration; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_radiocarbon_calibration (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    radiocarbon_calibration_id integer NOT NULL,
    c14_yr_bp integer NOT NULL,
    cal_yr_bp integer NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_rdb; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_rdb (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    rdb_id integer NOT NULL,
    location_id integer NOT NULL,
    rdb_code_id integer,
    taxon_id integer NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_rdb_codes; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_rdb_codes (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    rdb_code_id integer NOT NULL,
    date_updated timestamp with time zone,
    rdb_category character varying(4),
    rdb_definition character varying(200),
    rdb_system_id integer
);


--
-- Name: tbl_rdb_systems; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_rdb_systems (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    rdb_system_id integer NOT NULL,
    biblio_id integer NOT NULL,
    location_id integer NOT NULL,
    rdb_first_published smallint,
    rdb_system character varying(10),
    rdb_system_date integer,
    rdb_version character varying(10),
    date_updated timestamp with time zone
);


--
-- Name: tbl_record_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_record_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    record_type_id integer NOT NULL,
    record_type_name character varying(50),
    record_type_description text,
    date_updated timestamp with time zone
);


--
-- Name: tbl_relative_age_refs; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_relative_age_refs (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    relative_age_ref_id integer NOT NULL,
    biblio_id integer NOT NULL,
    date_updated timestamp with time zone,
    relative_age_id integer NOT NULL
);


--
-- Name: tbl_relative_age_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_relative_age_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    relative_age_type_id integer NOT NULL,
    age_type character varying(255),
    description text,
    date_updated time with time zone
);


--
-- Name: tbl_relative_ages; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_relative_ages (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    relative_age_id integer NOT NULL,
    relative_age_type_id integer,
    relative_age_name character varying(50),
    description text,
    c14_age_older numeric(20,5),
    c14_age_younger numeric(20,5),
    cal_age_older numeric(20,5),
    cal_age_younger numeric(20,5),
    notes text,
    date_updated timestamp with time zone,
    location_id integer,
    abbreviation character varying(255)
);


--
-- Name: tbl_relative_dates; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_relative_dates (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    relative_date_id integer NOT NULL,
    relative_age_id integer,
    physical_sample_id integer NOT NULL,
    method_id integer,
    notes text,
    date_updated timestamp with time zone,
    dating_uncertainty_id integer
);


--
-- Name: tbl_sample_alt_refs; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_alt_refs (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_alt_ref_id integer NOT NULL,
    alt_ref character varying(40) NOT NULL,
    alt_ref_type_id integer NOT NULL,
    date_updated timestamp with time zone,
    physical_sample_id integer NOT NULL
);


--
-- Name: tbl_sample_colours; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_colours (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_colour_id integer NOT NULL,
    colour_id integer NOT NULL,
    date_updated timestamp with time zone,
    physical_sample_id integer NOT NULL
);


--
-- Name: tbl_sample_coordinates; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_coordinates (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_coordinate_id integer NOT NULL,
    physical_sample_id integer NOT NULL,
    coordinate_method_dimension_id integer NOT NULL,
    measurement numeric(20,10) NOT NULL,
    accuracy numeric(20,10),
    date_updated timestamp with time zone
);


--
-- Name: tbl_sample_description_sample_group_contexts; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_description_sample_group_contexts (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_description_sample_group_context_id integer NOT NULL,
    sampling_context_id integer,
    sample_description_type_id integer,
    date_updated timestamp with time zone
);


--
-- Name: tbl_sample_description_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_description_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_description_type_id integer NOT NULL,
    type_name character varying(255),
    type_description text,
    date_updated timestamp with time zone
);


--
-- Name: tbl_sample_descriptions; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_descriptions (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_description_id integer NOT NULL,
    sample_description_type_id integer NOT NULL,
    physical_sample_id integer NOT NULL,
    description character varying(255),
    date_updated timestamp with time zone
);


--
-- Name: tbl_sample_dimensions; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_dimensions (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_dimension_id integer NOT NULL,
    physical_sample_id integer NOT NULL,
    dimension_id integer NOT NULL,
    method_id integer NOT NULL,
    dimension_value numeric(20,10) NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_sample_group_coordinates; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_group_coordinates (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_group_position_id integer NOT NULL,
    coordinate_method_dimension_id integer NOT NULL,
    sample_group_position numeric(20,10),
    position_accuracy character varying(128),
    sample_group_id integer NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_sample_group_description_type_sampling_contexts; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_group_description_type_sampling_contexts (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_group_description_type_sampling_context_id integer NOT NULL,
    sampling_context_id integer NOT NULL,
    sample_group_description_type_id integer NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_sample_group_description_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_group_description_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_group_description_type_id integer NOT NULL,
    type_name character varying(255),
    type_description character varying(255),
    date_updated timestamp with time zone
);


--
-- Name: tbl_sample_group_descriptions; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_group_descriptions (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_group_description_id integer NOT NULL,
    group_description character varying(255),
    sample_group_description_type_id integer NOT NULL,
    date_updated timestamp with time zone,
    sample_group_id integer
);


--
-- Name: tbl_sample_group_dimensions; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_group_dimensions (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_group_dimension_id integer NOT NULL,
    date_updated timestamp with time zone,
    dimension_id integer NOT NULL,
    dimension_value numeric(20,5) NOT NULL,
    sample_group_id integer NOT NULL
);


--
-- Name: tbl_sample_group_images; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_group_images (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_group_image_id integer NOT NULL,
    date_updated timestamp with time zone,
    description text,
    image_location text NOT NULL,
    image_name character varying(80),
    image_type_id integer NOT NULL,
    sample_group_id integer NOT NULL
);


--
-- Name: tbl_sample_group_notes; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_group_notes (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_group_note_id integer NOT NULL,
    sample_group_id integer NOT NULL,
    note character varying(255),
    date_updated timestamp with time zone
);


--
-- Name: tbl_sample_group_references; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_group_references (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_group_reference_id integer NOT NULL,
    biblio_id integer NOT NULL,
    date_updated timestamp with time zone,
    sample_group_id integer
);


--
-- Name: tbl_sample_group_sampling_contexts; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_group_sampling_contexts (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sampling_context_id integer NOT NULL,
    sampling_context character varying(40) NOT NULL,
    description text,
    sort_order smallint NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_sample_groups; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_groups (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_group_id integer NOT NULL,
    site_id integer,
    sampling_context_id integer,
    method_id integer NOT NULL,
    sample_group_name character varying(100),
    sample_group_description text,
    date_updated timestamp with time zone
);


--
-- Name: tbl_sample_horizons; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_horizons (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_horizon_id integer NOT NULL,
    date_updated timestamp with time zone,
    horizon_id integer NOT NULL,
    physical_sample_id integer NOT NULL
);


--
-- Name: tbl_sample_images; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_images (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_image_id integer NOT NULL,
    date_updated timestamp with time zone,
    description text,
    image_location text NOT NULL,
    image_name character varying(80),
    image_type_id integer NOT NULL,
    physical_sample_id integer NOT NULL
);


--
-- Name: tbl_sample_location_type_sampling_contexts; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_location_type_sampling_contexts (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_location_type_sampling_context_id integer NOT NULL,
    sampling_context_id integer NOT NULL,
    sample_location_type_id integer NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_sample_location_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_location_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_location_type_id integer NOT NULL,
    location_type character varying(255),
    location_type_description text,
    date_updated timestamp with time zone
);


--
-- Name: tbl_sample_locations; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_locations (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_location_id integer NOT NULL,
    sample_location_type_id integer NOT NULL,
    physical_sample_id integer NOT NULL,
    location character varying(255),
    date_updated timestamp with time zone
);


--
-- Name: tbl_sample_notes; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_notes (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_note_id integer NOT NULL,
    physical_sample_id integer NOT NULL,
    note_type character varying(255),
    note text NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_sample_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sample_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    sample_type_id integer NOT NULL,
    type_name character varying(40) NOT NULL,
    description text,
    date_updated timestamp with time zone
);


--
-- Name: tbl_season_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_season_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    season_type_id integer NOT NULL,
    date_updated timestamp with time zone,
    description text,
    season_type character varying(30)
);


--
-- Name: tbl_seasons; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_seasons (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    season_id integer NOT NULL,
    date_updated timestamp with time zone,
    season_name character varying(20),
    season_type character varying(30),
    season_type_id integer,
    sort_order smallint
);


--
-- Name: tbl_site_images; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_site_images (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    site_image_id integer NOT NULL,
    contact_id integer,
    credit character varying(100),
    date_taken date,
    date_updated timestamp with time zone,
    description text,
    image_location text NOT NULL,
    image_name character varying(80),
    image_type_id integer NOT NULL,
    site_id integer NOT NULL
);


--
-- Name: tbl_site_locations; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_site_locations (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    site_location_id integer NOT NULL,
    date_updated timestamp with time zone,
    location_id integer NOT NULL,
    site_id integer NOT NULL
);


--
-- Name: tbl_site_natgridrefs; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_site_natgridrefs (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    site_natgridref_id integer NOT NULL,
    site_id integer NOT NULL,
    method_id integer NOT NULL,
    natgridref character varying(255) NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_site_other_records; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_site_other_records (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    site_other_records_id integer NOT NULL,
    site_id integer,
    biblio_id integer,
    record_type_id integer,
    description text,
    date_updated timestamp with time zone
);


--
-- Name: tbl_site_preservation_status; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_site_preservation_status (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    site_preservation_status_id integer NOT NULL,
    site_id integer,
    preservation_status_or_threat character varying(255),
    description text,
    assessment_type character varying(255),
    assessment_author_contact_id integer,
    date_updated timestamp with time zone,
    evaluation_date date
);


--
-- Name: tbl_site_references; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_site_references (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    site_reference_id integer NOT NULL,
    site_id integer,
    biblio_id integer NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_sites; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_sites (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    site_id integer NOT NULL,
    altitude numeric(18,10),
    latitude_dd numeric(18,10),
    longitude_dd numeric(18,10),
    national_site_identifier character varying(255),
    site_description text,
    site_name character varying(50),
    site_preservation_status_id integer,
    date_updated timestamp with time zone
);


--
-- Name: tbl_species_association_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_species_association_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    association_type_id integer NOT NULL,
    association_type_name character varying(255),
    association_description text,
    date_updated timestamp with time zone
);


--
-- Name: tbl_species_associations; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_species_associations (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    species_association_id integer NOT NULL,
    associated_taxon_id integer NOT NULL,
    biblio_id integer,
    date_updated timestamp with time zone,
    taxon_id integer NOT NULL,
    association_type_id integer,
    referencing_type text
);


--
-- Name: tbl_taxa_common_names; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_taxa_common_names (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    taxon_common_name_id integer NOT NULL,
    common_name character varying(255),
    date_updated timestamp with time zone,
    language_id integer,
    taxon_id integer
);


--
-- Name: tbl_taxa_images; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_taxa_images (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    taxa_images_id integer NOT NULL,
    image_name character varying(255),
    description text,
    image_location text,
    image_type_id integer,
    taxon_id integer NOT NULL,
    date_updated time with time zone
);


--
-- Name: tbl_taxa_measured_attributes; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_taxa_measured_attributes (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    measured_attribute_id integer NOT NULL,
    attribute_measure character varying(20),
    attribute_type character varying(25),
    attribute_units character varying(10),
    data numeric(18,10),
    date_updated timestamp with time zone,
    taxon_id integer NOT NULL
);


--
-- Name: tbl_taxa_reference_specimens; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_taxa_reference_specimens (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    taxa_reference_specimen_id integer NOT NULL,
    taxon_id integer NOT NULL,
    contact_id integer NOT NULL,
    notes text,
    date_updated time with time zone
);


--
-- Name: tbl_taxa_seasonality; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_taxa_seasonality (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    seasonality_id integer NOT NULL,
    activity_type_id integer NOT NULL,
    season_id integer,
    taxon_id integer NOT NULL,
    location_id integer NOT NULL,
    date_updated timestamp with time zone
);


--
-- Name: tbl_taxa_synonyms; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_taxa_synonyms (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    synonym_id integer NOT NULL,
    biblio_id integer NOT NULL,
    date_updated timestamp with time zone,
    family_id integer,
    genus_id integer,
    notes text,
    taxon_id integer,
    author_id integer,
    synonym character varying(255),
    reference_type character varying(255)
);


--
-- Name: tbl_taxa_tree_authors; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_taxa_tree_authors (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    author_id integer NOT NULL,
    author_name character varying(100),
    date_updated timestamp with time zone
);


--
-- Name: tbl_taxa_tree_families; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_taxa_tree_families (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    family_id integer NOT NULL,
    date_updated timestamp with time zone,
    family_name character varying(100),
    order_id integer NOT NULL
);


--
-- Name: tbl_taxa_tree_genera; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_taxa_tree_genera (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    genus_id integer NOT NULL,
    date_updated timestamp with time zone,
    family_id integer,
    genus_name character varying(100)
);


--
-- Name: tbl_taxa_tree_master; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_taxa_tree_master (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    taxon_id integer NOT NULL,
    author_id integer,
    date_updated timestamp with time zone,
    genus_id integer,
    species character varying(255)
);


--
-- Name: tbl_taxa_tree_orders; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_taxa_tree_orders (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    order_id integer NOT NULL,
    date_updated timestamp with time zone,
    order_name character varying(50),
    record_type_id integer,
    sort_order integer
);


--
-- Name: tbl_taxonomic_order; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_taxonomic_order (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    taxonomic_order_id integer NOT NULL,
    date_updated timestamp with time zone,
    taxon_id integer,
    taxonomic_code numeric(18,10),
    taxonomic_order_system_id integer
);


--
-- Name: tbl_taxonomic_order_biblio; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_taxonomic_order_biblio (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    taxonomic_order_biblio_id integer NOT NULL,
    biblio_id integer,
    date_updated timestamp with time zone,
    taxonomic_order_system_id integer
);


--
-- Name: tbl_taxonomic_order_systems; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_taxonomic_order_systems (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    taxonomic_order_system_id integer NOT NULL,
    date_updated timestamp with time zone,
    system_description text,
    system_name character varying(50)
);


--
-- Name: tbl_taxonomy_notes; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_taxonomy_notes (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    taxonomy_notes_id integer NOT NULL,
    biblio_id integer NOT NULL,
    date_updated timestamp with time zone,
    taxon_id integer NOT NULL,
    taxonomy_notes text
);


--
-- Name: tbl_tephra_dates; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_tephra_dates (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    tephra_date_id integer NOT NULL,
    analysis_entity_id integer NOT NULL,
    date_updated timestamp with time zone,
    notes text,
    tephra_id integer NOT NULL,
    dating_uncertainty_id integer
);


--
-- Name: tbl_tephra_refs; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_tephra_refs (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    tephra_ref_id integer NOT NULL,
    biblio_id integer NOT NULL,
    date_updated timestamp with time zone,
    tephra_id integer NOT NULL
);


--
-- Name: tbl_tephras; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_tephras (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    tephra_id integer NOT NULL,
    c14_age numeric(20,5),
    c14_age_older numeric(20,5),
    c14_age_younger numeric(20,5),
    cal_age numeric(20,5),
    cal_age_older numeric(20,5),
    cal_age_younger numeric(20,5),
    date_updated timestamp with time zone,
    notes text,
    tephra_name character varying(80)
);


--
-- Name: tbl_text_biology; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_text_biology (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    biology_id integer NOT NULL,
    biblio_id integer NOT NULL,
    biology_text text,
    date_updated timestamp with time zone,
    taxon_id integer NOT NULL
);


--
-- Name: tbl_text_distribution; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_text_distribution (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    distribution_id integer NOT NULL,
    biblio_id integer NOT NULL,
    date_updated timestamp with time zone,
    distribution_text text,
    taxon_id integer NOT NULL
);


--
-- Name: tbl_text_identification_keys; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_text_identification_keys (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    key_id integer NOT NULL,
    biblio_id integer NOT NULL,
    date_updated timestamp with time zone,
    key_text text,
    taxon_id integer NOT NULL
);


--
-- Name: tbl_units; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_units (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    unit_id integer NOT NULL,
    date_updated timestamp with time zone,
    description text,
    unit_abbrev character varying(15),
    unit_name character varying(50) NOT NULL
);


--
-- Name: tbl_updates_log; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_updates_log (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    updates_log_id integer NOT NULL,
    table_name character varying(150) NOT NULL,
    last_updated date NOT NULL
);


--
-- Name: tbl_view_states; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_view_states (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    view_state_id integer NOT NULL,
    view_state text,
    creatation_date timestamp with time zone,
    session_id character varying(256)
);


--
-- Name: tbl_years_types; Type: TABLE; Schema: clearing_house; Owner: -
--

CREATE TABLE tbl_years_types (
    submission_id integer NOT NULL,
    source_id integer NOT NULL,
    local_db_id integer NOT NULL,
    public_db_id integer,
    years_type_id integer NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    date_updated timestamp with time zone
);


SET search_path = public, pg_catalog;

--
-- Name: tbl_abundance_elements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_abundance_elements (
    abundance_element_id integer NOT NULL,
    record_type_id integer,
    element_name character varying(100) NOT NULL,
    element_description text,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN tbl_abundance_elements.record_type_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_abundance_elements.record_type_id IS 'used to restrict list of available elements according to record type. enables specific use of single term for multiple proxies whilst avoiding confusion, e.g. mni insects, mni seeds';


--
-- Name: COLUMN tbl_abundance_elements.element_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_abundance_elements.element_name IS 'short name for element, e.g. mni, seed, leaf';


--
-- Name: COLUMN tbl_abundance_elements.element_description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_abundance_elements.element_description IS 'explanation of short name, e.g. minimum number of individuals, base of seed grain, covering of leaf or flower bud';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_abundance_elements; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_abundance_elements AS
 SELECT tbl_abundance_elements.submission_id,
    tbl_abundance_elements.source_id,
    tbl_abundance_elements.local_db_id AS merged_db_id,
    tbl_abundance_elements.local_db_id,
    tbl_abundance_elements.public_db_id,
    tbl_abundance_elements.abundance_element_id,
    tbl_abundance_elements.record_type_id,
    tbl_abundance_elements.element_name,
    tbl_abundance_elements.element_description,
    tbl_abundance_elements.date_updated
   FROM tbl_abundance_elements
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_abundance_elements.abundance_element_id AS merged_db_id,
    0 AS local_db_id,
    tbl_abundance_elements.abundance_element_id AS public_db_id,
    tbl_abundance_elements.abundance_element_id,
    tbl_abundance_elements.record_type_id,
    tbl_abundance_elements.element_name,
    tbl_abundance_elements.element_description,
    tbl_abundance_elements.date_updated
   FROM public.tbl_abundance_elements;


SET search_path = public, pg_catalog;

--
-- Name: tbl_abundance_ident_levels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_abundance_ident_levels (
    abundance_ident_level_id integer NOT NULL,
    abundance_id integer NOT NULL,
    identification_level_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_abundance_ident_levels; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_abundance_ident_levels AS
 SELECT tbl_abundance_ident_levels.submission_id,
    tbl_abundance_ident_levels.source_id,
    tbl_abundance_ident_levels.local_db_id AS merged_db_id,
    tbl_abundance_ident_levels.local_db_id,
    tbl_abundance_ident_levels.public_db_id,
    tbl_abundance_ident_levels.abundance_ident_level_id,
    tbl_abundance_ident_levels.abundance_id,
    tbl_abundance_ident_levels.identification_level_id,
    tbl_abundance_ident_levels.date_updated
   FROM tbl_abundance_ident_levels
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_abundance_ident_levels.abundance_ident_level_id AS merged_db_id,
    0 AS local_db_id,
    tbl_abundance_ident_levels.abundance_ident_level_id AS public_db_id,
    tbl_abundance_ident_levels.abundance_ident_level_id,
    tbl_abundance_ident_levels.abundance_id,
    tbl_abundance_ident_levels.identification_level_id,
    tbl_abundance_ident_levels.date_updated
   FROM public.tbl_abundance_ident_levels;


SET search_path = public, pg_catalog;

--
-- Name: tbl_abundance_modifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_abundance_modifications (
    abundance_modification_id integer NOT NULL,
    abundance_id integer NOT NULL,
    modification_type_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_abundance_modifications; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_abundance_modifications AS
 SELECT tbl_abundance_modifications.submission_id,
    tbl_abundance_modifications.source_id,
    tbl_abundance_modifications.local_db_id AS merged_db_id,
    tbl_abundance_modifications.local_db_id,
    tbl_abundance_modifications.public_db_id,
    tbl_abundance_modifications.abundance_modification_id,
    tbl_abundance_modifications.abundance_id,
    tbl_abundance_modifications.modification_type_id,
    tbl_abundance_modifications.date_updated
   FROM tbl_abundance_modifications
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_abundance_modifications.abundance_modification_id AS merged_db_id,
    0 AS local_db_id,
    tbl_abundance_modifications.abundance_modification_id AS public_db_id,
    tbl_abundance_modifications.abundance_modification_id,
    tbl_abundance_modifications.abundance_id,
    tbl_abundance_modifications.modification_type_id,
    tbl_abundance_modifications.date_updated
   FROM public.tbl_abundance_modifications;


SET search_path = public, pg_catalog;

--
-- Name: tbl_abundances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_abundances (
    abundance_id integer NOT NULL,
    taxon_id integer NOT NULL,
    analysis_entity_id integer NOT NULL,
    abundance_element_id integer,
    abundance integer DEFAULT 0 NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE tbl_abundances; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_abundances IS '20120503pib deleted column "abundance_modification_id" as appeared superfluous with "abundance_id" in tbl_adbundance_modifications';


--
-- Name: COLUMN tbl_abundances.abundance_element_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_abundances.abundance_element_id IS 'allows recording of different parts for single taxon, e.g. leaf, seed, mni etc.';


--
-- Name: COLUMN tbl_abundances.abundance; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_abundances.abundance IS 'usually count value (abundance) but can be presence (1) or catagorical or relative scale, as defined by tbl_data_types through tbl_datasets';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_abundances; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_abundances AS
 SELECT tbl_abundances.submission_id,
    tbl_abundances.source_id,
    tbl_abundances.local_db_id AS merged_db_id,
    tbl_abundances.local_db_id,
    tbl_abundances.public_db_id,
    tbl_abundances.abundance_id,
    tbl_abundances.taxon_id,
    tbl_abundances.analysis_entity_id,
    tbl_abundances.abundance_element_id,
    tbl_abundances.abundance,
    tbl_abundances.date_updated
   FROM tbl_abundances
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_abundances.abundance_id AS merged_db_id,
    0 AS local_db_id,
    tbl_abundances.abundance_id AS public_db_id,
    tbl_abundances.abundance_id,
    tbl_abundances.taxon_id,
    tbl_abundances.analysis_entity_id,
    tbl_abundances.abundance_element_id,
    tbl_abundances.abundance,
    tbl_abundances.date_updated
   FROM public.tbl_abundances;


SET search_path = public, pg_catalog;

--
-- Name: tbl_activity_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_activity_types (
    activity_type_id integer NOT NULL,
    activity_type character varying(50) DEFAULT NULL::character varying,
    description text,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_activity_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_activity_types AS
 SELECT tbl_activity_types.submission_id,
    tbl_activity_types.source_id,
    tbl_activity_types.local_db_id AS merged_db_id,
    tbl_activity_types.local_db_id,
    tbl_activity_types.public_db_id,
    tbl_activity_types.activity_type_id,
    tbl_activity_types.activity_type,
    tbl_activity_types.description,
    tbl_activity_types.date_updated
   FROM tbl_activity_types
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_activity_types.activity_type_id AS merged_db_id,
    0 AS local_db_id,
    tbl_activity_types.activity_type_id AS public_db_id,
    tbl_activity_types.activity_type_id,
    tbl_activity_types.activity_type,
    tbl_activity_types.description,
    tbl_activity_types.date_updated
   FROM public.tbl_activity_types;


SET search_path = public, pg_catalog;

--
-- Name: tbl_aggregate_datasets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_aggregate_datasets (
    aggregate_dataset_id integer NOT NULL,
    aggregate_order_type_id integer NOT NULL,
    biblio_id integer,
    aggregate_dataset_name character varying(255),
    date_updated timestamp with time zone DEFAULT now(),
    description text
);


--
-- Name: COLUMN tbl_aggregate_datasets.aggregate_dataset_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_aggregate_datasets.aggregate_dataset_name IS 'name of aggregated dataset';


--
-- Name: COLUMN tbl_aggregate_datasets.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_aggregate_datasets.description IS 'Notes explaining the purpose of the aggregated set of analysis entities';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_aggregate_datasets; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_aggregate_datasets AS
 SELECT tbl_aggregate_datasets.submission_id,
    tbl_aggregate_datasets.source_id,
    tbl_aggregate_datasets.local_db_id AS merged_db_id,
    tbl_aggregate_datasets.local_db_id,
    tbl_aggregate_datasets.public_db_id,
    tbl_aggregate_datasets.aggregate_dataset_id,
    tbl_aggregate_datasets.aggregate_order_type_id,
    tbl_aggregate_datasets.biblio_id,
    tbl_aggregate_datasets.aggregate_dataset_name,
    tbl_aggregate_datasets.date_updated,
    tbl_aggregate_datasets.description
   FROM tbl_aggregate_datasets
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_aggregate_datasets.aggregate_dataset_id AS merged_db_id,
    0 AS local_db_id,
    tbl_aggregate_datasets.aggregate_dataset_id AS public_db_id,
    tbl_aggregate_datasets.aggregate_dataset_id,
    tbl_aggregate_datasets.aggregate_order_type_id,
    tbl_aggregate_datasets.biblio_id,
    tbl_aggregate_datasets.aggregate_dataset_name,
    tbl_aggregate_datasets.date_updated,
    tbl_aggregate_datasets.description
   FROM public.tbl_aggregate_datasets;


SET search_path = public, pg_catalog;

--
-- Name: tbl_aggregate_order_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_aggregate_order_types (
    aggregate_order_type_id integer NOT NULL,
    aggregate_order_type character varying(60) NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    description text
);


--
-- Name: TABLE tbl_aggregate_order_types; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_aggregate_order_types IS '20120504pib: drop this? or replace with alternative?';


--
-- Name: COLUMN tbl_aggregate_order_types.aggregate_order_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_aggregate_order_types.aggregate_order_type IS 'aggregate order name, e.g. site name, age, sample depth, altitude';


--
-- Name: COLUMN tbl_aggregate_order_types.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_aggregate_order_types.description IS 'explanation of ordering system';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_aggregate_order_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_aggregate_order_types AS
 SELECT tbl_aggregate_order_types.submission_id,
    tbl_aggregate_order_types.source_id,
    tbl_aggregate_order_types.local_db_id AS merged_db_id,
    tbl_aggregate_order_types.local_db_id,
    tbl_aggregate_order_types.public_db_id,
    tbl_aggregate_order_types.aggregate_order_type_id,
    tbl_aggregate_order_types.aggregate_order_type,
    tbl_aggregate_order_types.date_updated,
    tbl_aggregate_order_types.description
   FROM tbl_aggregate_order_types
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_aggregate_order_types.aggregate_order_type_id AS merged_db_id,
    0 AS local_db_id,
    tbl_aggregate_order_types.aggregate_order_type_id AS public_db_id,
    tbl_aggregate_order_types.aggregate_order_type_id,
    tbl_aggregate_order_types.aggregate_order_type,
    tbl_aggregate_order_types.date_updated,
    tbl_aggregate_order_types.description
   FROM public.tbl_aggregate_order_types;


SET search_path = public, pg_catalog;

--
-- Name: tbl_aggregate_sample_ages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_aggregate_sample_ages (
    aggregate_sample_age_id integer NOT NULL,
    aggregate_dataset_id integer NOT NULL,
    analysis_entity_age_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_aggregate_sample_ages; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_aggregate_sample_ages AS
 SELECT tbl_aggregate_sample_ages.submission_id,
    tbl_aggregate_sample_ages.source_id,
    tbl_aggregate_sample_ages.local_db_id AS merged_db_id,
    tbl_aggregate_sample_ages.local_db_id,
    tbl_aggregate_sample_ages.public_db_id,
    tbl_aggregate_sample_ages.aggregate_sample_age_id,
    tbl_aggregate_sample_ages.aggregate_dataset_id,
    tbl_aggregate_sample_ages.analysis_entity_age_id,
    tbl_aggregate_sample_ages.date_updated
   FROM tbl_aggregate_sample_ages
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_aggregate_sample_ages.aggregate_sample_age_id AS merged_db_id,
    0 AS local_db_id,
    tbl_aggregate_sample_ages.aggregate_sample_age_id AS public_db_id,
    tbl_aggregate_sample_ages.aggregate_sample_age_id,
    tbl_aggregate_sample_ages.aggregate_dataset_id,
    tbl_aggregate_sample_ages.analysis_entity_age_id,
    tbl_aggregate_sample_ages.date_updated
   FROM public.tbl_aggregate_sample_ages;


SET search_path = public, pg_catalog;

--
-- Name: tbl_aggregate_samples; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_aggregate_samples (
    aggregate_sample_id integer NOT NULL,
    aggregate_dataset_id integer NOT NULL,
    analysis_entity_id integer NOT NULL,
    aggregate_sample_name character varying(50),
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE tbl_aggregate_samples; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_aggregate_samples IS '20120504pib: can we drop aggregate sample name? seems excessive and unnecessary sample names can be traced.';


--
-- Name: COLUMN tbl_aggregate_samples.aggregate_sample_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_aggregate_samples.aggregate_sample_name IS 'optional name for aggregated entity.';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_aggregate_samples; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_aggregate_samples AS
 SELECT tbl_aggregate_samples.submission_id,
    tbl_aggregate_samples.source_id,
    tbl_aggregate_samples.local_db_id AS merged_db_id,
    tbl_aggregate_samples.local_db_id,
    tbl_aggregate_samples.public_db_id,
    tbl_aggregate_samples.aggregate_sample_id,
    tbl_aggregate_samples.aggregate_dataset_id,
    tbl_aggregate_samples.analysis_entity_id,
    tbl_aggregate_samples.aggregate_sample_name,
    tbl_aggregate_samples.date_updated
   FROM tbl_aggregate_samples
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_aggregate_samples.aggregate_sample_id AS merged_db_id,
    0 AS local_db_id,
    tbl_aggregate_samples.aggregate_sample_id AS public_db_id,
    tbl_aggregate_samples.aggregate_sample_id,
    tbl_aggregate_samples.aggregate_dataset_id,
    tbl_aggregate_samples.analysis_entity_id,
    tbl_aggregate_samples.aggregate_sample_name,
    tbl_aggregate_samples.date_updated
   FROM public.tbl_aggregate_samples;


SET search_path = public, pg_catalog;

--
-- Name: tbl_alt_ref_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_alt_ref_types (
    alt_ref_type_id integer NOT NULL,
    alt_ref_type character varying(50) NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    description text
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_alt_ref_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_alt_ref_types AS
 SELECT tbl_alt_ref_types.submission_id,
    tbl_alt_ref_types.source_id,
    tbl_alt_ref_types.local_db_id AS merged_db_id,
    tbl_alt_ref_types.local_db_id,
    tbl_alt_ref_types.public_db_id,
    tbl_alt_ref_types.alt_ref_type_id,
    tbl_alt_ref_types.alt_ref_type,
    tbl_alt_ref_types.date_updated,
    tbl_alt_ref_types.description
   FROM tbl_alt_ref_types
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_alt_ref_types.alt_ref_type_id AS merged_db_id,
    0 AS local_db_id,
    tbl_alt_ref_types.alt_ref_type_id AS public_db_id,
    tbl_alt_ref_types.alt_ref_type_id,
    tbl_alt_ref_types.alt_ref_type,
    tbl_alt_ref_types.date_updated,
    tbl_alt_ref_types.description
   FROM public.tbl_alt_ref_types;


SET search_path = public, pg_catalog;

--
-- Name: tbl_analysis_entities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_analysis_entities (
    analysis_entity_id integer NOT NULL,
    physical_sample_id integer,
    dataset_id integer,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE tbl_analysis_entities; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_analysis_entities IS '20120503pib deleted column preparation_method_id, but may need to cater for this in datasets...
20120506pib: deleted method_id and added table for multiple methods per entity';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_analysis_entities; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_analysis_entities AS
 SELECT tbl_analysis_entities.submission_id,
    tbl_analysis_entities.source_id,
    tbl_analysis_entities.local_db_id AS merged_db_id,
    tbl_analysis_entities.local_db_id,
    tbl_analysis_entities.public_db_id,
    tbl_analysis_entities.analysis_entity_id,
    tbl_analysis_entities.physical_sample_id,
    tbl_analysis_entities.dataset_id,
    tbl_analysis_entities.date_updated
   FROM tbl_analysis_entities
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_analysis_entities.analysis_entity_id AS merged_db_id,
    0 AS local_db_id,
    tbl_analysis_entities.analysis_entity_id AS public_db_id,
    tbl_analysis_entities.analysis_entity_id,
    tbl_analysis_entities.physical_sample_id,
    tbl_analysis_entities.dataset_id,
    tbl_analysis_entities.date_updated
   FROM public.tbl_analysis_entities;


SET search_path = public, pg_catalog;

--
-- Name: tbl_analysis_entity_ages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_analysis_entity_ages (
    analysis_entity_age_id integer NOT NULL,
    age numeric(20,10) NOT NULL,
    age_older numeric(15,5),
    age_younger numeric(15,5),
    analysis_entity_id integer,
    chronology_id integer,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE tbl_analysis_entity_ages; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_analysis_entity_ages IS '20120504pib: should this be connected to physical sample instead of analysis entities? allowing multiple ages (from multiple dates) for a sample. at the moment it requires a lot of backtracing to find a sample''s age... but then again, it allows... what, exactly?';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_analysis_entity_ages; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_analysis_entity_ages AS
 SELECT tbl_analysis_entity_ages.submission_id,
    tbl_analysis_entity_ages.source_id,
    tbl_analysis_entity_ages.local_db_id AS merged_db_id,
    tbl_analysis_entity_ages.local_db_id,
    tbl_analysis_entity_ages.public_db_id,
    tbl_analysis_entity_ages.analysis_entity_age_id,
    tbl_analysis_entity_ages.age,
    tbl_analysis_entity_ages.age_older,
    tbl_analysis_entity_ages.age_younger,
    tbl_analysis_entity_ages.analysis_entity_id,
    tbl_analysis_entity_ages.chronology_id,
    tbl_analysis_entity_ages.date_updated
   FROM tbl_analysis_entity_ages
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_analysis_entity_ages.analysis_entity_age_id AS merged_db_id,
    0 AS local_db_id,
    tbl_analysis_entity_ages.analysis_entity_age_id AS public_db_id,
    tbl_analysis_entity_ages.analysis_entity_age_id,
    tbl_analysis_entity_ages.age,
    tbl_analysis_entity_ages.age_older,
    tbl_analysis_entity_ages.age_younger,
    tbl_analysis_entity_ages.analysis_entity_id,
    tbl_analysis_entity_ages.chronology_id,
    tbl_analysis_entity_ages.date_updated
   FROM public.tbl_analysis_entity_ages;


SET search_path = public, pg_catalog;

--
-- Name: tbl_analysis_entity_dimensions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_analysis_entity_dimensions (
    analysis_entity_dimension_id integer NOT NULL,
    analysis_entity_id integer NOT NULL,
    dimension_id integer NOT NULL,
    dimension_value numeric NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_analysis_entity_dimensions; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_analysis_entity_dimensions AS
 SELECT tbl_analysis_entity_dimensions.submission_id,
    tbl_analysis_entity_dimensions.source_id,
    tbl_analysis_entity_dimensions.local_db_id AS merged_db_id,
    tbl_analysis_entity_dimensions.local_db_id,
    tbl_analysis_entity_dimensions.public_db_id,
    tbl_analysis_entity_dimensions.analysis_entity_dimension_id,
    tbl_analysis_entity_dimensions.analysis_entity_id,
    tbl_analysis_entity_dimensions.dimension_id,
    tbl_analysis_entity_dimensions.dimension_value,
    tbl_analysis_entity_dimensions.date_updated
   FROM tbl_analysis_entity_dimensions
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_analysis_entity_dimensions.analysis_entity_dimension_id AS merged_db_id,
    0 AS local_db_id,
    tbl_analysis_entity_dimensions.analysis_entity_dimension_id AS public_db_id,
    tbl_analysis_entity_dimensions.analysis_entity_dimension_id,
    tbl_analysis_entity_dimensions.analysis_entity_id,
    tbl_analysis_entity_dimensions.dimension_id,
    tbl_analysis_entity_dimensions.dimension_value,
    tbl_analysis_entity_dimensions.date_updated
   FROM public.tbl_analysis_entity_dimensions;


SET search_path = public, pg_catalog;

--
-- Name: tbl_analysis_entity_prep_methods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_analysis_entity_prep_methods (
    analysis_entity_prep_method_id integer NOT NULL,
    analysis_entity_id integer NOT NULL,
    method_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE tbl_analysis_entity_prep_methods; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_analysis_entity_prep_methods IS '20120506pib: created to cater for multiple preparation methods for analysis but maintaining simple dataset concept.';


--
-- Name: COLUMN tbl_analysis_entity_prep_methods.method_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_analysis_entity_prep_methods.method_id IS 'preparation methods only';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_analysis_entity_prep_methods; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_analysis_entity_prep_methods AS
 SELECT tbl_analysis_entity_prep_methods.submission_id,
    tbl_analysis_entity_prep_methods.source_id,
    tbl_analysis_entity_prep_methods.local_db_id AS merged_db_id,
    tbl_analysis_entity_prep_methods.local_db_id,
    tbl_analysis_entity_prep_methods.public_db_id,
    tbl_analysis_entity_prep_methods.analysis_entity_prep_method_id,
    tbl_analysis_entity_prep_methods.analysis_entity_id,
    tbl_analysis_entity_prep_methods.method_id,
    tbl_analysis_entity_prep_methods.date_updated
   FROM tbl_analysis_entity_prep_methods
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_analysis_entity_prep_methods.analysis_entity_prep_method_id AS merged_db_id,
    0 AS local_db_id,
    tbl_analysis_entity_prep_methods.analysis_entity_prep_method_id AS public_db_id,
    tbl_analysis_entity_prep_methods.analysis_entity_prep_method_id,
    tbl_analysis_entity_prep_methods.analysis_entity_id,
    tbl_analysis_entity_prep_methods.method_id,
    tbl_analysis_entity_prep_methods.date_updated
   FROM public.tbl_analysis_entity_prep_methods;


SET search_path = public, pg_catalog;

--
-- Name: tbl_biblio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_biblio (
    biblio_id integer NOT NULL,
    author character varying,
    biblio_keyword_id integer,
    bugs_author character varying(255) DEFAULT NULL::character varying,
    bugs_biblio_id integer,
    bugs_reference character varying(60) DEFAULT NULL::character varying,
    bugs_title character varying,
    collection_or_journal_id integer,
    date_updated timestamp with time zone DEFAULT now(),
    doi character varying(255) DEFAULT NULL::character varying,
    edition character varying(128) DEFAULT NULL::character varying,
    isbn character varying(128) DEFAULT NULL::character varying,
    keywords character varying,
    notes text,
    number character varying(128) DEFAULT NULL::character varying,
    pages character varying(50) DEFAULT NULL::character varying,
    pdf_link character varying,
    publication_type_id integer,
    publisher_id integer,
    title character varying,
    volume character varying(128) DEFAULT NULL::character varying,
    year character varying(255) DEFAULT NULL::character varying
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_biblio; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_biblio AS
 SELECT tbl_biblio.submission_id,
    tbl_biblio.source_id,
    tbl_biblio.local_db_id AS merged_db_id,
    tbl_biblio.local_db_id,
    tbl_biblio.public_db_id,
    tbl_biblio.biblio_id,
    tbl_biblio.author,
    tbl_biblio.biblio_keyword_id,
    tbl_biblio.bugs_author,
    tbl_biblio.bugs_biblio_id,
    tbl_biblio.bugs_reference,
    tbl_biblio.bugs_title,
    tbl_biblio.collection_or_journal_id,
    tbl_biblio.date_updated,
    tbl_biblio.doi,
    tbl_biblio.edition,
    tbl_biblio.isbn,
    tbl_biblio.keywords,
    tbl_biblio.notes,
    tbl_biblio.number,
    tbl_biblio.pages,
    tbl_biblio.pdf_link,
    tbl_biblio.publication_type_id,
    tbl_biblio.publisher_id,
    tbl_biblio.title,
    tbl_biblio.volume,
    tbl_biblio.year
   FROM tbl_biblio
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_biblio.biblio_id AS merged_db_id,
    0 AS local_db_id,
    tbl_biblio.biblio_id AS public_db_id,
    tbl_biblio.biblio_id,
    tbl_biblio.author,
    tbl_biblio.biblio_keyword_id,
    tbl_biblio.bugs_author,
    tbl_biblio.bugs_biblio_id,
    tbl_biblio.bugs_reference,
    tbl_biblio.bugs_title,
    tbl_biblio.collection_or_journal_id,
    tbl_biblio.date_updated,
    tbl_biblio.doi,
    tbl_biblio.edition,
    tbl_biblio.isbn,
    tbl_biblio.keywords,
    tbl_biblio.notes,
    tbl_biblio.number,
    tbl_biblio.pages,
    tbl_biblio.pdf_link,
    tbl_biblio.publication_type_id,
    tbl_biblio.publisher_id,
    tbl_biblio.title,
    tbl_biblio.volume,
    tbl_biblio.year
   FROM public.tbl_biblio;


SET search_path = public, pg_catalog;

--
-- Name: tbl_biblio_keywords; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_biblio_keywords (
    biblio_keyword_id integer NOT NULL,
    biblio_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    keyword_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_biblio_keywords; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_biblio_keywords AS
 SELECT tbl_biblio_keywords.submission_id,
    tbl_biblio_keywords.source_id,
    tbl_biblio_keywords.local_db_id AS merged_db_id,
    tbl_biblio_keywords.local_db_id,
    tbl_biblio_keywords.public_db_id,
    tbl_biblio_keywords.biblio_keyword_id,
    tbl_biblio_keywords.biblio_id,
    tbl_biblio_keywords.date_updated,
    tbl_biblio_keywords.keyword_id
   FROM tbl_biblio_keywords
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_biblio_keywords.biblio_keyword_id AS merged_db_id,
    0 AS local_db_id,
    tbl_biblio_keywords.biblio_keyword_id AS public_db_id,
    tbl_biblio_keywords.biblio_keyword_id,
    tbl_biblio_keywords.biblio_id,
    tbl_biblio_keywords.date_updated,
    tbl_biblio_keywords.keyword_id
   FROM public.tbl_biblio_keywords;


SET search_path = public, pg_catalog;

--
-- Name: tbl_ceramics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_ceramics (
    ceramics_id integer NOT NULL,
    analysis_entity_id integer NOT NULL,
    ceramics_measurement_id integer NOT NULL,
    measurement_value character varying NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_ceramics; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_ceramics AS
 SELECT tbl_ceramics.submission_id,
    tbl_ceramics.source_id,
    tbl_ceramics.local_db_id AS merged_db_id,
    tbl_ceramics.local_db_id,
    tbl_ceramics.public_db_id,
    tbl_ceramics.ceramics_id,
    tbl_ceramics.analysis_entity_id,
    tbl_ceramics.ceramics_measurement_id,
    tbl_ceramics.measurement_value,
    tbl_ceramics.date_updated
   FROM tbl_ceramics
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_ceramics.ceramics_id AS merged_db_id,
    0 AS local_db_id,
    tbl_ceramics.ceramics_id AS public_db_id,
    tbl_ceramics.ceramics_id,
    tbl_ceramics.analysis_entity_id,
    tbl_ceramics.ceramics_measurement_id,
    tbl_ceramics.measurement_value,
    tbl_ceramics.date_updated
   FROM public.tbl_ceramics;


SET search_path = public, pg_catalog;

--
-- Name: tbl_ceramics_measurement_lookup; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_ceramics_measurement_lookup (
    ceramics_measurement_lookup_id integer NOT NULL,
    ceramics_measurement_id integer NOT NULL,
    value character varying NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_ceramics_measurement_lookup; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_ceramics_measurement_lookup AS
 SELECT tbl_ceramics_measurement_lookup.submission_id,
    tbl_ceramics_measurement_lookup.source_id,
    tbl_ceramics_measurement_lookup.local_db_id AS merged_db_id,
    tbl_ceramics_measurement_lookup.local_db_id,
    tbl_ceramics_measurement_lookup.public_db_id,
    tbl_ceramics_measurement_lookup.ceramics_measurement_lookup_id,
    tbl_ceramics_measurement_lookup.ceramics_measurement_id,
    tbl_ceramics_measurement_lookup.value,
    tbl_ceramics_measurement_lookup.date_updated
   FROM tbl_ceramics_measurement_lookup
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_ceramics_measurement_lookup.ceramics_measurement_lookup_id AS merged_db_id,
    0 AS local_db_id,
    tbl_ceramics_measurement_lookup.ceramics_measurement_lookup_id AS public_db_id,
    tbl_ceramics_measurement_lookup.ceramics_measurement_lookup_id,
    tbl_ceramics_measurement_lookup.ceramics_measurement_id,
    tbl_ceramics_measurement_lookup.value,
    tbl_ceramics_measurement_lookup.date_updated
   FROM public.tbl_ceramics_measurement_lookup;


SET search_path = public, pg_catalog;

--
-- Name: tbl_ceramics_measurements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_ceramics_measurements (
    ceramics_measurement_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    method_id integer
);


--
-- Name: TABLE tbl_ceramics_measurements; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_ceramics_measurements IS 'Type=lookup';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_ceramics_measurements; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_ceramics_measurements AS
 SELECT tbl_ceramics_measurements.submission_id,
    tbl_ceramics_measurements.source_id,
    tbl_ceramics_measurements.local_db_id AS merged_db_id,
    tbl_ceramics_measurements.local_db_id,
    tbl_ceramics_measurements.public_db_id,
    tbl_ceramics_measurements.ceramics_measurement_id,
    tbl_ceramics_measurements.date_updated,
    tbl_ceramics_measurements.method_id
   FROM tbl_ceramics_measurements
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_ceramics_measurements.ceramics_measurement_id AS merged_db_id,
    0 AS local_db_id,
    tbl_ceramics_measurements.ceramics_measurement_id AS public_db_id,
    tbl_ceramics_measurements.ceramics_measurement_id,
    tbl_ceramics_measurements.date_updated,
    tbl_ceramics_measurements.method_id
   FROM public.tbl_ceramics_measurements;


SET search_path = public, pg_catalog;

--
-- Name: tbl_chron_control_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_chron_control_types (
    chron_control_type_id integer NOT NULL,
    chron_control_type character varying(50),
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_chron_control_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_chron_control_types AS
 SELECT tbl_chron_control_types.submission_id,
    tbl_chron_control_types.source_id,
    tbl_chron_control_types.local_db_id AS merged_db_id,
    tbl_chron_control_types.local_db_id,
    tbl_chron_control_types.public_db_id,
    tbl_chron_control_types.chron_control_type_id,
    tbl_chron_control_types.chron_control_type,
    tbl_chron_control_types.date_updated
   FROM tbl_chron_control_types
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_chron_control_types.chron_control_type_id AS merged_db_id,
    0 AS local_db_id,
    tbl_chron_control_types.chron_control_type_id AS public_db_id,
    tbl_chron_control_types.chron_control_type_id,
    tbl_chron_control_types.chron_control_type,
    tbl_chron_control_types.date_updated
   FROM public.tbl_chron_control_types;


SET search_path = public, pg_catalog;

--
-- Name: tbl_chron_controls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_chron_controls (
    chron_control_id integer NOT NULL,
    age numeric(20,5),
    age_limit_older numeric(20,5),
    age_limit_younger numeric(20,5),
    chron_control_type_id integer,
    chronology_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    depth_bottom numeric(20,5),
    depth_top numeric(20,5),
    notes text
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_chron_controls; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_chron_controls AS
 SELECT tbl_chron_controls.submission_id,
    tbl_chron_controls.source_id,
    tbl_chron_controls.local_db_id AS merged_db_id,
    tbl_chron_controls.local_db_id,
    tbl_chron_controls.public_db_id,
    tbl_chron_controls.chron_control_id,
    tbl_chron_controls.age,
    tbl_chron_controls.age_limit_older,
    tbl_chron_controls.age_limit_younger,
    tbl_chron_controls.chron_control_type_id,
    tbl_chron_controls.chronology_id,
    tbl_chron_controls.date_updated,
    tbl_chron_controls.depth_bottom,
    tbl_chron_controls.depth_top,
    tbl_chron_controls.notes
   FROM tbl_chron_controls
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_chron_controls.chron_control_id AS merged_db_id,
    0 AS local_db_id,
    tbl_chron_controls.chron_control_id AS public_db_id,
    tbl_chron_controls.chron_control_id,
    tbl_chron_controls.age,
    tbl_chron_controls.age_limit_older,
    tbl_chron_controls.age_limit_younger,
    tbl_chron_controls.chron_control_type_id,
    tbl_chron_controls.chronology_id,
    tbl_chron_controls.date_updated,
    tbl_chron_controls.depth_bottom,
    tbl_chron_controls.depth_top,
    tbl_chron_controls.notes
   FROM public.tbl_chron_controls;


SET search_path = public, pg_catalog;

--
-- Name: tbl_chronologies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_chronologies (
    chronology_id integer NOT NULL,
    age_bound_older integer,
    age_bound_younger integer,
    age_model character varying(80),
    age_type_id integer NOT NULL,
    chronology_name character varying(80),
    contact_id integer,
    date_prepared timestamp(0) without time zone,
    date_updated timestamp with time zone DEFAULT now(),
    is_default boolean DEFAULT false NOT NULL,
    notes text,
    sample_group_id integer NOT NULL
);


--
-- Name: TABLE tbl_chronologies; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_chronologies IS '20120504pib: note that the dropped age type recorded the type of dates (c14 etc) used in constructing the chronology... but is only one per chonology enough? can a chronology not be made up of mulitple types of age?';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_chronologies; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_chronologies AS
 SELECT tbl_chronologies.submission_id,
    tbl_chronologies.source_id,
    tbl_chronologies.local_db_id AS merged_db_id,
    tbl_chronologies.local_db_id,
    tbl_chronologies.public_db_id,
    tbl_chronologies.chronology_id,
    tbl_chronologies.age_bound_older,
    tbl_chronologies.age_bound_younger,
    tbl_chronologies.age_model,
    tbl_chronologies.age_type_id,
    tbl_chronologies.chronology_name,
    tbl_chronologies.contact_id,
    tbl_chronologies.date_prepared,
    tbl_chronologies.date_updated,
    tbl_chronologies.is_default,
    tbl_chronologies.notes,
    tbl_chronologies.sample_group_id
   FROM tbl_chronologies
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_chronologies.chronology_id AS merged_db_id,
    0 AS local_db_id,
    tbl_chronologies.chronology_id AS public_db_id,
    tbl_chronologies.chronology_id,
    tbl_chronologies.age_bound_older,
    tbl_chronologies.age_bound_younger,
    tbl_chronologies.age_model,
    tbl_chronologies.age_type_id,
    tbl_chronologies.chronology_name,
    tbl_chronologies.contact_id,
    tbl_chronologies.date_prepared,
    tbl_chronologies.date_updated,
    tbl_chronologies.is_default,
    tbl_chronologies.notes,
    tbl_chronologies.sample_group_id
   FROM public.tbl_chronologies;


--
-- Name: view_clearinghouse_dataset_abundance_element_names; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_clearinghouse_dataset_abundance_element_names AS
 SELECT a.submission_id,
    a.abundance_id,
    a.merged_db_id,
    a.public_db_id,
    a.local_db_id,
    array_to_string(array_agg(ael.element_name), ','::text) AS element_name
   FROM (view_abundances a
     JOIN view_abundance_elements ael ON ((ael.abundance_element_id = a.abundance_element_id)))
  GROUP BY a.submission_id, a.abundance_id, a.merged_db_id, a.public_db_id, a.local_db_id;


SET search_path = public, pg_catalog;

--
-- Name: tbl_identification_levels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_identification_levels (
    identification_level_id integer NOT NULL,
    identification_level_abbrev character varying(50) DEFAULT NULL::character varying,
    identification_level_name character varying(50) DEFAULT NULL::character varying,
    notes text,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_identification_levels; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_identification_levels AS
 SELECT tbl_identification_levels.submission_id,
    tbl_identification_levels.source_id,
    tbl_identification_levels.local_db_id AS merged_db_id,
    tbl_identification_levels.local_db_id,
    tbl_identification_levels.public_db_id,
    tbl_identification_levels.identification_level_id,
    tbl_identification_levels.identification_level_abbrev,
    tbl_identification_levels.identification_level_name,
    tbl_identification_levels.notes,
    tbl_identification_levels.date_updated
   FROM tbl_identification_levels
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_identification_levels.identification_level_id AS merged_db_id,
    0 AS local_db_id,
    tbl_identification_levels.identification_level_id AS public_db_id,
    tbl_identification_levels.identification_level_id,
    tbl_identification_levels.identification_level_abbrev,
    tbl_identification_levels.identification_level_name,
    tbl_identification_levels.notes,
    tbl_identification_levels.date_updated
   FROM public.tbl_identification_levels;


--
-- Name: view_clearinghouse_dataset_abundance_ident_levels; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_clearinghouse_dataset_abundance_ident_levels AS
 SELECT al.submission_id,
    al.abundance_id,
    al.merged_db_id,
    al.public_db_id,
    al.local_db_id,
    array_to_string(array_agg(l.identification_level_abbrev), ','::text) AS identification_level_abbrev,
    array_to_string(array_agg(l.identification_level_name), ','::text) AS identification_level_name
   FROM (view_abundance_ident_levels al
     LEFT JOIN view_identification_levels l ON ((l.identification_level_id = al.identification_level_id)))
  GROUP BY al.submission_id, al.abundance_id, al.merged_db_id, al.public_db_id, al.local_db_id;


SET search_path = public, pg_catalog;

--
-- Name: tbl_modification_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_modification_types (
    modification_type_id integer NOT NULL,
    modification_type_name character varying(128),
    modification_type_description text,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN tbl_modification_types.modification_type_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_modification_types.modification_type_name IS 'short name of modification, e.g. carbonised';


--
-- Name: COLUMN tbl_modification_types.modification_type_description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_modification_types.modification_type_description IS 'clear explanation of modification so that name makes sense to non-domain scientists';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_modification_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_modification_types AS
 SELECT tbl_modification_types.submission_id,
    tbl_modification_types.source_id,
    tbl_modification_types.local_db_id AS merged_db_id,
    tbl_modification_types.local_db_id,
    tbl_modification_types.public_db_id,
    tbl_modification_types.modification_type_id,
    tbl_modification_types.modification_type_name,
    tbl_modification_types.modification_type_description,
    tbl_modification_types.date_updated
   FROM tbl_modification_types
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_modification_types.modification_type_id AS merged_db_id,
    0 AS local_db_id,
    tbl_modification_types.modification_type_id AS public_db_id,
    tbl_modification_types.modification_type_id,
    tbl_modification_types.modification_type_name,
    tbl_modification_types.modification_type_description,
    tbl_modification_types.date_updated
   FROM public.tbl_modification_types;


--
-- Name: view_clearinghouse_dataset_abundance_modification_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_clearinghouse_dataset_abundance_modification_types AS
 SELECT am.submission_id,
    am.abundance_id,
    am.merged_db_id,
    am.public_db_id,
    am.local_db_id,
    array_to_string(array_agg(mt.modification_type_description), ','::text) AS modification_type_description,
    array_to_string(array_agg(mt.modification_type_name), ','::text) AS modification_type_name
   FROM (view_abundance_modifications am
     LEFT JOIN view_modification_types mt ON (((mt.merged_db_id = am.modification_type_id) AND ((mt.submission_id = 0) OR (mt.submission_id = am.submission_id)))))
  GROUP BY am.submission_id, am.abundance_id, am.merged_db_id, am.public_db_id, am.local_db_id;


SET search_path = public, pg_catalog;

--
-- Name: tbl_datasets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_datasets (
    dataset_id integer NOT NULL,
    master_set_id integer,
    data_type_id integer NOT NULL,
    method_id integer,
    biblio_id integer,
    updated_dataset_id integer,
    project_id integer,
    dataset_name character varying(50) NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN tbl_datasets.dataset_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_datasets.dataset_name IS 'something uniquely identifying the dataset for this site. may be same as sample group name, or created adhoc if necessary, but preferably with some meaning.';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_datasets; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_datasets AS
 SELECT tbl_datasets.submission_id,
    tbl_datasets.source_id,
    tbl_datasets.local_db_id AS merged_db_id,
    tbl_datasets.local_db_id,
    tbl_datasets.public_db_id,
    tbl_datasets.dataset_id,
    tbl_datasets.master_set_id,
    tbl_datasets.data_type_id,
    tbl_datasets.method_id,
    tbl_datasets.biblio_id,
    tbl_datasets.updated_dataset_id,
    tbl_datasets.project_id,
    tbl_datasets.dataset_name,
    tbl_datasets.date_updated
   FROM tbl_datasets
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_datasets.dataset_id AS merged_db_id,
    0 AS local_db_id,
    tbl_datasets.dataset_id AS public_db_id,
    tbl_datasets.dataset_id,
    tbl_datasets.master_set_id,
    tbl_datasets.data_type_id,
    tbl_datasets.method_id,
    tbl_datasets.biblio_id,
    tbl_datasets.updated_dataset_id,
    tbl_datasets.project_id,
    tbl_datasets.dataset_name,
    tbl_datasets.date_updated
   FROM public.tbl_datasets;


SET search_path = public, pg_catalog;

--
-- Name: tbl_physical_samples; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_physical_samples (
    physical_sample_id integer NOT NULL,
    sample_group_id integer DEFAULT 0 NOT NULL,
    alt_ref_type_id integer,
    sample_type_id integer NOT NULL,
    sample_name character varying(50) NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    date_sampled character varying
);


--
-- Name: TABLE tbl_physical_samples; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_physical_samples IS '20120504PIB: deleted columns XYZ and created external tbl_sample_coodinates
20120506PIB: deleted columns depth_top & depth_bottom and moved to tbl_sample_dimensions
20130416PIB: changed to date_sampled from date to varchar format to increase flexibility';


--
-- Name: COLUMN tbl_physical_samples.alt_ref_type_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_physical_samples.alt_ref_type_id IS 'type of name represented by primary sample name, e.g. lab number, museum number etc.';


--
-- Name: COLUMN tbl_physical_samples.sample_type_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_physical_samples.sample_type_id IS 'physical form of sample, e.g. bulk sample, kubienta subsample, core subsample, dendro core, dendro slice...';


--
-- Name: COLUMN tbl_physical_samples.sample_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_physical_samples.sample_name IS 'reference number or name of sample. multiple references/names can be added as alternative references.';


--
-- Name: COLUMN tbl_physical_samples.date_sampled; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_physical_samples.date_sampled IS 'Date samples were taken. ';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_physical_samples; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_physical_samples AS
 SELECT tbl_physical_samples.submission_id,
    tbl_physical_samples.source_id,
    tbl_physical_samples.local_db_id AS merged_db_id,
    tbl_physical_samples.local_db_id,
    tbl_physical_samples.public_db_id,
    tbl_physical_samples.physical_sample_id,
    tbl_physical_samples.sample_group_id,
    tbl_physical_samples.alt_ref_type_id,
    tbl_physical_samples.sample_type_id,
    tbl_physical_samples.sample_name,
    tbl_physical_samples.date_updated,
    tbl_physical_samples.date_sampled
   FROM tbl_physical_samples
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_physical_samples.physical_sample_id AS merged_db_id,
    0 AS local_db_id,
    tbl_physical_samples.physical_sample_id AS public_db_id,
    tbl_physical_samples.physical_sample_id,
    tbl_physical_samples.sample_group_id,
    tbl_physical_samples.alt_ref_type_id,
    tbl_physical_samples.sample_type_id,
    tbl_physical_samples.sample_name,
    tbl_physical_samples.date_updated,
    tbl_physical_samples.date_sampled
   FROM public.tbl_physical_samples;


SET search_path = public, pg_catalog;

--
-- Name: tbl_taxa_tree_authors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_taxa_tree_authors (
    author_id integer NOT NULL,
    author_name character varying(100) DEFAULT NULL::character varying,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_taxa_tree_authors; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_taxa_tree_authors AS
 SELECT tbl_taxa_tree_authors.submission_id,
    tbl_taxa_tree_authors.source_id,
    tbl_taxa_tree_authors.local_db_id AS merged_db_id,
    tbl_taxa_tree_authors.local_db_id,
    tbl_taxa_tree_authors.public_db_id,
    tbl_taxa_tree_authors.author_id,
    tbl_taxa_tree_authors.author_name,
    tbl_taxa_tree_authors.date_updated
   FROM tbl_taxa_tree_authors
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_taxa_tree_authors.author_id AS merged_db_id,
    0 AS local_db_id,
    tbl_taxa_tree_authors.author_id AS public_db_id,
    tbl_taxa_tree_authors.author_id,
    tbl_taxa_tree_authors.author_name,
    tbl_taxa_tree_authors.date_updated
   FROM public.tbl_taxa_tree_authors;


SET search_path = public, pg_catalog;

--
-- Name: tbl_taxa_tree_genera; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_taxa_tree_genera (
    genus_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    family_id integer,
    genus_name character varying(100) DEFAULT NULL::character varying
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_taxa_tree_genera; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_taxa_tree_genera AS
 SELECT tbl_taxa_tree_genera.submission_id,
    tbl_taxa_tree_genera.source_id,
    tbl_taxa_tree_genera.local_db_id AS merged_db_id,
    tbl_taxa_tree_genera.local_db_id,
    tbl_taxa_tree_genera.public_db_id,
    tbl_taxa_tree_genera.genus_id,
    tbl_taxa_tree_genera.date_updated,
    tbl_taxa_tree_genera.family_id,
    tbl_taxa_tree_genera.genus_name
   FROM tbl_taxa_tree_genera
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_taxa_tree_genera.genus_id AS merged_db_id,
    0 AS local_db_id,
    tbl_taxa_tree_genera.genus_id AS public_db_id,
    tbl_taxa_tree_genera.genus_id,
    tbl_taxa_tree_genera.date_updated,
    tbl_taxa_tree_genera.family_id,
    tbl_taxa_tree_genera.genus_name
   FROM public.tbl_taxa_tree_genera;


SET search_path = public, pg_catalog;

--
-- Name: tbl_taxa_tree_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_taxa_tree_master (
    taxon_id integer NOT NULL,
    author_id integer,
    date_updated timestamp with time zone DEFAULT now(),
    genus_id integer,
    species character varying(255) DEFAULT NULL::character varying
);


--
-- Name: TABLE tbl_taxa_tree_master; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_taxa_tree_master IS '20130416PIB: removed default=0 for author_id and genus_id as was incorrect';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_taxa_tree_master; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_taxa_tree_master AS
 SELECT tbl_taxa_tree_master.submission_id,
    tbl_taxa_tree_master.source_id,
    tbl_taxa_tree_master.local_db_id AS merged_db_id,
    tbl_taxa_tree_master.local_db_id,
    tbl_taxa_tree_master.public_db_id,
    tbl_taxa_tree_master.taxon_id,
    tbl_taxa_tree_master.author_id,
    tbl_taxa_tree_master.date_updated,
    tbl_taxa_tree_master.genus_id,
    tbl_taxa_tree_master.species
   FROM tbl_taxa_tree_master
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_taxa_tree_master.taxon_id AS merged_db_id,
    0 AS local_db_id,
    tbl_taxa_tree_master.taxon_id AS public_db_id,
    tbl_taxa_tree_master.taxon_id,
    tbl_taxa_tree_master.author_id,
    tbl_taxa_tree_master.date_updated,
    tbl_taxa_tree_master.genus_id,
    tbl_taxa_tree_master.species
   FROM public.tbl_taxa_tree_master;


--
-- Name: view_clearinghouse_dataset_abundances; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_clearinghouse_dataset_abundances AS
 SELECT d.submission_id,
    d.source_id,
    d.local_db_id AS local_dataset_id,
    d.public_db_id AS public_dataset_id,
    a.abundance_id,
    a.local_db_id,
    a.public_db_id,
    a.abundance,
    ttm.taxon_id,
    ttm.public_db_id AS public_taxon_id,
    ttg.genus_name,
    ttm.species,
    tta.author_name,
    ps.physical_sample_id,
    ps.public_db_id AS public_physical_sample_id,
    ps.sample_name,
    COALESCE(ael.element_name, ''::text) AS element_name,
    COALESCE(mt.modification_type_name, ''::text) AS modification_type_name,
    COALESCE(il.identification_level_name, ''::text) AS identification_level_name
   FROM (((((((((view_datasets d
     JOIN view_analysis_entities ae ON (((ae.dataset_id = d.merged_db_id) AND ((ae.submission_id = 0) OR (ae.submission_id = d.submission_id)))))
     JOIN view_physical_samples ps ON (((ps.merged_db_id = ae.physical_sample_id) AND ((ps.submission_id = 0) OR (ps.submission_id = d.submission_id)))))
     JOIN view_abundances a ON (((a.analysis_entity_id = ae.merged_db_id) AND ((a.submission_id = 0) OR (a.submission_id = d.submission_id)))))
     LEFT JOIN view_taxa_tree_master ttm ON (((ttm.merged_db_id = a.taxon_id) AND ((ttm.submission_id = 0) OR (ttm.submission_id = d.submission_id)))))
     LEFT JOIN view_taxa_tree_genera ttg ON (((ttg.merged_db_id = ttm.genus_id) AND ((ttg.submission_id = 0) OR (ttg.submission_id = d.submission_id)))))
     LEFT JOIN view_taxa_tree_authors tta ON (((tta.merged_db_id = ttm.author_id) AND ((tta.submission_id = 0) OR (tta.submission_id = d.submission_id)))))
     LEFT JOIN view_clearinghouse_dataset_abundance_modification_types mt ON (((mt.abundance_id = a.merged_db_id) AND ((mt.submission_id = 0) OR (mt.submission_id = d.submission_id)))))
     LEFT JOIN view_clearinghouse_dataset_abundance_ident_levels il ON (((il.abundance_id = a.merged_db_id) AND ((il.submission_id = 0) OR (il.submission_id = d.submission_id)))))
     LEFT JOIN view_clearinghouse_dataset_abundance_element_names ael ON (((ael.abundance_id = a.merged_db_id) AND ((ael.submission_id = 0) OR (ael.submission_id = d.submission_id)))))
  WHERE (1 = 1);


SET search_path = public, pg_catalog;

--
-- Name: tbl_dimensions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_dimensions (
    dimension_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    dimension_abbrev character varying(10),
    dimension_description text,
    dimension_name character varying(50) NOT NULL,
    unit_id integer,
    method_group_id integer
);


--
-- Name: COLUMN tbl_dimensions.method_group_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_dimensions.method_group_id IS 'Limits choice of dimension by method group (e.g. size measurements, coordinate systems)';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_dimensions; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_dimensions AS
 SELECT tbl_dimensions.submission_id,
    tbl_dimensions.source_id,
    tbl_dimensions.local_db_id AS merged_db_id,
    tbl_dimensions.local_db_id,
    tbl_dimensions.public_db_id,
    tbl_dimensions.dimension_id,
    tbl_dimensions.date_updated,
    tbl_dimensions.dimension_abbrev,
    tbl_dimensions.dimension_description,
    tbl_dimensions.dimension_name,
    tbl_dimensions.unit_id,
    tbl_dimensions.method_group_id
   FROM tbl_dimensions
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_dimensions.dimension_id AS merged_db_id,
    0 AS local_db_id,
    tbl_dimensions.dimension_id AS public_db_id,
    tbl_dimensions.dimension_id,
    tbl_dimensions.date_updated,
    tbl_dimensions.dimension_abbrev,
    tbl_dimensions.dimension_description,
    tbl_dimensions.dimension_name,
    tbl_dimensions.unit_id,
    tbl_dimensions.method_group_id
   FROM public.tbl_dimensions;


SET search_path = public, pg_catalog;

--
-- Name: tbl_measured_value_dimensions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_measured_value_dimensions (
    measured_value_dimension_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    dimension_id integer NOT NULL,
    dimension_value numeric(18,10) NOT NULL,
    measured_value_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_measured_value_dimensions; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_measured_value_dimensions AS
 SELECT tbl_measured_value_dimensions.submission_id,
    tbl_measured_value_dimensions.source_id,
    tbl_measured_value_dimensions.local_db_id AS merged_db_id,
    tbl_measured_value_dimensions.local_db_id,
    tbl_measured_value_dimensions.public_db_id,
    tbl_measured_value_dimensions.measured_value_dimension_id,
    tbl_measured_value_dimensions.date_updated,
    tbl_measured_value_dimensions.dimension_id,
    tbl_measured_value_dimensions.dimension_value,
    tbl_measured_value_dimensions.measured_value_id
   FROM tbl_measured_value_dimensions
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_measured_value_dimensions.measured_value_dimension_id AS merged_db_id,
    0 AS local_db_id,
    tbl_measured_value_dimensions.measured_value_dimension_id AS public_db_id,
    tbl_measured_value_dimensions.measured_value_dimension_id,
    tbl_measured_value_dimensions.date_updated,
    tbl_measured_value_dimensions.dimension_id,
    tbl_measured_value_dimensions.dimension_value,
    tbl_measured_value_dimensions.measured_value_id
   FROM public.tbl_measured_value_dimensions;


SET search_path = public, pg_catalog;

--
-- Name: tbl_measured_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_measured_values (
    measured_value_id integer NOT NULL,
    analysis_entity_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    measured_value numeric(20,10) NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_measured_values; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_measured_values AS
 SELECT tbl_measured_values.submission_id,
    tbl_measured_values.source_id,
    tbl_measured_values.local_db_id AS merged_db_id,
    tbl_measured_values.local_db_id,
    tbl_measured_values.public_db_id,
    tbl_measured_values.measured_value_id,
    tbl_measured_values.analysis_entity_id,
    tbl_measured_values.date_updated,
    tbl_measured_values.measured_value
   FROM tbl_measured_values
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_measured_values.measured_value_id AS merged_db_id,
    0 AS local_db_id,
    tbl_measured_values.measured_value_id AS public_db_id,
    tbl_measured_values.measured_value_id,
    tbl_measured_values.analysis_entity_id,
    tbl_measured_values.date_updated,
    tbl_measured_values.measured_value
   FROM public.tbl_measured_values;


SET search_path = public, pg_catalog;

--
-- Name: tbl_methods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_methods (
    method_id integer NOT NULL,
    biblio_id integer,
    date_updated timestamp with time zone DEFAULT now(),
    description text NOT NULL,
    method_abbrev_or_alt_name character varying(50),
    method_group_id integer NOT NULL,
    method_name character varying(50) NOT NULL,
    record_type_id integer,
    unit_id integer
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_methods; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_methods AS
 SELECT tbl_methods.submission_id,
    tbl_methods.source_id,
    tbl_methods.local_db_id AS merged_db_id,
    tbl_methods.local_db_id,
    tbl_methods.public_db_id,
    tbl_methods.method_id,
    tbl_methods.biblio_id,
    tbl_methods.date_updated,
    tbl_methods.description,
    tbl_methods.method_abbrev_or_alt_name,
    tbl_methods.method_group_id,
    tbl_methods.method_name,
    tbl_methods.record_type_id,
    tbl_methods.unit_id
   FROM tbl_methods
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_methods.method_id AS merged_db_id,
    0 AS local_db_id,
    tbl_methods.method_id AS public_db_id,
    tbl_methods.method_id,
    tbl_methods.biblio_id,
    tbl_methods.date_updated,
    tbl_methods.description,
    tbl_methods.method_abbrev_or_alt_name,
    tbl_methods.method_group_id,
    tbl_methods.method_name,
    tbl_methods.record_type_id,
    tbl_methods.unit_id
   FROM public.tbl_methods;


--
-- Name: view_clearinghouse_dataset_measured_values; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_clearinghouse_dataset_measured_values AS
 SELECT d.submission_id,
    d.source_id,
    d.local_db_id AS local_dataset_id,
    d.merged_db_id AS merged_dataset_id,
    d.public_db_id AS public_dataset_id,
    ps.sample_group_id,
    ps.merged_db_id AS physical_sample_id,
    ps.local_db_id AS local_physical_sample_id,
    ps.public_db_id AS public_physical_sample_id,
    ps.sample_name,
    m.method_id,
    m.public_db_id AS public_method_id,
    m.method_name,
    aepmm.method_id AS prep_method_id,
    aepmm.public_db_id AS public_prep_method_id,
    aepmm.method_name AS prep_method_name,
    mv.measured_value
   FROM ((((((((view_datasets d
     JOIN view_analysis_entities ae ON (((ae.dataset_id = d.merged_db_id) AND ((ae.submission_id = 0) OR (ae.submission_id = d.submission_id)))))
     JOIN view_measured_values mv ON (((mv.analysis_entity_id = ae.merged_db_id) AND ((mv.submission_id = 0) OR (mv.submission_id = d.submission_id)))))
     JOIN view_physical_samples ps ON (((ps.merged_db_id = ae.physical_sample_id) AND ((ps.submission_id = 0) OR (ps.submission_id = d.submission_id)))))
     JOIN view_methods m ON (((m.merged_db_id = d.method_id) AND ((m.submission_id = 0) OR (m.submission_id = d.submission_id)))))
     LEFT JOIN view_measured_value_dimensions mvd ON (((mvd.measured_value_id = mv.merged_db_id) AND ((mvd.submission_id = 0) OR (mvd.submission_id = d.submission_id)))))
     LEFT JOIN view_dimensions dd ON (((dd.merged_db_id = mvd.dimension_id) AND ((dd.submission_id = 0) OR (dd.submission_id = d.submission_id)))))
     LEFT JOIN view_analysis_entity_prep_methods aepm ON (((aepm.analysis_entity_id = ae.merged_db_id) AND ((aepm.submission_id = 0) OR (aepm.submission_id = d.submission_id)))))
     LEFT JOIN view_methods aepmm ON (((aepmm.merged_db_id = aepm.method_id) AND ((aepmm.submission_id = 0) OR (aepmm.submission_id = d.submission_id)))));


--
-- Name: view_clearinghouse_sead_rdb_schema_pk_columns; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_clearinghouse_sead_rdb_schema_pk_columns AS
 SELECT tbl_clearinghouse_sead_rdb_schema.table_schema,
    tbl_clearinghouse_sead_rdb_schema.table_name,
    tbl_clearinghouse_sead_rdb_schema.column_name
   FROM tbl_clearinghouse_sead_rdb_schema
  WHERE ((tbl_clearinghouse_sead_rdb_schema.is_pk)::text = 'YES'::text);


--
-- Name: view_clearinghouse_local_fk_references; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_clearinghouse_local_fk_references AS
 SELECT v.submission_id,
    c.table_id,
    c.column_id,
    v.fk_local_db_id,
    fk_t.table_id AS fk_table_id,
    fk_c.column_id AS fk_column_id
   FROM (((((tbl_clearinghouse_submission_xml_content_values v
     JOIN tbl_clearinghouse_submission_xml_content_columns c ON ((((c.submission_id = v.submission_id) AND (c.table_id = v.table_id)) AND (c.column_id = v.column_id))))
     JOIN tbl_clearinghouse_submission_tables fk_t ON (((fk_t.table_name_underscored)::text = (c.fk_table_underscored)::text)))
     JOIN view_clearinghouse_sead_rdb_schema_pk_columns s ON ((((s.table_schema)::text = 'public'::text) AND ((s.table_name)::text = (fk_t.table_name_underscored)::text))))
     JOIN tbl_clearinghouse_submission_xml_content_columns fk_c ON ((((fk_c.submission_id = v.submission_id) AND (fk_c.table_id = fk_t.table_id)) AND ((fk_c.column_name_underscored)::text = (s.column_name)::text))))
     JOIN tbl_clearinghouse_submission_xml_content_values fk_v ON (((((fk_v.submission_id = v.submission_id) AND (fk_v.table_id = fk_t.table_id)) AND (fk_v.column_id = fk_c.column_id)) AND (fk_v.local_db_id = v.fk_local_db_id))))
  WHERE (v.fk_flag = true);


SET search_path = public, pg_catalog;

--
-- Name: tbl_collections_or_journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_collections_or_journals (
    collection_or_journal_id integer NOT NULL,
    collection_or_journal_abbrev character varying(128),
    collection_title_or_journal_name character varying,
    date_updated timestamp with time zone DEFAULT now(),
    issn character varying(128),
    number_of_volumes character varying(50),
    publisher_id integer,
    series_editor character varying,
    series_title character varying,
    volume_editor character varying
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_collections_or_journals; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_collections_or_journals AS
 SELECT tbl_collections_or_journals.submission_id,
    tbl_collections_or_journals.source_id,
    tbl_collections_or_journals.local_db_id AS merged_db_id,
    tbl_collections_or_journals.local_db_id,
    tbl_collections_or_journals.public_db_id,
    tbl_collections_or_journals.collection_or_journal_id,
    tbl_collections_or_journals.collection_or_journal_abbrev,
    tbl_collections_or_journals.collection_title_or_journal_name,
    tbl_collections_or_journals.date_updated,
    tbl_collections_or_journals.issn,
    tbl_collections_or_journals.number_of_volumes,
    tbl_collections_or_journals.publisher_id,
    tbl_collections_or_journals.series_editor,
    tbl_collections_or_journals.series_title,
    tbl_collections_or_journals.volume_editor
   FROM tbl_collections_or_journals
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_collections_or_journals.collection_or_journal_id AS merged_db_id,
    0 AS local_db_id,
    tbl_collections_or_journals.collection_or_journal_id AS public_db_id,
    tbl_collections_or_journals.collection_or_journal_id,
    tbl_collections_or_journals.collection_or_journal_abbrev,
    tbl_collections_or_journals.collection_title_or_journal_name,
    tbl_collections_or_journals.date_updated,
    tbl_collections_or_journals.issn,
    tbl_collections_or_journals.number_of_volumes,
    tbl_collections_or_journals.publisher_id,
    tbl_collections_or_journals.series_editor,
    tbl_collections_or_journals.series_title,
    tbl_collections_or_journals.volume_editor
   FROM public.tbl_collections_or_journals;


SET search_path = public, pg_catalog;

--
-- Name: tbl_colours; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_colours (
    colour_id integer NOT NULL,
    colour_name character varying(30) NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    method_id integer NOT NULL,
    rgb integer
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_colours; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_colours AS
 SELECT tbl_colours.submission_id,
    tbl_colours.source_id,
    tbl_colours.local_db_id AS merged_db_id,
    tbl_colours.local_db_id,
    tbl_colours.public_db_id,
    tbl_colours.colour_id,
    tbl_colours.colour_name,
    tbl_colours.date_updated,
    tbl_colours.method_id,
    tbl_colours.rgb
   FROM tbl_colours
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_colours.colour_id AS merged_db_id,
    0 AS local_db_id,
    tbl_colours.colour_id AS public_db_id,
    tbl_colours.colour_id,
    tbl_colours.colour_name,
    tbl_colours.date_updated,
    tbl_colours.method_id,
    tbl_colours.rgb
   FROM public.tbl_colours;


SET search_path = public, pg_catalog;

--
-- Name: tbl_contact_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_contact_types (
    contact_type_id integer NOT NULL,
    contact_type_name character varying(150) NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    description text
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_contact_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_contact_types AS
 SELECT tbl_contact_types.submission_id,
    tbl_contact_types.source_id,
    tbl_contact_types.local_db_id AS merged_db_id,
    tbl_contact_types.local_db_id,
    tbl_contact_types.public_db_id,
    tbl_contact_types.contact_type_id,
    tbl_contact_types.contact_type_name,
    tbl_contact_types.date_updated,
    tbl_contact_types.description
   FROM tbl_contact_types
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_contact_types.contact_type_id AS merged_db_id,
    0 AS local_db_id,
    tbl_contact_types.contact_type_id AS public_db_id,
    tbl_contact_types.contact_type_id,
    tbl_contact_types.contact_type_name,
    tbl_contact_types.date_updated,
    tbl_contact_types.description
   FROM public.tbl_contact_types;


SET search_path = public, pg_catalog;

--
-- Name: tbl_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_contacts (
    contact_id integer NOT NULL,
    address_1 character varying(255),
    address_2 character varying(255),
    location_id integer,
    email character varying,
    first_name character varying(50),
    last_name character varying(100),
    phone_number character varying(50),
    url text,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_contacts; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_contacts AS
 SELECT tbl_contacts.submission_id,
    tbl_contacts.source_id,
    tbl_contacts.local_db_id AS merged_db_id,
    tbl_contacts.local_db_id,
    tbl_contacts.public_db_id,
    tbl_contacts.contact_id,
    tbl_contacts.address_1,
    tbl_contacts.address_2,
    tbl_contacts.location_id,
    tbl_contacts.email,
    tbl_contacts.first_name,
    tbl_contacts.last_name,
    tbl_contacts.phone_number,
    tbl_contacts.url,
    tbl_contacts.date_updated
   FROM tbl_contacts
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_contacts.contact_id AS merged_db_id,
    0 AS local_db_id,
    tbl_contacts.contact_id AS public_db_id,
    tbl_contacts.contact_id,
    tbl_contacts.address_1,
    tbl_contacts.address_2,
    tbl_contacts.location_id,
    tbl_contacts.email,
    tbl_contacts.first_name,
    tbl_contacts.last_name,
    tbl_contacts.phone_number,
    tbl_contacts.url,
    tbl_contacts.date_updated
   FROM public.tbl_contacts;


SET search_path = public, pg_catalog;

--
-- Name: tbl_coordinate_method_dimensions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_coordinate_method_dimensions (
    coordinate_method_dimension_id integer NOT NULL,
    dimension_id integer NOT NULL,
    method_id integer NOT NULL,
    limit_upper numeric(18,10),
    limit_lower numeric(18,10),
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_coordinate_method_dimensions; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_coordinate_method_dimensions AS
 SELECT tbl_coordinate_method_dimensions.submission_id,
    tbl_coordinate_method_dimensions.source_id,
    tbl_coordinate_method_dimensions.local_db_id AS merged_db_id,
    tbl_coordinate_method_dimensions.local_db_id,
    tbl_coordinate_method_dimensions.public_db_id,
    tbl_coordinate_method_dimensions.coordinate_method_dimension_id,
    tbl_coordinate_method_dimensions.dimension_id,
    tbl_coordinate_method_dimensions.method_id,
    tbl_coordinate_method_dimensions.limit_upper,
    tbl_coordinate_method_dimensions.limit_lower,
    tbl_coordinate_method_dimensions.date_updated
   FROM tbl_coordinate_method_dimensions
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_coordinate_method_dimensions.coordinate_method_dimension_id AS merged_db_id,
    0 AS local_db_id,
    tbl_coordinate_method_dimensions.coordinate_method_dimension_id AS public_db_id,
    tbl_coordinate_method_dimensions.coordinate_method_dimension_id,
    tbl_coordinate_method_dimensions.dimension_id,
    tbl_coordinate_method_dimensions.method_id,
    tbl_coordinate_method_dimensions.limit_upper,
    tbl_coordinate_method_dimensions.limit_lower,
    tbl_coordinate_method_dimensions.date_updated
   FROM public.tbl_coordinate_method_dimensions;


SET search_path = public, pg_catalog;

--
-- Name: tbl_data_type_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_data_type_groups (
    data_type_group_id integer NOT NULL,
    data_type_group_name character varying(25),
    date_updated timestamp with time zone DEFAULT now(),
    description text
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_data_type_groups; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_data_type_groups AS
 SELECT tbl_data_type_groups.submission_id,
    tbl_data_type_groups.source_id,
    tbl_data_type_groups.local_db_id AS merged_db_id,
    tbl_data_type_groups.local_db_id,
    tbl_data_type_groups.public_db_id,
    tbl_data_type_groups.data_type_group_id,
    tbl_data_type_groups.data_type_group_name,
    tbl_data_type_groups.date_updated,
    tbl_data_type_groups.description
   FROM tbl_data_type_groups
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_data_type_groups.data_type_group_id AS merged_db_id,
    0 AS local_db_id,
    tbl_data_type_groups.data_type_group_id AS public_db_id,
    tbl_data_type_groups.data_type_group_id,
    tbl_data_type_groups.data_type_group_name,
    tbl_data_type_groups.date_updated,
    tbl_data_type_groups.description
   FROM public.tbl_data_type_groups;


SET search_path = public, pg_catalog;

--
-- Name: tbl_data_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_data_types (
    data_type_id integer NOT NULL,
    data_type_group_id integer NOT NULL,
    data_type_name character varying(25) DEFAULT NULL::character varying,
    date_updated timestamp with time zone DEFAULT now(),
    definition text
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_data_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_data_types AS
 SELECT tbl_data_types.submission_id,
    tbl_data_types.source_id,
    tbl_data_types.local_db_id AS merged_db_id,
    tbl_data_types.local_db_id,
    tbl_data_types.public_db_id,
    tbl_data_types.data_type_id,
    tbl_data_types.data_type_group_id,
    tbl_data_types.data_type_name,
    tbl_data_types.date_updated,
    tbl_data_types.definition
   FROM tbl_data_types
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_data_types.data_type_id AS merged_db_id,
    0 AS local_db_id,
    tbl_data_types.data_type_id AS public_db_id,
    tbl_data_types.data_type_id,
    tbl_data_types.data_type_group_id,
    tbl_data_types.data_type_name,
    tbl_data_types.date_updated,
    tbl_data_types.definition
   FROM public.tbl_data_types;


--
-- Name: view_dataset_abundance_element_names; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_dataset_abundance_element_names AS
 SELECT a.abundance_id,
    array_to_string(array_agg(ael.element_name), ','::text) AS element_name
   FROM (public.tbl_abundances a
     JOIN public.tbl_abundance_elements ael ON ((ael.abundance_element_id = a.abundance_element_id)))
  GROUP BY a.abundance_id;


--
-- Name: view_dataset_abundance_ident_levels; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_dataset_abundance_ident_levels AS
 SELECT al.abundance_id,
    array_to_string(array_agg(l.identification_level_abbrev), ','::text) AS identification_level_abbrev,
    array_to_string(array_agg(l.identification_level_name), ','::text) AS identification_level_name
   FROM (public.tbl_abundance_ident_levels al
     LEFT JOIN public.tbl_identification_levels l ON ((l.identification_level_id = al.identification_level_id)))
  GROUP BY al.abundance_id;


--
-- Name: view_dataset_abundance_modification_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_dataset_abundance_modification_types AS
 SELECT am.abundance_id,
    array_to_string(array_agg(mt.modification_type_description), ','::text) AS modification_type_description,
    array_to_string(array_agg(mt.modification_type_name), ','::text) AS modification_type_name
   FROM (public.tbl_abundance_modifications am
     LEFT JOIN public.tbl_modification_types mt ON ((mt.modification_type_id = am.modification_type_id)))
  GROUP BY am.abundance_id;


--
-- Name: view_dataset_abundances; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_dataset_abundances AS
 SELECT d.dataset_id,
    ttm.taxon_id,
    ttg.genus_name,
    ttm.species,
    ps.physical_sample_id,
    ps.sample_name,
    a.abundance_id,
    a.abundance,
    COALESCE(ael.element_name, ''::text) AS element_name,
    COALESCE(mt.modification_type_name, ''::text) AS modification_type_name,
    COALESCE(il.identification_level_name, ''::text) AS identification_level_name
   FROM ((((((((public.tbl_datasets d
     LEFT JOIN public.tbl_analysis_entities ae ON ((d.dataset_id = ae.dataset_id)))
     LEFT JOIN public.tbl_physical_samples ps ON ((ae.physical_sample_id = ps.physical_sample_id)))
     LEFT JOIN public.tbl_abundances a ON ((a.analysis_entity_id = ae.analysis_entity_id)))
     LEFT JOIN public.tbl_taxa_tree_master ttm ON ((ttm.taxon_id = a.taxon_id)))
     LEFT JOIN public.tbl_taxa_tree_genera ttg ON ((ttg.genus_id = ttm.genus_id)))
     LEFT JOIN view_dataset_abundance_modification_types mt ON ((mt.abundance_id = a.abundance_id)))
     LEFT JOIN view_dataset_abundance_ident_levels il ON ((il.abundance_id = a.abundance_id)))
     LEFT JOIN view_dataset_abundance_element_names ael ON ((ael.abundance_id = a.abundance_id)))
  WHERE (1 = 1);


SET search_path = public, pg_catalog;

--
-- Name: tbl_dataset_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_dataset_contacts (
    dataset_contact_id integer NOT NULL,
    contact_id integer NOT NULL,
    contact_type_id integer NOT NULL,
    dataset_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_dataset_contacts; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_dataset_contacts AS
 SELECT tbl_dataset_contacts.submission_id,
    tbl_dataset_contacts.source_id,
    tbl_dataset_contacts.local_db_id AS merged_db_id,
    tbl_dataset_contacts.local_db_id,
    tbl_dataset_contacts.public_db_id,
    tbl_dataset_contacts.dataset_contact_id,
    tbl_dataset_contacts.contact_id,
    tbl_dataset_contacts.contact_type_id,
    tbl_dataset_contacts.dataset_id,
    tbl_dataset_contacts.date_updated
   FROM tbl_dataset_contacts
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_dataset_contacts.dataset_contact_id AS merged_db_id,
    0 AS local_db_id,
    tbl_dataset_contacts.dataset_contact_id AS public_db_id,
    tbl_dataset_contacts.dataset_contact_id,
    tbl_dataset_contacts.contact_id,
    tbl_dataset_contacts.contact_type_id,
    tbl_dataset_contacts.dataset_id,
    tbl_dataset_contacts.date_updated
   FROM public.tbl_dataset_contacts;


SET search_path = public, pg_catalog;

--
-- Name: tbl_dataset_masters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_dataset_masters (
    master_set_id integer NOT NULL,
    contact_id integer,
    biblio_id integer,
    master_name character varying(100),
    master_notes text,
    url text,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN tbl_dataset_masters.biblio_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_dataset_masters.biblio_id IS 'primary reference for master dataset if available, e.g. buckland & buckland 2006 for bugscep';


--
-- Name: COLUMN tbl_dataset_masters.master_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_dataset_masters.master_name IS 'identification of master dataset, e.g. mal, bugscep, dendrolab';


--
-- Name: COLUMN tbl_dataset_masters.master_notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_dataset_masters.master_notes IS 'description of master dataset, its form (e.g. database, lab) and any other relevant information for tracing it.';


--
-- Name: COLUMN tbl_dataset_masters.url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_dataset_masters.url IS 'website or other url for master dataset, be it a project, lab or... other';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_dataset_masters; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_dataset_masters AS
 SELECT tbl_dataset_masters.submission_id,
    tbl_dataset_masters.source_id,
    tbl_dataset_masters.local_db_id AS merged_db_id,
    tbl_dataset_masters.local_db_id,
    tbl_dataset_masters.public_db_id,
    tbl_dataset_masters.master_set_id,
    tbl_dataset_masters.contact_id,
    tbl_dataset_masters.biblio_id,
    tbl_dataset_masters.master_name,
    tbl_dataset_masters.master_notes,
    tbl_dataset_masters.url,
    tbl_dataset_masters.date_updated
   FROM tbl_dataset_masters
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_dataset_masters.master_set_id AS merged_db_id,
    0 AS local_db_id,
    tbl_dataset_masters.master_set_id AS public_db_id,
    tbl_dataset_masters.master_set_id,
    tbl_dataset_masters.contact_id,
    tbl_dataset_masters.biblio_id,
    tbl_dataset_masters.master_name,
    tbl_dataset_masters.master_notes,
    tbl_dataset_masters.url,
    tbl_dataset_masters.date_updated
   FROM public.tbl_dataset_masters;


--
-- Name: view_dataset_measured_values; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_dataset_measured_values AS
 SELECT d.dataset_id,
    ps.physical_sample_id,
    ps.sample_group_id,
    ps.sample_name,
    m.method_id,
    m.method_name,
    aepmm.method_id AS prep_method_id,
    aepmm.method_name AS prep_method_name,
    mv.measured_value
   FROM ((((((((public.tbl_datasets d
     JOIN public.tbl_analysis_entities ae ON ((ae.dataset_id = d.dataset_id)))
     JOIN public.tbl_measured_values mv ON ((mv.analysis_entity_id = ae.analysis_entity_id)))
     JOIN public.tbl_physical_samples ps ON ((ps.physical_sample_id = ae.physical_sample_id)))
     JOIN public.tbl_methods m ON ((m.method_id = d.method_id)))
     LEFT JOIN public.tbl_measured_value_dimensions mvd ON ((mvd.measured_value_id = mv.measured_value_id)))
     LEFT JOIN public.tbl_dimensions dd ON ((dd.dimension_id = mvd.dimension_id)))
     LEFT JOIN public.tbl_analysis_entity_prep_methods aepm ON ((aepm.analysis_entity_id = ae.analysis_entity_id)))
     LEFT JOIN public.tbl_methods aepmm ON ((aepmm.method_id = aepm.method_id)));


SET search_path = public, pg_catalog;

--
-- Name: tbl_dataset_submission_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_dataset_submission_types (
    submission_type_id integer NOT NULL,
    submission_type character varying(60) NOT NULL,
    description text,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN tbl_dataset_submission_types.submission_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_dataset_submission_types.submission_type IS 'descriptive name for type of submission, e.g. original submission, ingestion from another database';


--
-- Name: COLUMN tbl_dataset_submission_types.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_dataset_submission_types.description IS 'explanation of submission type, explaining clearly data ingestion mechanism';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_dataset_submission_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_dataset_submission_types AS
 SELECT tbl_dataset_submission_types.submission_id,
    tbl_dataset_submission_types.source_id,
    tbl_dataset_submission_types.local_db_id AS merged_db_id,
    tbl_dataset_submission_types.local_db_id,
    tbl_dataset_submission_types.public_db_id,
    tbl_dataset_submission_types.submission_type_id,
    tbl_dataset_submission_types.submission_type,
    tbl_dataset_submission_types.description,
    tbl_dataset_submission_types.date_updated
   FROM tbl_dataset_submission_types
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_dataset_submission_types.submission_type_id AS merged_db_id,
    0 AS local_db_id,
    tbl_dataset_submission_types.submission_type_id AS public_db_id,
    tbl_dataset_submission_types.submission_type_id,
    tbl_dataset_submission_types.submission_type,
    tbl_dataset_submission_types.description,
    tbl_dataset_submission_types.date_updated
   FROM public.tbl_dataset_submission_types;


SET search_path = public, pg_catalog;

--
-- Name: tbl_dataset_submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_dataset_submissions (
    dataset_submission_id integer NOT NULL,
    dataset_id integer NOT NULL,
    submission_type_id integer NOT NULL,
    contact_id integer NOT NULL,
    date_submitted date NOT NULL,
    notes text,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN tbl_dataset_submissions.notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_dataset_submissions.notes IS 'any details of submission not covered by submission_type information, such as name of source from which submission originates if not covered elsewhere in database, e.g. from bugscep';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_dataset_submissions; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_dataset_submissions AS
 SELECT tbl_dataset_submissions.submission_id,
    tbl_dataset_submissions.source_id,
    tbl_dataset_submissions.local_db_id AS merged_db_id,
    tbl_dataset_submissions.local_db_id,
    tbl_dataset_submissions.public_db_id,
    tbl_dataset_submissions.dataset_submission_id,
    tbl_dataset_submissions.dataset_id,
    tbl_dataset_submissions.submission_type_id,
    tbl_dataset_submissions.contact_id,
    tbl_dataset_submissions.date_submitted,
    tbl_dataset_submissions.notes,
    tbl_dataset_submissions.date_updated
   FROM tbl_dataset_submissions
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_dataset_submissions.dataset_submission_id AS merged_db_id,
    0 AS local_db_id,
    tbl_dataset_submissions.dataset_submission_id AS public_db_id,
    tbl_dataset_submissions.dataset_submission_id,
    tbl_dataset_submissions.dataset_id,
    tbl_dataset_submissions.submission_type_id,
    tbl_dataset_submissions.contact_id,
    tbl_dataset_submissions.date_submitted,
    tbl_dataset_submissions.notes,
    tbl_dataset_submissions.date_updated
   FROM public.tbl_dataset_submissions;


SET search_path = public, pg_catalog;

--
-- Name: tbl_dating_labs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_dating_labs (
    dating_lab_id integer NOT NULL,
    contact_id integer,
    international_lab_id character varying(10) NOT NULL,
    lab_name character varying(100) DEFAULT NULL::character varying,
    country_id integer,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE tbl_dating_labs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_dating_labs IS '20120504pib: reduced this table and linked to tbl_contacts for address related data';


--
-- Name: COLUMN tbl_dating_labs.contact_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_dating_labs.contact_id IS 'address details are stored in tbl_contacts';


--
-- Name: COLUMN tbl_dating_labs.international_lab_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_dating_labs.international_lab_id IS 'international standard radiocarbon lab identifier.
from http://www.radiocarbon.org/info/labcodes.html';


--
-- Name: COLUMN tbl_dating_labs.lab_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_dating_labs.lab_name IS 'international standard name of radiocarbon lab, from http://www.radiocarbon.org/info/labcodes.html';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_dating_labs; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_dating_labs AS
 SELECT tbl_dating_labs.submission_id,
    tbl_dating_labs.source_id,
    tbl_dating_labs.local_db_id AS merged_db_id,
    tbl_dating_labs.local_db_id,
    tbl_dating_labs.public_db_id,
    tbl_dating_labs.dating_lab_id,
    tbl_dating_labs.contact_id,
    tbl_dating_labs.international_lab_id,
    tbl_dating_labs.lab_name,
    tbl_dating_labs.country_id,
    tbl_dating_labs.date_updated
   FROM tbl_dating_labs
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_dating_labs.dating_lab_id AS merged_db_id,
    0 AS local_db_id,
    tbl_dating_labs.dating_lab_id AS public_db_id,
    tbl_dating_labs.dating_lab_id,
    tbl_dating_labs.contact_id,
    tbl_dating_labs.international_lab_id,
    tbl_dating_labs.lab_name,
    tbl_dating_labs.country_id,
    tbl_dating_labs.date_updated
   FROM public.tbl_dating_labs;


SET search_path = public, pg_catalog;

--
-- Name: tbl_dating_material; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_dating_material (
    dating_material_id integer NOT NULL,
    geochron_id integer NOT NULL,
    taxon_id integer,
    material_dated character varying,
    description text,
    abundance_element_id integer,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE tbl_dating_material; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_dating_material IS '20130722PIB: Added field date_updated';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_dating_material; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_dating_material AS
 SELECT tbl_dating_material.submission_id,
    tbl_dating_material.source_id,
    tbl_dating_material.local_db_id AS merged_db_id,
    tbl_dating_material.local_db_id,
    tbl_dating_material.public_db_id,
    tbl_dating_material.dating_material_id,
    tbl_dating_material.geochron_id,
    tbl_dating_material.taxon_id,
    tbl_dating_material.material_dated,
    tbl_dating_material.description,
    tbl_dating_material.abundance_element_id,
    tbl_dating_material.date_updated
   FROM tbl_dating_material
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_dating_material.dating_material_id AS merged_db_id,
    0 AS local_db_id,
    tbl_dating_material.dating_material_id AS public_db_id,
    tbl_dating_material.dating_material_id,
    tbl_dating_material.geochron_id,
    tbl_dating_material.taxon_id,
    tbl_dating_material.material_dated,
    tbl_dating_material.description,
    tbl_dating_material.abundance_element_id,
    tbl_dating_material.date_updated
   FROM public.tbl_dating_material;


SET search_path = public, pg_catalog;

--
-- Name: tbl_dating_uncertainty; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_dating_uncertainty (
    dating_uncertainty_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    description text,
    uncertainty character varying
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_dating_uncertainty; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_dating_uncertainty AS
 SELECT tbl_dating_uncertainty.submission_id,
    tbl_dating_uncertainty.source_id,
    tbl_dating_uncertainty.local_db_id AS merged_db_id,
    tbl_dating_uncertainty.local_db_id,
    tbl_dating_uncertainty.public_db_id,
    tbl_dating_uncertainty.dating_uncertainty_id,
    tbl_dating_uncertainty.date_updated,
    tbl_dating_uncertainty.description,
    tbl_dating_uncertainty.uncertainty
   FROM tbl_dating_uncertainty
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_dating_uncertainty.dating_uncertainty_id AS merged_db_id,
    0 AS local_db_id,
    tbl_dating_uncertainty.dating_uncertainty_id AS public_db_id,
    tbl_dating_uncertainty.dating_uncertainty_id,
    tbl_dating_uncertainty.date_updated,
    tbl_dating_uncertainty.description,
    tbl_dating_uncertainty.uncertainty
   FROM public.tbl_dating_uncertainty;


SET search_path = public, pg_catalog;

--
-- Name: tbl_dendro; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_dendro (
    dendro_id integer NOT NULL,
    analysis_entity_id integer NOT NULL,
    dendro_measurement_id integer NOT NULL,
    measurement_value character varying NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_dendro; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_dendro AS
 SELECT tbl_dendro.submission_id,
    tbl_dendro.source_id,
    tbl_dendro.local_db_id AS merged_db_id,
    tbl_dendro.local_db_id,
    tbl_dendro.public_db_id,
    tbl_dendro.dendro_id,
    tbl_dendro.analysis_entity_id,
    tbl_dendro.dendro_measurement_id,
    tbl_dendro.measurement_value,
    tbl_dendro.date_updated
   FROM tbl_dendro
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_dendro.dendro_id AS merged_db_id,
    0 AS local_db_id,
    tbl_dendro.dendro_id AS public_db_id,
    tbl_dendro.dendro_id,
    tbl_dendro.analysis_entity_id,
    tbl_dendro.dendro_measurement_id,
    tbl_dendro.measurement_value,
    tbl_dendro.date_updated
   FROM public.tbl_dendro;


SET search_path = public, pg_catalog;

--
-- Name: tbl_dendro_date_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_dendro_date_notes (
    dendro_date_note_id integer NOT NULL,
    dendro_date_id integer NOT NULL,
    note text,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_dendro_date_notes; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_dendro_date_notes AS
 SELECT tbl_dendro_date_notes.submission_id,
    tbl_dendro_date_notes.source_id,
    tbl_dendro_date_notes.local_db_id AS merged_db_id,
    tbl_dendro_date_notes.local_db_id,
    tbl_dendro_date_notes.public_db_id,
    tbl_dendro_date_notes.dendro_date_note_id,
    tbl_dendro_date_notes.dendro_date_id,
    tbl_dendro_date_notes.note,
    tbl_dendro_date_notes.date_updated
   FROM tbl_dendro_date_notes
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_dendro_date_notes.dendro_date_note_id AS merged_db_id,
    0 AS local_db_id,
    tbl_dendro_date_notes.dendro_date_note_id AS public_db_id,
    tbl_dendro_date_notes.dendro_date_note_id,
    tbl_dendro_date_notes.dendro_date_id,
    tbl_dendro_date_notes.note,
    tbl_dendro_date_notes.date_updated
   FROM public.tbl_dendro_date_notes;


SET search_path = public, pg_catalog;

--
-- Name: tbl_dendro_dates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_dendro_dates (
    dendro_date_id integer NOT NULL,
    analysis_entity_id integer NOT NULL,
    cal_age_younger integer,
    dating_uncertainty_id integer,
    years_type_id integer,
    error integer,
    season_or_qualifier_id integer,
    date_updated timestamp with time zone DEFAULT now(),
    cal_age_older integer
);


--
-- Name: TABLE tbl_dendro_dates; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_dendro_dates IS '20130722PIB: Added field dating_uncertainty_id to cater for >< etc.
20130722PIB: prefixed fieldnames age_younger and age_older with "cal_" to conform with equivalent names in other tables';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_dendro_dates; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_dendro_dates AS
 SELECT tbl_dendro_dates.submission_id,
    tbl_dendro_dates.source_id,
    tbl_dendro_dates.local_db_id AS merged_db_id,
    tbl_dendro_dates.local_db_id,
    tbl_dendro_dates.public_db_id,
    tbl_dendro_dates.dendro_date_id,
    tbl_dendro_dates.analysis_entity_id,
    tbl_dendro_dates.cal_age_younger,
    tbl_dendro_dates.dating_uncertainty_id,
    tbl_dendro_dates.years_type_id,
    tbl_dendro_dates.error,
    tbl_dendro_dates.season_or_qualifier_id,
    tbl_dendro_dates.date_updated,
    tbl_dendro_dates.cal_age_older
   FROM tbl_dendro_dates
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_dendro_dates.dendro_date_id AS merged_db_id,
    0 AS local_db_id,
    tbl_dendro_dates.dendro_date_id AS public_db_id,
    tbl_dendro_dates.dendro_date_id,
    tbl_dendro_dates.analysis_entity_id,
    tbl_dendro_dates.cal_age_younger,
    tbl_dendro_dates.dating_uncertainty_id,
    tbl_dendro_dates.years_type_id,
    tbl_dendro_dates.error,
    tbl_dendro_dates.season_or_qualifier_id,
    tbl_dendro_dates.date_updated,
    tbl_dendro_dates.cal_age_older
   FROM public.tbl_dendro_dates;


SET search_path = public, pg_catalog;

--
-- Name: tbl_dendro_measurement_lookup; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_dendro_measurement_lookup (
    dendro_measurement_lookup_id integer NOT NULL,
    dendro_measurement_id integer NOT NULL,
    value character varying NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_dendro_measurement_lookup; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_dendro_measurement_lookup AS
 SELECT tbl_dendro_measurement_lookup.submission_id,
    tbl_dendro_measurement_lookup.source_id,
    tbl_dendro_measurement_lookup.local_db_id AS merged_db_id,
    tbl_dendro_measurement_lookup.local_db_id,
    tbl_dendro_measurement_lookup.public_db_id,
    tbl_dendro_measurement_lookup.dendro_measurement_lookup_id,
    tbl_dendro_measurement_lookup.dendro_measurement_id,
    tbl_dendro_measurement_lookup.value,
    tbl_dendro_measurement_lookup.date_updated
   FROM tbl_dendro_measurement_lookup
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_dendro_measurement_lookup.dendro_measurement_lookup_id AS merged_db_id,
    0 AS local_db_id,
    tbl_dendro_measurement_lookup.dendro_measurement_lookup_id AS public_db_id,
    tbl_dendro_measurement_lookup.dendro_measurement_lookup_id,
    tbl_dendro_measurement_lookup.dendro_measurement_id,
    tbl_dendro_measurement_lookup.value,
    tbl_dendro_measurement_lookup.date_updated
   FROM public.tbl_dendro_measurement_lookup;


SET search_path = public, pg_catalog;

--
-- Name: tbl_dendro_measurements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_dendro_measurements (
    dendro_measurement_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    method_id integer
);


--
-- Name: TABLE tbl_dendro_measurements; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_dendro_measurements IS 'Type=lookup';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_dendro_measurements; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_dendro_measurements AS
 SELECT tbl_dendro_measurements.submission_id,
    tbl_dendro_measurements.source_id,
    tbl_dendro_measurements.local_db_id AS merged_db_id,
    tbl_dendro_measurements.local_db_id,
    tbl_dendro_measurements.public_db_id,
    tbl_dendro_measurements.dendro_measurement_id,
    tbl_dendro_measurements.date_updated,
    tbl_dendro_measurements.method_id
   FROM tbl_dendro_measurements
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_dendro_measurements.dendro_measurement_id AS merged_db_id,
    0 AS local_db_id,
    tbl_dendro_measurements.dendro_measurement_id AS public_db_id,
    tbl_dendro_measurements.dendro_measurement_id,
    tbl_dendro_measurements.date_updated,
    tbl_dendro_measurements.method_id
   FROM public.tbl_dendro_measurements;


SET search_path = public, pg_catalog;

--
-- Name: tbl_ecocode_definitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_ecocode_definitions (
    ecocode_definition_id integer NOT NULL,
    abbreviation character varying(10) DEFAULT NULL::character varying,
    date_updated timestamp with time zone DEFAULT now(),
    definition text,
    ecocode_group_id integer DEFAULT 0,
    name character varying(150) DEFAULT NULL::character varying,
    notes text,
    sort_order smallint DEFAULT 0
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_ecocode_definitions; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_ecocode_definitions AS
 SELECT tbl_ecocode_definitions.submission_id,
    tbl_ecocode_definitions.source_id,
    tbl_ecocode_definitions.local_db_id AS merged_db_id,
    tbl_ecocode_definitions.local_db_id,
    tbl_ecocode_definitions.public_db_id,
    tbl_ecocode_definitions.ecocode_definition_id,
    tbl_ecocode_definitions.abbreviation,
    tbl_ecocode_definitions.date_updated,
    tbl_ecocode_definitions.definition,
    tbl_ecocode_definitions.ecocode_group_id,
    tbl_ecocode_definitions.label,
    tbl_ecocode_definitions.notes,
    tbl_ecocode_definitions.sort_order
   FROM tbl_ecocode_definitions
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_ecocode_definitions.ecocode_definition_id AS merged_db_id,
    0 AS local_db_id,
    tbl_ecocode_definitions.ecocode_definition_id AS public_db_id,
    tbl_ecocode_definitions.ecocode_definition_id,
    tbl_ecocode_definitions.abbreviation,
    tbl_ecocode_definitions.date_updated,
    tbl_ecocode_definitions.definition,
    tbl_ecocode_definitions.ecocode_group_id,
    tbl_ecocode_definitions.name AS label,
    tbl_ecocode_definitions.notes,
    tbl_ecocode_definitions.sort_order
   FROM public.tbl_ecocode_definitions;


SET search_path = public, pg_catalog;

--
-- Name: tbl_ecocode_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_ecocode_groups (
    ecocode_group_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    definition text DEFAULT NULL::character varying,
    ecocode_system_id integer DEFAULT 0,
    name character varying(150) DEFAULT NULL::character varying,
    abbreviation character varying(255)
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_ecocode_groups; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_ecocode_groups AS
 SELECT tbl_ecocode_groups.submission_id,
    tbl_ecocode_groups.source_id,
    tbl_ecocode_groups.local_db_id AS merged_db_id,
    tbl_ecocode_groups.local_db_id,
    tbl_ecocode_groups.public_db_id,
    tbl_ecocode_groups.ecocode_group_id,
    tbl_ecocode_groups.date_updated,
    tbl_ecocode_groups.definition,
    tbl_ecocode_groups.ecocode_system_id,
    tbl_ecocode_groups.label
   FROM tbl_ecocode_groups
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_ecocode_groups.ecocode_group_id AS merged_db_id,
    0 AS local_db_id,
    tbl_ecocode_groups.ecocode_group_id AS public_db_id,
    tbl_ecocode_groups.ecocode_group_id,
    tbl_ecocode_groups.date_updated,
    tbl_ecocode_groups.definition,
    tbl_ecocode_groups.ecocode_system_id,
    tbl_ecocode_groups.name AS label
   FROM public.tbl_ecocode_groups;


SET search_path = public, pg_catalog;

--
-- Name: tbl_ecocode_systems; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_ecocode_systems (
    ecocode_system_id integer NOT NULL,
    biblio_id integer,
    date_updated timestamp with time zone DEFAULT now(),
    definition text DEFAULT NULL::character varying,
    name character varying(50) DEFAULT NULL::character varying,
    notes text
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_ecocode_systems; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_ecocode_systems AS
 SELECT tbl_ecocode_systems.submission_id,
    tbl_ecocode_systems.source_id,
    tbl_ecocode_systems.local_db_id AS merged_db_id,
    tbl_ecocode_systems.local_db_id,
    tbl_ecocode_systems.public_db_id,
    tbl_ecocode_systems.ecocode_system_id,
    tbl_ecocode_systems.biblio_id,
    tbl_ecocode_systems.date_updated,
    tbl_ecocode_systems.definition,
    tbl_ecocode_systems.name,
    tbl_ecocode_systems.notes
   FROM tbl_ecocode_systems
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_ecocode_systems.ecocode_system_id AS merged_db_id,
    0 AS local_db_id,
    tbl_ecocode_systems.ecocode_system_id AS public_db_id,
    tbl_ecocode_systems.ecocode_system_id,
    tbl_ecocode_systems.biblio_id,
    tbl_ecocode_systems.date_updated,
    tbl_ecocode_systems.definition,
    tbl_ecocode_systems.name,
    tbl_ecocode_systems.notes
   FROM public.tbl_ecocode_systems;


SET search_path = public, pg_catalog;

--
-- Name: tbl_ecocodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_ecocodes (
    ecocode_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    ecocode_definition_id integer DEFAULT 0,
    taxon_id integer DEFAULT 0
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_ecocodes; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_ecocodes AS
 SELECT tbl_ecocodes.submission_id,
    tbl_ecocodes.source_id,
    tbl_ecocodes.local_db_id AS merged_db_id,
    tbl_ecocodes.local_db_id,
    tbl_ecocodes.public_db_id,
    tbl_ecocodes.ecocode_id,
    tbl_ecocodes.date_updated,
    tbl_ecocodes.ecocode_definition_id,
    tbl_ecocodes.taxon_id
   FROM tbl_ecocodes
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_ecocodes.ecocode_id AS merged_db_id,
    0 AS local_db_id,
    tbl_ecocodes.ecocode_id AS public_db_id,
    tbl_ecocodes.ecocode_id,
    tbl_ecocodes.date_updated,
    tbl_ecocodes.ecocode_definition_id,
    tbl_ecocodes.taxon_id
   FROM public.tbl_ecocodes;


SET search_path = public, pg_catalog;

--
-- Name: tbl_feature_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_feature_types (
    feature_type_id integer NOT NULL,
    feature_type_name character varying(128),
    feature_type_description text,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_feature_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_feature_types AS
 SELECT tbl_feature_types.submission_id,
    tbl_feature_types.source_id,
    tbl_feature_types.local_db_id AS merged_db_id,
    tbl_feature_types.local_db_id,
    tbl_feature_types.public_db_id,
    tbl_feature_types.feature_type_id,
    tbl_feature_types.feature_type_name,
    tbl_feature_types.feature_type_description,
    tbl_feature_types.date_updated
   FROM tbl_feature_types
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_feature_types.feature_type_id AS merged_db_id,
    0 AS local_db_id,
    tbl_feature_types.feature_type_id AS public_db_id,
    tbl_feature_types.feature_type_id,
    tbl_feature_types.feature_type_name,
    tbl_feature_types.feature_type_description,
    tbl_feature_types.date_updated
   FROM public.tbl_feature_types;


SET search_path = public, pg_catalog;

--
-- Name: tbl_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_features (
    feature_id integer NOT NULL,
    feature_type_id integer NOT NULL,
    feature_name character varying,
    feature_description text,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN tbl_features.feature_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_features.feature_name IS 'estabilished reference name/number for the feature (note: not the sample). e.g. well 47, anl.3, c107.
remember that a sample can come from multiple features (e.g. c107 in well 47) but each feature should have a separate record.';


--
-- Name: COLUMN tbl_features.feature_description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_features.feature_description IS 'description of the feature. may include any field notes, lab notes or interpretation information useful for interpreting the sample data.';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_features; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_features AS
 SELECT tbl_features.submission_id,
    tbl_features.source_id,
    tbl_features.local_db_id AS merged_db_id,
    tbl_features.local_db_id,
    tbl_features.public_db_id,
    tbl_features.feature_id,
    tbl_features.feature_type_id,
    tbl_features.feature_name,
    tbl_features.feature_description,
    tbl_features.date_updated
   FROM tbl_features
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_features.feature_id AS merged_db_id,
    0 AS local_db_id,
    tbl_features.feature_id AS public_db_id,
    tbl_features.feature_id,
    tbl_features.feature_type_id,
    tbl_features.feature_name,
    tbl_features.feature_description,
    tbl_features.date_updated
   FROM public.tbl_features;


SET search_path = public, pg_catalog;

--
-- Name: tbl_geochron_refs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_geochron_refs (
    geochron_ref_id integer NOT NULL,
    geochron_id integer NOT NULL,
    biblio_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN tbl_geochron_refs.biblio_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_geochron_refs.biblio_id IS 'reference for specific date';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_geochron_refs; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_geochron_refs AS
 SELECT tbl_geochron_refs.submission_id,
    tbl_geochron_refs.source_id,
    tbl_geochron_refs.local_db_id AS merged_db_id,
    tbl_geochron_refs.local_db_id,
    tbl_geochron_refs.public_db_id,
    tbl_geochron_refs.geochron_ref_id,
    tbl_geochron_refs.geochron_id,
    tbl_geochron_refs.biblio_id,
    tbl_geochron_refs.date_updated
   FROM tbl_geochron_refs
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_geochron_refs.geochron_ref_id AS merged_db_id,
    0 AS local_db_id,
    tbl_geochron_refs.geochron_ref_id AS public_db_id,
    tbl_geochron_refs.geochron_ref_id,
    tbl_geochron_refs.geochron_id,
    tbl_geochron_refs.biblio_id,
    tbl_geochron_refs.date_updated
   FROM public.tbl_geochron_refs;


SET search_path = public, pg_catalog;

--
-- Name: tbl_geochronology; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_geochronology (
    geochron_id integer NOT NULL,
    analysis_entity_id integer NOT NULL,
    dating_lab_id integer,
    lab_number character varying(40),
    age numeric(20,5),
    error_older numeric(20,5),
    error_younger numeric(20,5),
    delta_13c numeric(10,5),
    notes text,
    date_updated timestamp with time zone DEFAULT now(),
    dating_uncertainty_id integer
);


--
-- Name: TABLE tbl_geochronology; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_geochronology IS '20130722PIB: Altered field uncertainty (varchar) to dating_uncertainty_id and linked to tbl_dating_uncertainty to enable lookup of uncertainty modifiers for dates';


--
-- Name: COLUMN tbl_geochronology.age; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_geochronology.age IS 'radiocarbon (or other radiometric) age.';


--
-- Name: COLUMN tbl_geochronology.error_older; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_geochronology.error_older IS 'plus (+) side of the measured error (set same as error_younger if standard +/- error)';


--
-- Name: COLUMN tbl_geochronology.error_younger; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_geochronology.error_younger IS 'minus (-) side of the measured error (set same as error_younger if standard +/- error)';


--
-- Name: COLUMN tbl_geochronology.delta_13c; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_geochronology.delta_13c IS 'delta 13c where available for calibration correction.';


--
-- Name: COLUMN tbl_geochronology.notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_geochronology.notes IS 'notes specific to this date';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_geochronology; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_geochronology AS
 SELECT tbl_geochronology.submission_id,
    tbl_geochronology.source_id,
    tbl_geochronology.local_db_id AS merged_db_id,
    tbl_geochronology.local_db_id,
    tbl_geochronology.public_db_id,
    tbl_geochronology.geochron_id,
    tbl_geochronology.analysis_entity_id,
    tbl_geochronology.dating_lab_id,
    tbl_geochronology.lab_number,
    tbl_geochronology.age,
    tbl_geochronology.error_older,
    tbl_geochronology.error_younger,
    tbl_geochronology.delta_13c,
    tbl_geochronology.notes,
    tbl_geochronology.date_updated,
    tbl_geochronology.dating_uncertainty_id
   FROM tbl_geochronology
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_geochronology.geochron_id AS merged_db_id,
    0 AS local_db_id,
    tbl_geochronology.geochron_id AS public_db_id,
    tbl_geochronology.geochron_id,
    tbl_geochronology.analysis_entity_id,
    tbl_geochronology.dating_lab_id,
    tbl_geochronology.lab_number,
    tbl_geochronology.age,
    tbl_geochronology.error_older,
    tbl_geochronology.error_younger,
    tbl_geochronology.delta_13c,
    tbl_geochronology.notes,
    tbl_geochronology.date_updated,
    tbl_geochronology.dating_uncertainty_id
   FROM public.tbl_geochronology;


SET search_path = public, pg_catalog;

--
-- Name: tbl_horizons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_horizons (
    horizon_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    description text,
    horizon_name character varying(15) NOT NULL,
    method_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_horizons; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_horizons AS
 SELECT tbl_horizons.submission_id,
    tbl_horizons.source_id,
    tbl_horizons.local_db_id AS merged_db_id,
    tbl_horizons.local_db_id,
    tbl_horizons.public_db_id,
    tbl_horizons.horizon_id,
    tbl_horizons.date_updated,
    tbl_horizons.description,
    tbl_horizons.horizon_name,
    tbl_horizons.method_id
   FROM tbl_horizons
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_horizons.horizon_id AS merged_db_id,
    0 AS local_db_id,
    tbl_horizons.horizon_id AS public_db_id,
    tbl_horizons.horizon_id,
    tbl_horizons.date_updated,
    tbl_horizons.description,
    tbl_horizons.horizon_name,
    tbl_horizons.method_id
   FROM public.tbl_horizons;


SET search_path = public, pg_catalog;

--
-- Name: tbl_image_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_image_types (
    image_type_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    description text,
    image_type character varying(40) NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_image_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_image_types AS
 SELECT tbl_image_types.submission_id,
    tbl_image_types.source_id,
    tbl_image_types.local_db_id AS merged_db_id,
    tbl_image_types.local_db_id,
    tbl_image_types.public_db_id,
    tbl_image_types.image_type_id,
    tbl_image_types.date_updated,
    tbl_image_types.description,
    tbl_image_types.image_type
   FROM tbl_image_types
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_image_types.image_type_id AS merged_db_id,
    0 AS local_db_id,
    tbl_image_types.image_type_id AS public_db_id,
    tbl_image_types.image_type_id,
    tbl_image_types.date_updated,
    tbl_image_types.description,
    tbl_image_types.image_type
   FROM public.tbl_image_types;


SET search_path = public, pg_catalog;

--
-- Name: tbl_imported_taxa_replacements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_imported_taxa_replacements (
    imported_taxa_replacement_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    imported_name_replaced character varying(100) NOT NULL,
    taxon_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_imported_taxa_replacements; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_imported_taxa_replacements AS
 SELECT tbl_imported_taxa_replacements.submission_id,
    tbl_imported_taxa_replacements.source_id,
    tbl_imported_taxa_replacements.local_db_id AS merged_db_id,
    tbl_imported_taxa_replacements.local_db_id,
    tbl_imported_taxa_replacements.public_db_id,
    tbl_imported_taxa_replacements.imported_taxa_replacement_id,
    tbl_imported_taxa_replacements.date_updated,
    tbl_imported_taxa_replacements.imported_name_replaced,
    tbl_imported_taxa_replacements.taxon_id
   FROM tbl_imported_taxa_replacements
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_imported_taxa_replacements.imported_taxa_replacement_id AS merged_db_id,
    0 AS local_db_id,
    tbl_imported_taxa_replacements.imported_taxa_replacement_id AS public_db_id,
    tbl_imported_taxa_replacements.imported_taxa_replacement_id,
    tbl_imported_taxa_replacements.date_updated,
    tbl_imported_taxa_replacements.imported_name_replaced,
    tbl_imported_taxa_replacements.taxon_id
   FROM public.tbl_imported_taxa_replacements;


SET search_path = public, pg_catalog;

--
-- Name: tbl_keywords; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_keywords (
    keyword_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    definition text,
    keyword character varying
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_keywords; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_keywords AS
 SELECT tbl_keywords.submission_id,
    tbl_keywords.source_id,
    tbl_keywords.local_db_id AS merged_db_id,
    tbl_keywords.local_db_id,
    tbl_keywords.public_db_id,
    tbl_keywords.keyword_id,
    tbl_keywords.date_updated,
    tbl_keywords.definition,
    tbl_keywords.keyword
   FROM tbl_keywords
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_keywords.keyword_id AS merged_db_id,
    0 AS local_db_id,
    tbl_keywords.keyword_id AS public_db_id,
    tbl_keywords.keyword_id,
    tbl_keywords.date_updated,
    tbl_keywords.definition,
    tbl_keywords.keyword
   FROM public.tbl_keywords;


SET search_path = public, pg_catalog;

--
-- Name: tbl_languages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_languages (
    language_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    language_name_english character varying(100) DEFAULT NULL::character varying,
    language_name_native character varying(100) DEFAULT NULL::character varying
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_languages; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_languages AS
 SELECT tbl_languages.submission_id,
    tbl_languages.source_id,
    tbl_languages.local_db_id AS merged_db_id,
    tbl_languages.local_db_id,
    tbl_languages.public_db_id,
    tbl_languages.language_id,
    tbl_languages.date_updated,
    tbl_languages.language_name_english,
    tbl_languages.language_name_native
   FROM tbl_languages
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_languages.language_id AS merged_db_id,
    0 AS local_db_id,
    tbl_languages.language_id AS public_db_id,
    tbl_languages.language_id,
    tbl_languages.date_updated,
    tbl_languages.language_name_english,
    tbl_languages.language_name_native
   FROM public.tbl_languages;


SET search_path = public, pg_catalog;

--
-- Name: tbl_lithology; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_lithology (
    lithology_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    depth_bottom numeric(20,5),
    depth_top numeric(20,5) NOT NULL,
    description text NOT NULL,
    lower_boundary character varying(255),
    sample_group_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_lithology; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_lithology AS
 SELECT tbl_lithology.submission_id,
    tbl_lithology.source_id,
    tbl_lithology.local_db_id AS merged_db_id,
    tbl_lithology.local_db_id,
    tbl_lithology.public_db_id,
    tbl_lithology.lithology_id,
    tbl_lithology.date_updated,
    tbl_lithology.depth_bottom,
    tbl_lithology.depth_top,
    tbl_lithology.description,
    tbl_lithology.lower_boundary,
    tbl_lithology.sample_group_id
   FROM tbl_lithology
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_lithology.lithology_id AS merged_db_id,
    0 AS local_db_id,
    tbl_lithology.lithology_id AS public_db_id,
    tbl_lithology.lithology_id,
    tbl_lithology.date_updated,
    tbl_lithology.depth_bottom,
    tbl_lithology.depth_top,
    tbl_lithology.description,
    tbl_lithology.lower_boundary,
    tbl_lithology.sample_group_id
   FROM public.tbl_lithology;


SET search_path = public, pg_catalog;

--
-- Name: tbl_location_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_location_types (
    location_type_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    description text,
    location_type character varying(40)
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_location_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_location_types AS
 SELECT tbl_location_types.submission_id,
    tbl_location_types.source_id,
    tbl_location_types.local_db_id AS merged_db_id,
    tbl_location_types.local_db_id,
    tbl_location_types.public_db_id,
    tbl_location_types.location_type_id,
    tbl_location_types.date_updated,
    tbl_location_types.description,
    tbl_location_types.location_type
   FROM tbl_location_types
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_location_types.location_type_id AS merged_db_id,
    0 AS local_db_id,
    tbl_location_types.location_type_id AS public_db_id,
    tbl_location_types.location_type_id,
    tbl_location_types.date_updated,
    tbl_location_types.description,
    tbl_location_types.location_type
   FROM public.tbl_location_types;


SET search_path = public, pg_catalog;

--
-- Name: tbl_locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_locations (
    location_id integer NOT NULL,
    location_name character varying(255) NOT NULL,
    location_type_id integer NOT NULL,
    default_lat_dd numeric(18,10),
    default_long_dd numeric(18,10),
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN tbl_locations.default_lat_dd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_locations.default_lat_dd IS 'default latitude in decimal degrees for location, e.g. mid point of country. leave empty if not known.';


--
-- Name: COLUMN tbl_locations.default_long_dd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_locations.default_long_dd IS 'default longitude in decimal degrees for location, e.g. mid point of country';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_locations; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_locations AS
 SELECT tbl_locations.submission_id,
    tbl_locations.source_id,
    tbl_locations.local_db_id AS merged_db_id,
    tbl_locations.local_db_id,
    tbl_locations.public_db_id,
    tbl_locations.location_id,
    tbl_locations.location_name,
    tbl_locations.location_type_id,
    tbl_locations.default_lat_dd,
    tbl_locations.default_long_dd,
    tbl_locations.date_updated
   FROM tbl_locations
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_locations.location_id AS merged_db_id,
    0 AS local_db_id,
    tbl_locations.location_id AS public_db_id,
    tbl_locations.location_id,
    tbl_locations.location_name,
    tbl_locations.location_type_id,
    tbl_locations.default_lat_dd,
    tbl_locations.default_long_dd,
    tbl_locations.date_updated
   FROM public.tbl_locations;


SET search_path = public, pg_catalog;

--
-- Name: tbl_mcr_names; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_mcr_names (
    taxon_id integer NOT NULL,
    comparison_notes character varying(255) DEFAULT NULL::character varying,
    date_updated timestamp with time zone DEFAULT now(),
    mcr_name_trim character varying(80) DEFAULT NULL::character varying,
    mcr_number smallint DEFAULT 0,
    mcr_species_name character varying(200) DEFAULT NULL::character varying
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_mcr_names; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_mcr_names AS
 SELECT tbl_mcr_names.submission_id,
    tbl_mcr_names.source_id,
    tbl_mcr_names.local_db_id AS merged_db_id,
    tbl_mcr_names.local_db_id,
    tbl_mcr_names.public_db_id,
    tbl_mcr_names.taxon_id,
    tbl_mcr_names.comparison_notes,
    tbl_mcr_names.date_updated,
    tbl_mcr_names.mcr_name_trim,
    tbl_mcr_names.mcr_number,
    tbl_mcr_names.mcr_species_name
   FROM tbl_mcr_names
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_mcr_names.taxon_id AS merged_db_id,
    0 AS local_db_id,
    tbl_mcr_names.taxon_id AS public_db_id,
    tbl_mcr_names.taxon_id,
    tbl_mcr_names.comparison_notes,
    tbl_mcr_names.date_updated,
    tbl_mcr_names.mcr_name_trim,
    tbl_mcr_names.mcr_number,
    tbl_mcr_names.mcr_species_name
   FROM public.tbl_mcr_names;


SET search_path = public, pg_catalog;

--
-- Name: tbl_mcr_summary_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_mcr_summary_data (
    mcr_summary_data_id integer NOT NULL,
    cog_mid_tmax smallint DEFAULT 0,
    cog_mid_trange smallint DEFAULT 0,
    date_updated timestamp with time zone DEFAULT now(),
    taxon_id integer NOT NULL,
    tmax_hi smallint DEFAULT 0,
    tmax_lo smallint DEFAULT 0,
    tmin_hi smallint DEFAULT 0,
    tmin_lo smallint DEFAULT 0,
    trange_hi smallint DEFAULT 0,
    trange_lo smallint DEFAULT 0
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_mcr_summary_data; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_mcr_summary_data AS
 SELECT tbl_mcr_summary_data.submission_id,
    tbl_mcr_summary_data.source_id,
    tbl_mcr_summary_data.local_db_id AS merged_db_id,
    tbl_mcr_summary_data.local_db_id,
    tbl_mcr_summary_data.public_db_id,
    tbl_mcr_summary_data.mcr_summary_data_id,
    tbl_mcr_summary_data.cog_mid_tmax,
    tbl_mcr_summary_data.cog_mid_trange,
    tbl_mcr_summary_data.date_updated,
    tbl_mcr_summary_data.taxon_id,
    tbl_mcr_summary_data.tmax_hi,
    tbl_mcr_summary_data.tmax_lo,
    tbl_mcr_summary_data.tmin_hi,
    tbl_mcr_summary_data.tmin_lo,
    tbl_mcr_summary_data.trange_hi,
    tbl_mcr_summary_data.trange_lo
   FROM tbl_mcr_summary_data
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_mcr_summary_data.mcr_summary_data_id AS merged_db_id,
    0 AS local_db_id,
    tbl_mcr_summary_data.mcr_summary_data_id AS public_db_id,
    tbl_mcr_summary_data.mcr_summary_data_id,
    tbl_mcr_summary_data.cog_mid_tmax,
    tbl_mcr_summary_data.cog_mid_trange,
    tbl_mcr_summary_data.date_updated,
    tbl_mcr_summary_data.taxon_id,
    tbl_mcr_summary_data.tmax_hi,
    tbl_mcr_summary_data.tmax_lo,
    tbl_mcr_summary_data.tmin_hi,
    tbl_mcr_summary_data.tmin_lo,
    tbl_mcr_summary_data.trange_hi,
    tbl_mcr_summary_data.trange_lo
   FROM public.tbl_mcr_summary_data;


SET search_path = public, pg_catalog;

--
-- Name: tbl_mcrdata_birmbeetledat; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_mcrdata_birmbeetledat (
    mcrdata_birmbeetledat_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    mcr_data text,
    mcr_row smallint NOT NULL,
    taxon_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_mcrdata_birmbeetledat; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_mcrdata_birmbeetledat AS
 SELECT tbl_mcrdata_birmbeetledat.submission_id,
    tbl_mcrdata_birmbeetledat.source_id,
    tbl_mcrdata_birmbeetledat.local_db_id AS merged_db_id,
    tbl_mcrdata_birmbeetledat.local_db_id,
    tbl_mcrdata_birmbeetledat.public_db_id,
    tbl_mcrdata_birmbeetledat.mcrdata_birmbeetledat_id,
    tbl_mcrdata_birmbeetledat.date_updated,
    tbl_mcrdata_birmbeetledat.mcr_data,
    tbl_mcrdata_birmbeetledat.mcr_row,
    tbl_mcrdata_birmbeetledat.taxon_id
   FROM tbl_mcrdata_birmbeetledat
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_mcrdata_birmbeetledat.mcrdata_birmbeetledat_id AS merged_db_id,
    0 AS local_db_id,
    tbl_mcrdata_birmbeetledat.mcrdata_birmbeetledat_id AS public_db_id,
    tbl_mcrdata_birmbeetledat.mcrdata_birmbeetledat_id,
    tbl_mcrdata_birmbeetledat.date_updated,
    tbl_mcrdata_birmbeetledat.mcr_data,
    tbl_mcrdata_birmbeetledat.mcr_row,
    tbl_mcrdata_birmbeetledat.taxon_id
   FROM public.tbl_mcrdata_birmbeetledat;


SET search_path = public, pg_catalog;

--
-- Name: tbl_method_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_method_groups (
    method_group_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    description text NOT NULL,
    group_name character varying(100) NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_method_groups; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_method_groups AS
 SELECT tbl_method_groups.submission_id,
    tbl_method_groups.source_id,
    tbl_method_groups.local_db_id AS merged_db_id,
    tbl_method_groups.local_db_id,
    tbl_method_groups.public_db_id,
    tbl_method_groups.method_group_id,
    tbl_method_groups.date_updated,
    tbl_method_groups.description,
    tbl_method_groups.group_name
   FROM tbl_method_groups
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_method_groups.method_group_id AS merged_db_id,
    0 AS local_db_id,
    tbl_method_groups.method_group_id AS public_db_id,
    tbl_method_groups.method_group_id,
    tbl_method_groups.date_updated,
    tbl_method_groups.description,
    tbl_method_groups.group_name
   FROM public.tbl_method_groups;


SET search_path = public, pg_catalog;

--
-- Name: tbl_physical_sample_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_physical_sample_features (
    physical_sample_feature_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    feature_id integer NOT NULL,
    physical_sample_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_physical_sample_features; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_physical_sample_features AS
 SELECT tbl_physical_sample_features.submission_id,
    tbl_physical_sample_features.source_id,
    tbl_physical_sample_features.local_db_id AS merged_db_id,
    tbl_physical_sample_features.local_db_id,
    tbl_physical_sample_features.public_db_id,
    tbl_physical_sample_features.physical_sample_feature_id,
    tbl_physical_sample_features.date_updated,
    tbl_physical_sample_features.feature_id,
    tbl_physical_sample_features.physical_sample_id
   FROM tbl_physical_sample_features
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_physical_sample_features.physical_sample_feature_id AS merged_db_id,
    0 AS local_db_id,
    tbl_physical_sample_features.physical_sample_feature_id AS public_db_id,
    tbl_physical_sample_features.physical_sample_feature_id,
    tbl_physical_sample_features.date_updated,
    tbl_physical_sample_features.feature_id,
    tbl_physical_sample_features.physical_sample_id
   FROM public.tbl_physical_sample_features;


SET search_path = public, pg_catalog;

--
-- Name: tbl_project_stages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_project_stages (
    project_stage_id integer NOT NULL,
    stage_name character varying,
    description text,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN tbl_project_stages.stage_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_project_stages.stage_name IS 'stage of project in investigative cycle, e.g. desktop study, prospection, final excavation';


--
-- Name: COLUMN tbl_project_stages.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_project_stages.description IS 'explanation of stage name term, including details of purpose and general contents';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_project_stages; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_project_stages AS
 SELECT tbl_project_stages.submission_id,
    tbl_project_stages.source_id,
    tbl_project_stages.local_db_id AS merged_db_id,
    tbl_project_stages.local_db_id,
    tbl_project_stages.public_db_id,
    tbl_project_stages.project_stage_id,
    tbl_project_stages.stage_name,
    tbl_project_stages.description,
    tbl_project_stages.date_updated
   FROM tbl_project_stages
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_project_stages.project_stage_id AS merged_db_id,
    0 AS local_db_id,
    tbl_project_stages.project_stage_id AS public_db_id,
    tbl_project_stages.project_stage_id,
    tbl_project_stages.stage_name,
    tbl_project_stages.description,
    tbl_project_stages.date_updated
   FROM public.tbl_project_stages;


SET search_path = public, pg_catalog;

--
-- Name: tbl_project_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_project_types (
    project_type_id integer NOT NULL,
    project_type_name character varying,
    description text,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN tbl_project_types.project_type_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_project_types.project_type_name IS 'descriptive name for project type, e.g. consultancy, research, teaching; also combinations consultancy/teaching';


--
-- Name: COLUMN tbl_project_types.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_project_types.description IS 'project type combinations can be used where appropriate, e.g. teaching/research';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_project_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_project_types AS
 SELECT tbl_project_types.submission_id,
    tbl_project_types.source_id,
    tbl_project_types.local_db_id AS merged_db_id,
    tbl_project_types.local_db_id,
    tbl_project_types.public_db_id,
    tbl_project_types.project_type_id,
    tbl_project_types.project_type_name,
    tbl_project_types.description,
    tbl_project_types.date_updated
   FROM tbl_project_types
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_project_types.project_type_id AS merged_db_id,
    0 AS local_db_id,
    tbl_project_types.project_type_id AS public_db_id,
    tbl_project_types.project_type_id,
    tbl_project_types.project_type_name,
    tbl_project_types.description,
    tbl_project_types.date_updated
   FROM public.tbl_project_types;


SET search_path = public, pg_catalog;

--
-- Name: tbl_projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_projects (
    project_id integer NOT NULL,
    project_type_id integer,
    project_stage_id integer,
    project_name character varying(150),
    project_abbrev_name character varying(25),
    description text,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN tbl_projects.project_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_projects.project_name IS 'name of project (e.g. phil''s phd thesis, malmö ringroad vägverket)';


--
-- Name: COLUMN tbl_projects.project_abbrev_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_projects.project_abbrev_name IS 'optional. abbreviation of project name or acronym (e.g. vgv, swedab)';


--
-- Name: COLUMN tbl_projects.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_projects.description IS 'brief description of project and any useful information for finding out more.';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_projects; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_projects AS
 SELECT tbl_projects.submission_id,
    tbl_projects.source_id,
    tbl_projects.local_db_id AS merged_db_id,
    tbl_projects.local_db_id,
    tbl_projects.public_db_id,
    tbl_projects.project_id,
    tbl_projects.project_type_id,
    tbl_projects.project_stage_id,
    tbl_projects.project_name,
    tbl_projects.project_abbrev_name,
    tbl_projects.description,
    tbl_projects.date_updated
   FROM tbl_projects
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_projects.project_id AS merged_db_id,
    0 AS local_db_id,
    tbl_projects.project_id AS public_db_id,
    tbl_projects.project_id,
    tbl_projects.project_type_id,
    tbl_projects.project_stage_id,
    tbl_projects.project_name,
    tbl_projects.project_abbrev_name,
    tbl_projects.description,
    tbl_projects.date_updated
   FROM public.tbl_projects;


SET search_path = public, pg_catalog;

--
-- Name: tbl_publication_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_publication_types (
    publication_type_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    publication_type character varying(30)
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_publication_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_publication_types AS
 SELECT tbl_publication_types.submission_id,
    tbl_publication_types.source_id,
    tbl_publication_types.local_db_id AS merged_db_id,
    tbl_publication_types.local_db_id,
    tbl_publication_types.public_db_id,
    tbl_publication_types.publication_type_id,
    tbl_publication_types.date_updated,
    tbl_publication_types.publication_type
   FROM tbl_publication_types
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_publication_types.publication_type_id AS merged_db_id,
    0 AS local_db_id,
    tbl_publication_types.publication_type_id AS public_db_id,
    tbl_publication_types.publication_type_id,
    tbl_publication_types.date_updated,
    tbl_publication_types.publication_type
   FROM public.tbl_publication_types;


SET search_path = public, pg_catalog;

--
-- Name: tbl_publishers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_publishers (
    publisher_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    place_of_publishing_house character varying,
    publisher_name character varying(255)
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_publishers; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_publishers AS
 SELECT tbl_publishers.submission_id,
    tbl_publishers.source_id,
    tbl_publishers.local_db_id AS merged_db_id,
    tbl_publishers.local_db_id,
    tbl_publishers.public_db_id,
    tbl_publishers.publisher_id,
    tbl_publishers.date_updated,
    tbl_publishers.place_of_publishing_house,
    tbl_publishers.publisher_name
   FROM tbl_publishers
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_publishers.publisher_id AS merged_db_id,
    0 AS local_db_id,
    tbl_publishers.publisher_id AS public_db_id,
    tbl_publishers.publisher_id,
    tbl_publishers.date_updated,
    tbl_publishers.place_of_publishing_house,
    tbl_publishers.publisher_name
   FROM public.tbl_publishers;


SET search_path = public, pg_catalog;

--
-- Name: tbl_radiocarbon_calibration; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_radiocarbon_calibration (
    radiocarbon_calibration_id integer NOT NULL,
    c14_yr_bp integer NOT NULL,
    cal_yr_bp integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN tbl_radiocarbon_calibration.c14_yr_bp; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_radiocarbon_calibration.c14_yr_bp IS 'mid-point of c14 age.';


--
-- Name: COLUMN tbl_radiocarbon_calibration.cal_yr_bp; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_radiocarbon_calibration.cal_yr_bp IS 'mid-point of calibrated age.';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_radiocarbon_calibration; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_radiocarbon_calibration AS
 SELECT tbl_radiocarbon_calibration.submission_id,
    tbl_radiocarbon_calibration.source_id,
    tbl_radiocarbon_calibration.local_db_id AS merged_db_id,
    tbl_radiocarbon_calibration.local_db_id,
    tbl_radiocarbon_calibration.public_db_id,
    tbl_radiocarbon_calibration.radiocarbon_calibration_id,
    tbl_radiocarbon_calibration.c14_yr_bp,
    tbl_radiocarbon_calibration.cal_yr_bp,
    tbl_radiocarbon_calibration.date_updated
   FROM tbl_radiocarbon_calibration
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_radiocarbon_calibration.radiocarbon_calibration_id AS merged_db_id,
    0 AS local_db_id,
    tbl_radiocarbon_calibration.radiocarbon_calibration_id AS public_db_id,
    tbl_radiocarbon_calibration.radiocarbon_calibration_id,
    tbl_radiocarbon_calibration.c14_yr_bp,
    tbl_radiocarbon_calibration.cal_yr_bp,
    tbl_radiocarbon_calibration.date_updated
   FROM public.tbl_radiocarbon_calibration;


SET search_path = public, pg_catalog;

--
-- Name: tbl_rdb; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_rdb (
    rdb_id integer NOT NULL,
    location_id integer NOT NULL,
    rdb_code_id integer,
    taxon_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN tbl_rdb.location_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_rdb.location_id IS 'geographical source/relevance of the specific code. e.g. the international iucn classification of species in the uk.';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_rdb; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_rdb AS
 SELECT tbl_rdb.submission_id,
    tbl_rdb.source_id,
    tbl_rdb.local_db_id AS merged_db_id,
    tbl_rdb.local_db_id,
    tbl_rdb.public_db_id,
    tbl_rdb.rdb_id,
    tbl_rdb.location_id,
    tbl_rdb.rdb_code_id,
    tbl_rdb.taxon_id,
    tbl_rdb.date_updated
   FROM tbl_rdb
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_rdb.rdb_id AS merged_db_id,
    0 AS local_db_id,
    tbl_rdb.rdb_id AS public_db_id,
    tbl_rdb.rdb_id,
    tbl_rdb.location_id,
    tbl_rdb.rdb_code_id,
    tbl_rdb.taxon_id,
    tbl_rdb.date_updated
   FROM public.tbl_rdb;


SET search_path = public, pg_catalog;

--
-- Name: tbl_rdb_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_rdb_codes (
    rdb_code_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    rdb_category character varying(4) DEFAULT NULL::character varying,
    rdb_definition character varying(200) DEFAULT NULL::character varying,
    rdb_system_id integer DEFAULT 0
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_rdb_codes; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_rdb_codes AS
 SELECT tbl_rdb_codes.submission_id,
    tbl_rdb_codes.source_id,
    tbl_rdb_codes.local_db_id AS merged_db_id,
    tbl_rdb_codes.local_db_id,
    tbl_rdb_codes.public_db_id,
    tbl_rdb_codes.rdb_code_id,
    tbl_rdb_codes.date_updated,
    tbl_rdb_codes.rdb_category,
    tbl_rdb_codes.rdb_definition,
    tbl_rdb_codes.rdb_system_id
   FROM tbl_rdb_codes
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_rdb_codes.rdb_code_id AS merged_db_id,
    0 AS local_db_id,
    tbl_rdb_codes.rdb_code_id AS public_db_id,
    tbl_rdb_codes.rdb_code_id,
    tbl_rdb_codes.date_updated,
    tbl_rdb_codes.rdb_category,
    tbl_rdb_codes.rdb_definition,
    tbl_rdb_codes.rdb_system_id
   FROM public.tbl_rdb_codes;


SET search_path = public, pg_catalog;

--
-- Name: tbl_rdb_systems; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_rdb_systems (
    rdb_system_id integer NOT NULL,
    biblio_id integer NOT NULL,
    location_id integer NOT NULL,
    rdb_first_published smallint,
    rdb_system character varying(10) DEFAULT NULL::character varying,
    rdb_system_date integer,
    rdb_version character varying(10) DEFAULT NULL::character varying,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN tbl_rdb_systems.location_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_rdb_systems.location_id IS 'geaographical relevance of rdb code system, e.g. uk, international, new forest';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_rdb_systems; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_rdb_systems AS
 SELECT tbl_rdb_systems.submission_id,
    tbl_rdb_systems.source_id,
    tbl_rdb_systems.local_db_id AS merged_db_id,
    tbl_rdb_systems.local_db_id,
    tbl_rdb_systems.public_db_id,
    tbl_rdb_systems.rdb_system_id,
    tbl_rdb_systems.biblio_id,
    tbl_rdb_systems.location_id,
    tbl_rdb_systems.rdb_first_published,
    tbl_rdb_systems.rdb_system,
    tbl_rdb_systems.rdb_system_date,
    tbl_rdb_systems.rdb_version,
    tbl_rdb_systems.date_updated
   FROM tbl_rdb_systems
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_rdb_systems.rdb_system_id AS merged_db_id,
    0 AS local_db_id,
    tbl_rdb_systems.rdb_system_id AS public_db_id,
    tbl_rdb_systems.rdb_system_id,
    tbl_rdb_systems.biblio_id,
    tbl_rdb_systems.location_id,
    tbl_rdb_systems.rdb_first_published,
    tbl_rdb_systems.rdb_system,
    tbl_rdb_systems.rdb_system_date,
    tbl_rdb_systems.rdb_version,
    tbl_rdb_systems.date_updated
   FROM public.tbl_rdb_systems;


SET search_path = public, pg_catalog;

--
-- Name: tbl_record_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_record_types (
    record_type_id integer NOT NULL,
    record_type_name character varying(50) DEFAULT NULL::character varying,
    record_type_description text,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE tbl_record_types; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_record_types IS 'may also use this to group methods - e.g. phosphate analyses (whereas tbl_method_groups would store the larger group "palaeo chemical/physical" methods)';


--
-- Name: COLUMN tbl_record_types.record_type_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_record_types.record_type_name IS 'short name of proxy/proxies in group';


--
-- Name: COLUMN tbl_record_types.record_type_description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_record_types.record_type_description IS 'detailed description of group and explanation for grouping';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_record_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_record_types AS
 SELECT tbl_record_types.submission_id,
    tbl_record_types.source_id,
    tbl_record_types.local_db_id AS merged_db_id,
    tbl_record_types.local_db_id,
    tbl_record_types.public_db_id,
    tbl_record_types.record_type_id,
    tbl_record_types.record_type_name,
    tbl_record_types.record_type_description,
    tbl_record_types.date_updated
   FROM tbl_record_types
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_record_types.record_type_id AS merged_db_id,
    0 AS local_db_id,
    tbl_record_types.record_type_id AS public_db_id,
    tbl_record_types.record_type_id,
    tbl_record_types.record_type_name,
    tbl_record_types.record_type_description,
    tbl_record_types.date_updated
   FROM public.tbl_record_types;


SET search_path = public, pg_catalog;

--
-- Name: tbl_relative_age_refs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_relative_age_refs (
    relative_age_ref_id integer NOT NULL,
    biblio_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    relative_age_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_relative_age_refs; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_relative_age_refs AS
 SELECT tbl_relative_age_refs.submission_id,
    tbl_relative_age_refs.source_id,
    tbl_relative_age_refs.local_db_id AS merged_db_id,
    tbl_relative_age_refs.local_db_id,
    tbl_relative_age_refs.public_db_id,
    tbl_relative_age_refs.relative_age_ref_id,
    tbl_relative_age_refs.biblio_id,
    tbl_relative_age_refs.date_updated,
    tbl_relative_age_refs.relative_age_id
   FROM tbl_relative_age_refs
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_relative_age_refs.relative_age_ref_id AS merged_db_id,
    0 AS local_db_id,
    tbl_relative_age_refs.relative_age_ref_id AS public_db_id,
    tbl_relative_age_refs.relative_age_ref_id,
    tbl_relative_age_refs.biblio_id,
    tbl_relative_age_refs.date_updated,
    tbl_relative_age_refs.relative_age_id
   FROM public.tbl_relative_age_refs;


SET search_path = public, pg_catalog;

--
-- Name: tbl_relative_ages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_relative_ages (
    relative_age_id integer NOT NULL,
    relative_age_type_id integer,
    relative_age_name character varying(50),
    description text,
    c14_age_older numeric(20,5),
    c14_age_younger numeric(20,5),
    cal_age_older numeric(20,5),
    cal_age_younger numeric(20,5),
    notes text,
    date_updated timestamp with time zone DEFAULT now(),
    location_id integer,
    abbreviation character varying
);


--
-- Name: TABLE tbl_relative_ages; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_relative_ages IS '20120504PIB: removed biblio_id as is replaced by tbl_relative_age_refs
20130722PIB: changed colour in model to AliceBlue to reflect degree of user addition possible (i.e. ages can be added for reference in tbl_relative_dates)';


--
-- Name: COLUMN tbl_relative_ages.relative_age_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_relative_ages.relative_age_name IS 'name of the dating period, e.g. bronze age. calendar ages should be given appropriate names such as ad 1492, 74 bc';


--
-- Name: COLUMN tbl_relative_ages.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_relative_ages.description IS 'a description of the (usually) period.';


--
-- Name: COLUMN tbl_relative_ages.c14_age_older; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_relative_ages.c14_age_older IS 'c14 age of younger boundary of period (where relevant).';


--
-- Name: COLUMN tbl_relative_ages.c14_age_younger; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_relative_ages.c14_age_younger IS 'c14 age of later boundary of period (where relevant). leave blank for calendar ages.';


--
-- Name: COLUMN tbl_relative_ages.cal_age_older; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_relative_ages.cal_age_older IS '(approximate) age before present (1950) of earliest boundary of period. or if calendar age then the calendar age converted to bp.';


--
-- Name: COLUMN tbl_relative_ages.cal_age_younger; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_relative_ages.cal_age_younger IS '(approximate) age before present (1950) of latest boundary of period. or if calendar age then the calendar age converted to bp.';


--
-- Name: COLUMN tbl_relative_ages.notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_relative_ages.notes IS 'any further notes not included in the description, such as reliability of definition or fuzzyness of boundaries.';


--
-- Name: COLUMN tbl_relative_ages.abbreviation; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_relative_ages.abbreviation IS 'Standard abbreviated form of name if available';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_relative_ages; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_relative_ages AS
 SELECT tbl_relative_ages.submission_id,
    tbl_relative_ages.source_id,
    tbl_relative_ages.local_db_id AS merged_db_id,
    tbl_relative_ages.local_db_id,
    tbl_relative_ages.public_db_id,
    tbl_relative_ages.relative_age_id,
    tbl_relative_ages.relative_age_type_id,
    tbl_relative_ages.relative_age_name,
    tbl_relative_ages.description,
    tbl_relative_ages.c14_age_older,
    tbl_relative_ages.c14_age_younger,
    tbl_relative_ages.cal_age_older,
    tbl_relative_ages.cal_age_younger,
    tbl_relative_ages.notes,
    tbl_relative_ages.date_updated,
    tbl_relative_ages.location_id
   FROM tbl_relative_ages
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_relative_ages.relative_age_id AS merged_db_id,
    0 AS local_db_id,
    tbl_relative_ages.relative_age_id AS public_db_id,
    tbl_relative_ages.relative_age_id,
    tbl_relative_ages.relative_age_type_id,
    tbl_relative_ages.relative_age_name,
    tbl_relative_ages.description,
    tbl_relative_ages.c14_age_older,
    tbl_relative_ages.c14_age_younger,
    tbl_relative_ages.cal_age_older,
    tbl_relative_ages.cal_age_younger,
    tbl_relative_ages.notes,
    tbl_relative_ages.date_updated,
    tbl_relative_ages.location_id
   FROM public.tbl_relative_ages;


SET search_path = public, pg_catalog;

--
-- Name: tbl_relative_dates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_relative_dates (
    relative_date_id integer NOT NULL,
    relative_age_id integer,
    physical_sample_id integer NOT NULL,
    method_id integer,
    notes text,
    date_updated timestamp with time zone DEFAULT now(),
    dating_uncertainty_id integer
);


--
-- Name: TABLE tbl_relative_dates; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_relative_dates IS '20120504PIB: Added method_id to store dating method used to attribute sample to period or calendar date (e.g. strategraphic dating, typological)
20130722PIB: addded field dating_uncertainty_id to cater for "from", "to" and "ca." etc. especially from import of BugsCEP';


--
-- Name: COLUMN tbl_relative_dates.method_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_relative_dates.method_id IS 'dating method used to attribute sample to period or calendar date.';


--
-- Name: COLUMN tbl_relative_dates.notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_relative_dates.notes IS 'any notes specific to the dating of this sample to this calendar or period based age';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_relative_dates; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_relative_dates AS
 SELECT tbl_relative_dates.submission_id,
    tbl_relative_dates.source_id,
    tbl_relative_dates.local_db_id AS merged_db_id,
    tbl_relative_dates.local_db_id,
    tbl_relative_dates.public_db_id,
    tbl_relative_dates.relative_date_id,
    tbl_relative_dates.relative_age_id,
    tbl_relative_dates.physical_sample_id,
    tbl_relative_dates.method_id,
    tbl_relative_dates.notes,
    tbl_relative_dates.date_updated,
    tbl_relative_dates.dating_uncertainty_id
   FROM tbl_relative_dates
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_relative_dates.relative_date_id AS merged_db_id,
    0 AS local_db_id,
    tbl_relative_dates.relative_date_id AS public_db_id,
    tbl_relative_dates.relative_date_id,
    tbl_relative_dates.relative_age_id,
    tbl_relative_dates.physical_sample_id,
    tbl_relative_dates.method_id,
    tbl_relative_dates.notes,
    tbl_relative_dates.date_updated,
    tbl_relative_dates.dating_uncertainty_id
   FROM public.tbl_relative_dates;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_alt_refs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_alt_refs (
    sample_alt_ref_id integer NOT NULL,
    alt_ref character varying(40) NOT NULL,
    alt_ref_type_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    physical_sample_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_alt_refs; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_alt_refs AS
 SELECT tbl_sample_alt_refs.submission_id,
    tbl_sample_alt_refs.source_id,
    tbl_sample_alt_refs.local_db_id AS merged_db_id,
    tbl_sample_alt_refs.local_db_id,
    tbl_sample_alt_refs.public_db_id,
    tbl_sample_alt_refs.sample_alt_ref_id,
    tbl_sample_alt_refs.alt_ref,
    tbl_sample_alt_refs.alt_ref_type_id,
    tbl_sample_alt_refs.date_updated,
    tbl_sample_alt_refs.physical_sample_id
   FROM tbl_sample_alt_refs
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_alt_refs.sample_alt_ref_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_alt_refs.sample_alt_ref_id AS public_db_id,
    tbl_sample_alt_refs.sample_alt_ref_id,
    tbl_sample_alt_refs.alt_ref,
    tbl_sample_alt_refs.alt_ref_type_id,
    tbl_sample_alt_refs.date_updated,
    tbl_sample_alt_refs.physical_sample_id
   FROM public.tbl_sample_alt_refs;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_colours; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_colours (
    sample_colour_id integer NOT NULL,
    colour_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    physical_sample_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_colours; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_colours AS
 SELECT tbl_sample_colours.submission_id,
    tbl_sample_colours.source_id,
    tbl_sample_colours.local_db_id AS merged_db_id,
    tbl_sample_colours.local_db_id,
    tbl_sample_colours.public_db_id,
    tbl_sample_colours.sample_colour_id,
    tbl_sample_colours.colour_id,
    tbl_sample_colours.date_updated,
    tbl_sample_colours.physical_sample_id
   FROM tbl_sample_colours
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_colours.sample_colour_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_colours.sample_colour_id AS public_db_id,
    tbl_sample_colours.sample_colour_id,
    tbl_sample_colours.colour_id,
    tbl_sample_colours.date_updated,
    tbl_sample_colours.physical_sample_id
   FROM public.tbl_sample_colours;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_coordinates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_coordinates (
    sample_coordinate_id integer NOT NULL,
    physical_sample_id integer NOT NULL,
    coordinate_method_dimension_id integer NOT NULL,
    measurement numeric(20,10) NOT NULL,
    accuracy numeric(20,10),
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN tbl_sample_coordinates.accuracy; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_sample_coordinates.accuracy IS 'GPS type accuracy, e.g. 5m 10m 0.01m';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_coordinates; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_coordinates AS
 SELECT tbl_sample_coordinates.submission_id,
    tbl_sample_coordinates.source_id,
    tbl_sample_coordinates.local_db_id AS merged_db_id,
    tbl_sample_coordinates.local_db_id,
    tbl_sample_coordinates.public_db_id,
    tbl_sample_coordinates.sample_coordinate_id,
    tbl_sample_coordinates.physical_sample_id,
    tbl_sample_coordinates.coordinate_method_dimension_id,
    tbl_sample_coordinates.measurement,
    tbl_sample_coordinates.accuracy,
    tbl_sample_coordinates.date_updated
   FROM tbl_sample_coordinates
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_coordinates.sample_coordinate_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_coordinates.sample_coordinate_id AS public_db_id,
    tbl_sample_coordinates.sample_coordinate_id,
    tbl_sample_coordinates.physical_sample_id,
    tbl_sample_coordinates.coordinate_method_dimension_id,
    tbl_sample_coordinates.measurement,
    tbl_sample_coordinates.accuracy,
    tbl_sample_coordinates.date_updated
   FROM public.tbl_sample_coordinates;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_description_sample_group_contexts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_description_sample_group_contexts (
    sample_description_sample_group_context_id integer NOT NULL,
    sampling_context_id integer,
    sample_description_type_id integer,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_description_sample_group_contexts; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_description_sample_group_contexts AS
 SELECT tbl_sample_description_sample_group_contexts.submission_id,
    tbl_sample_description_sample_group_contexts.source_id,
    tbl_sample_description_sample_group_contexts.local_db_id AS merged_db_id,
    tbl_sample_description_sample_group_contexts.local_db_id,
    tbl_sample_description_sample_group_contexts.public_db_id,
    tbl_sample_description_sample_group_contexts.sample_description_sample_group_context_id,
    tbl_sample_description_sample_group_contexts.sampling_context_id,
    tbl_sample_description_sample_group_contexts.sample_description_type_id,
    tbl_sample_description_sample_group_contexts.date_updated
   FROM tbl_sample_description_sample_group_contexts
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_description_sample_group_contexts.sample_description_sample_group_context_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_description_sample_group_contexts.sample_description_sample_group_context_id AS public_db_id,
    tbl_sample_description_sample_group_contexts.sample_description_sample_group_context_id,
    tbl_sample_description_sample_group_contexts.sampling_context_id,
    tbl_sample_description_sample_group_contexts.sample_description_type_id,
    tbl_sample_description_sample_group_contexts.date_updated
   FROM public.tbl_sample_description_sample_group_contexts;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_description_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_description_types (
    sample_description_type_id integer NOT NULL,
    type_name character varying(255),
    type_description text,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_description_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_description_types AS
 SELECT tbl_sample_description_types.submission_id,
    tbl_sample_description_types.source_id,
    tbl_sample_description_types.local_db_id AS merged_db_id,
    tbl_sample_description_types.local_db_id,
    tbl_sample_description_types.public_db_id,
    tbl_sample_description_types.sample_description_type_id,
    tbl_sample_description_types.type_name,
    tbl_sample_description_types.type_description,
    tbl_sample_description_types.date_updated
   FROM tbl_sample_description_types
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_description_types.sample_description_type_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_description_types.sample_description_type_id AS public_db_id,
    tbl_sample_description_types.sample_description_type_id,
    tbl_sample_description_types.type_name,
    tbl_sample_description_types.type_description,
    tbl_sample_description_types.date_updated
   FROM public.tbl_sample_description_types;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_descriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_descriptions (
    sample_description_id integer NOT NULL,
    sample_description_type_id integer NOT NULL,
    physical_sample_id integer NOT NULL,
    description character varying,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_descriptions; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_descriptions AS
 SELECT tbl_sample_descriptions.submission_id,
    tbl_sample_descriptions.source_id,
    tbl_sample_descriptions.local_db_id AS merged_db_id,
    tbl_sample_descriptions.local_db_id,
    tbl_sample_descriptions.public_db_id,
    tbl_sample_descriptions.sample_description_id,
    tbl_sample_descriptions.sample_description_type_id,
    tbl_sample_descriptions.physical_sample_id,
    tbl_sample_descriptions.description,
    tbl_sample_descriptions.date_updated
   FROM tbl_sample_descriptions
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_descriptions.sample_description_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_descriptions.sample_description_id AS public_db_id,
    tbl_sample_descriptions.sample_description_id,
    tbl_sample_descriptions.sample_description_type_id,
    tbl_sample_descriptions.physical_sample_id,
    tbl_sample_descriptions.description,
    tbl_sample_descriptions.date_updated
   FROM public.tbl_sample_descriptions;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_dimensions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_dimensions (
    sample_dimension_id integer NOT NULL,
    physical_sample_id integer NOT NULL,
    dimension_id integer NOT NULL,
    method_id integer NOT NULL,
    dimension_value numeric(20,10) NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE tbl_sample_dimensions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_sample_dimensions IS '20120506pib: depth measurements for samples moved here from tbl_physical_samples';


--
-- Name: COLUMN tbl_sample_dimensions.dimension_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_sample_dimensions.dimension_id IS 'details of the dimension measured';


--
-- Name: COLUMN tbl_sample_dimensions.method_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_sample_dimensions.method_id IS 'method describing dimension measurement, with link to units used';


--
-- Name: COLUMN tbl_sample_dimensions.dimension_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_sample_dimensions.dimension_value IS 'numerical value of dimension, in the units indicated in the documentation and interface.';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_dimensions; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_dimensions AS
 SELECT tbl_sample_dimensions.submission_id,
    tbl_sample_dimensions.source_id,
    tbl_sample_dimensions.local_db_id AS merged_db_id,
    tbl_sample_dimensions.local_db_id,
    tbl_sample_dimensions.public_db_id,
    tbl_sample_dimensions.sample_dimension_id,
    tbl_sample_dimensions.physical_sample_id,
    tbl_sample_dimensions.dimension_id,
    tbl_sample_dimensions.method_id,
    tbl_sample_dimensions.dimension_value,
    tbl_sample_dimensions.date_updated
   FROM tbl_sample_dimensions
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_dimensions.sample_dimension_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_dimensions.sample_dimension_id AS public_db_id,
    tbl_sample_dimensions.sample_dimension_id,
    tbl_sample_dimensions.physical_sample_id,
    tbl_sample_dimensions.dimension_id,
    tbl_sample_dimensions.method_id,
    tbl_sample_dimensions.dimension_value,
    tbl_sample_dimensions.date_updated
   FROM public.tbl_sample_dimensions;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_group_coordinates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_group_coordinates (
    sample_group_position_id integer NOT NULL,
    coordinate_method_dimension_id integer NOT NULL,
    sample_group_position numeric(20,10),
    position_accuracy character varying(128),
    sample_group_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_group_coordinates; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_group_coordinates AS
 SELECT tbl_sample_group_coordinates.submission_id,
    tbl_sample_group_coordinates.source_id,
    tbl_sample_group_coordinates.local_db_id AS merged_db_id,
    tbl_sample_group_coordinates.local_db_id,
    tbl_sample_group_coordinates.public_db_id,
    tbl_sample_group_coordinates.sample_group_position_id,
    tbl_sample_group_coordinates.coordinate_method_dimension_id,
    tbl_sample_group_coordinates.sample_group_position,
    tbl_sample_group_coordinates.position_accuracy,
    tbl_sample_group_coordinates.sample_group_id,
    tbl_sample_group_coordinates.date_updated
   FROM tbl_sample_group_coordinates
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_group_coordinates.sample_group_position_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_group_coordinates.sample_group_position_id AS public_db_id,
    tbl_sample_group_coordinates.sample_group_position_id,
    tbl_sample_group_coordinates.coordinate_method_dimension_id,
    tbl_sample_group_coordinates.sample_group_position,
    tbl_sample_group_coordinates.position_accuracy,
    tbl_sample_group_coordinates.sample_group_id,
    tbl_sample_group_coordinates.date_updated
   FROM public.tbl_sample_group_coordinates;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_group_description_type_sampling_contexts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_group_description_type_sampling_contexts (
    sample_group_description_type_sampling_context_id integer NOT NULL,
    sampling_context_id integer NOT NULL,
    sample_group_description_type_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_group_description_type_sampling_contexts; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_group_description_type_sampling_contexts AS
 SELECT tbl_sample_group_description_type_sampling_contexts.submission_id,
    tbl_sample_group_description_type_sampling_contexts.source_id,
    tbl_sample_group_description_type_sampling_contexts.local_db_id AS merged_db_id,
    tbl_sample_group_description_type_sampling_contexts.local_db_id,
    tbl_sample_group_description_type_sampling_contexts.public_db_id,
    tbl_sample_group_description_type_sampling_contexts.sample_group_description_type_sampling_context_id,
    tbl_sample_group_description_type_sampling_contexts.sampling_context_id,
    tbl_sample_group_description_type_sampling_contexts.sample_group_description_type_id,
    tbl_sample_group_description_type_sampling_contexts.date_updated
   FROM tbl_sample_group_description_type_sampling_contexts
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_group_description_type_sampling_contexts.sample_group_description_type_sampling_context_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_group_description_type_sampling_contexts.sample_group_description_type_sampling_context_id AS public_db_id,
    tbl_sample_group_description_type_sampling_contexts.sample_group_description_type_sampling_context_id,
    tbl_sample_group_description_type_sampling_contexts.sampling_context_id,
    tbl_sample_group_description_type_sampling_contexts.sample_group_description_type_id,
    tbl_sample_group_description_type_sampling_contexts.date_updated
   FROM public.tbl_sample_group_description_type_sampling_contexts;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_group_description_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_group_description_types (
    sample_group_description_type_id integer NOT NULL,
    type_name character varying(255),
    type_description character varying,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_group_description_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_group_description_types AS
 SELECT tbl_sample_group_description_types.submission_id,
    tbl_sample_group_description_types.source_id,
    tbl_sample_group_description_types.local_db_id AS merged_db_id,
    tbl_sample_group_description_types.local_db_id,
    tbl_sample_group_description_types.public_db_id,
    tbl_sample_group_description_types.sample_group_description_type_id,
    tbl_sample_group_description_types.type_name,
    tbl_sample_group_description_types.type_description,
    tbl_sample_group_description_types.date_updated
   FROM tbl_sample_group_description_types
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_group_description_types.sample_group_description_type_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_group_description_types.sample_group_description_type_id AS public_db_id,
    tbl_sample_group_description_types.sample_group_description_type_id,
    tbl_sample_group_description_types.type_name,
    tbl_sample_group_description_types.type_description,
    tbl_sample_group_description_types.date_updated
   FROM public.tbl_sample_group_description_types;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_group_descriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_group_descriptions (
    sample_group_description_id integer NOT NULL,
    group_description character varying,
    sample_group_description_type_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    sample_group_id integer
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_group_descriptions; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_group_descriptions AS
 SELECT tbl_sample_group_descriptions.submission_id,
    tbl_sample_group_descriptions.source_id,
    tbl_sample_group_descriptions.local_db_id AS merged_db_id,
    tbl_sample_group_descriptions.local_db_id,
    tbl_sample_group_descriptions.public_db_id,
    tbl_sample_group_descriptions.sample_group_description_id,
    tbl_sample_group_descriptions.group_description,
    tbl_sample_group_descriptions.sample_group_description_type_id,
    tbl_sample_group_descriptions.date_updated,
    tbl_sample_group_descriptions.sample_group_id
   FROM tbl_sample_group_descriptions
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_group_descriptions.sample_group_description_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_group_descriptions.sample_group_description_id AS public_db_id,
    tbl_sample_group_descriptions.sample_group_description_id,
    tbl_sample_group_descriptions.group_description,
    tbl_sample_group_descriptions.sample_group_description_type_id,
    tbl_sample_group_descriptions.date_updated,
    tbl_sample_group_descriptions.sample_group_id
   FROM public.tbl_sample_group_descriptions;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_group_dimensions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_group_dimensions (
    sample_group_dimension_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    dimension_id integer NOT NULL,
    dimension_value numeric(20,5) NOT NULL,
    sample_group_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_group_dimensions; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_group_dimensions AS
 SELECT tbl_sample_group_dimensions.submission_id,
    tbl_sample_group_dimensions.source_id,
    tbl_sample_group_dimensions.local_db_id AS merged_db_id,
    tbl_sample_group_dimensions.local_db_id,
    tbl_sample_group_dimensions.public_db_id,
    tbl_sample_group_dimensions.sample_group_dimension_id,
    tbl_sample_group_dimensions.date_updated,
    tbl_sample_group_dimensions.dimension_id,
    tbl_sample_group_dimensions.dimension_value,
    tbl_sample_group_dimensions.sample_group_id
   FROM tbl_sample_group_dimensions
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_group_dimensions.sample_group_dimension_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_group_dimensions.sample_group_dimension_id AS public_db_id,
    tbl_sample_group_dimensions.sample_group_dimension_id,
    tbl_sample_group_dimensions.date_updated,
    tbl_sample_group_dimensions.dimension_id,
    tbl_sample_group_dimensions.dimension_value,
    tbl_sample_group_dimensions.sample_group_id
   FROM public.tbl_sample_group_dimensions;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_group_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_group_images (
    sample_group_image_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    description text,
    image_location text NOT NULL,
    image_name character varying(80),
    image_type_id integer NOT NULL,
    sample_group_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_group_images; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_group_images AS
 SELECT tbl_sample_group_images.submission_id,
    tbl_sample_group_images.source_id,
    tbl_sample_group_images.local_db_id AS merged_db_id,
    tbl_sample_group_images.local_db_id,
    tbl_sample_group_images.public_db_id,
    tbl_sample_group_images.sample_group_image_id,
    tbl_sample_group_images.date_updated,
    tbl_sample_group_images.description,
    tbl_sample_group_images.image_location,
    tbl_sample_group_images.image_name,
    tbl_sample_group_images.image_type_id,
    tbl_sample_group_images.sample_group_id
   FROM tbl_sample_group_images
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_group_images.sample_group_image_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_group_images.sample_group_image_id AS public_db_id,
    tbl_sample_group_images.sample_group_image_id,
    tbl_sample_group_images.date_updated,
    tbl_sample_group_images.description,
    tbl_sample_group_images.image_location,
    tbl_sample_group_images.image_name,
    tbl_sample_group_images.image_type_id,
    tbl_sample_group_images.sample_group_id
   FROM public.tbl_sample_group_images;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_group_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_group_notes (
    sample_group_note_id integer NOT NULL,
    sample_group_id integer NOT NULL,
    note character varying,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_group_notes; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_group_notes AS
 SELECT tbl_sample_group_notes.submission_id,
    tbl_sample_group_notes.source_id,
    tbl_sample_group_notes.local_db_id AS merged_db_id,
    tbl_sample_group_notes.local_db_id,
    tbl_sample_group_notes.public_db_id,
    tbl_sample_group_notes.sample_group_note_id,
    tbl_sample_group_notes.sample_group_id,
    tbl_sample_group_notes.note,
    tbl_sample_group_notes.date_updated
   FROM tbl_sample_group_notes
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_group_notes.sample_group_note_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_group_notes.sample_group_note_id AS public_db_id,
    tbl_sample_group_notes.sample_group_note_id,
    tbl_sample_group_notes.sample_group_id,
    tbl_sample_group_notes.note,
    tbl_sample_group_notes.date_updated
   FROM public.tbl_sample_group_notes;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_group_references; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_group_references (
    sample_group_reference_id integer NOT NULL,
    biblio_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    sample_group_id integer DEFAULT 0
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_group_references; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_group_references AS
 SELECT tbl_sample_group_references.submission_id,
    tbl_sample_group_references.source_id,
    tbl_sample_group_references.local_db_id AS merged_db_id,
    tbl_sample_group_references.local_db_id,
    tbl_sample_group_references.public_db_id,
    tbl_sample_group_references.sample_group_reference_id,
    tbl_sample_group_references.biblio_id,
    tbl_sample_group_references.date_updated,
    tbl_sample_group_references.sample_group_id
   FROM tbl_sample_group_references
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_group_references.sample_group_reference_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_group_references.sample_group_reference_id AS public_db_id,
    tbl_sample_group_references.sample_group_reference_id,
    tbl_sample_group_references.biblio_id,
    tbl_sample_group_references.date_updated,
    tbl_sample_group_references.sample_group_id
   FROM public.tbl_sample_group_references;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_group_sampling_contexts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_group_sampling_contexts (
    sampling_context_id integer NOT NULL,
    sampling_context character varying(40) NOT NULL,
    description text,
    sort_order smallint DEFAULT 0 NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE tbl_sample_group_sampling_contexts; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_sample_group_sampling_contexts IS 'Type=lookup';


--
-- Name: COLUMN tbl_sample_group_sampling_contexts.sampling_context; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_sample_group_sampling_contexts.sampling_context IS 'short but meaningful name defining sample group context, e.g. stratigraphic sequence, archaeological excavation';


--
-- Name: COLUMN tbl_sample_group_sampling_contexts.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_sample_group_sampling_contexts.description IS 'full explanation of the grouping term';


--
-- Name: COLUMN tbl_sample_group_sampling_contexts.sort_order; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_sample_group_sampling_contexts.sort_order IS 'allows lists to group similar or associated group context close to each other, e.g. modern investigations together, palaeo investigations together';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_group_sampling_contexts; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_group_sampling_contexts AS
 SELECT tbl_sample_group_sampling_contexts.submission_id,
    tbl_sample_group_sampling_contexts.source_id,
    tbl_sample_group_sampling_contexts.local_db_id AS merged_db_id,
    tbl_sample_group_sampling_contexts.local_db_id,
    tbl_sample_group_sampling_contexts.public_db_id,
    tbl_sample_group_sampling_contexts.sampling_context_id,
    tbl_sample_group_sampling_contexts.sampling_context,
    tbl_sample_group_sampling_contexts.description,
    tbl_sample_group_sampling_contexts.sort_order,
    tbl_sample_group_sampling_contexts.date_updated
   FROM tbl_sample_group_sampling_contexts
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_group_sampling_contexts.sampling_context_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_group_sampling_contexts.sampling_context_id AS public_db_id,
    tbl_sample_group_sampling_contexts.sampling_context_id,
    tbl_sample_group_sampling_contexts.sampling_context,
    tbl_sample_group_sampling_contexts.description,
    tbl_sample_group_sampling_contexts.sort_order,
    tbl_sample_group_sampling_contexts.date_updated
   FROM public.tbl_sample_group_sampling_contexts;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_groups (
    sample_group_id integer NOT NULL,
    site_id integer DEFAULT 0,
    sampling_context_id integer,
    method_id integer NOT NULL,
    sample_group_name character varying(100) DEFAULT NULL::character varying,
    sample_group_description text,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN tbl_sample_groups.method_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_sample_groups.method_id IS 'sampling method, e.g. russian auger core, pitfall traps. note different from context in that it is specific to method of sample retrieval and not type of investigation.';


--
-- Name: COLUMN tbl_sample_groups.sample_group_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_sample_groups.sample_group_name IS 'Name which identifies the collection of samples. For ceramics, use vessel number.';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_groups; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_groups AS
 SELECT tbl_sample_groups.submission_id,
    tbl_sample_groups.source_id,
    tbl_sample_groups.local_db_id AS merged_db_id,
    tbl_sample_groups.local_db_id,
    tbl_sample_groups.public_db_id,
    tbl_sample_groups.sample_group_id,
    tbl_sample_groups.site_id,
    tbl_sample_groups.sampling_context_id,
    tbl_sample_groups.method_id,
    tbl_sample_groups.sample_group_name,
    tbl_sample_groups.sample_group_description,
    tbl_sample_groups.date_updated
   FROM tbl_sample_groups
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_groups.sample_group_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_groups.sample_group_id AS public_db_id,
    tbl_sample_groups.sample_group_id,
    tbl_sample_groups.site_id,
    tbl_sample_groups.sampling_context_id,
    tbl_sample_groups.method_id,
    tbl_sample_groups.sample_group_name,
    tbl_sample_groups.sample_group_description,
    tbl_sample_groups.date_updated
   FROM public.tbl_sample_groups;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_horizons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_horizons (
    sample_horizon_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    horizon_id integer NOT NULL,
    physical_sample_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_horizons; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_horizons AS
 SELECT tbl_sample_horizons.submission_id,
    tbl_sample_horizons.source_id,
    tbl_sample_horizons.local_db_id AS merged_db_id,
    tbl_sample_horizons.local_db_id,
    tbl_sample_horizons.public_db_id,
    tbl_sample_horizons.sample_horizon_id,
    tbl_sample_horizons.date_updated,
    tbl_sample_horizons.horizon_id,
    tbl_sample_horizons.physical_sample_id
   FROM tbl_sample_horizons
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_horizons.sample_horizon_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_horizons.sample_horizon_id AS public_db_id,
    tbl_sample_horizons.sample_horizon_id,
    tbl_sample_horizons.date_updated,
    tbl_sample_horizons.horizon_id,
    tbl_sample_horizons.physical_sample_id
   FROM public.tbl_sample_horizons;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_images (
    sample_image_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    description text,
    image_location text NOT NULL,
    image_name character varying(80),
    image_type_id integer NOT NULL,
    physical_sample_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_images; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_images AS
 SELECT tbl_sample_images.submission_id,
    tbl_sample_images.source_id,
    tbl_sample_images.local_db_id AS merged_db_id,
    tbl_sample_images.local_db_id,
    tbl_sample_images.public_db_id,
    tbl_sample_images.sample_image_id,
    tbl_sample_images.date_updated,
    tbl_sample_images.description,
    tbl_sample_images.image_location,
    tbl_sample_images.image_name,
    tbl_sample_images.image_type_id,
    tbl_sample_images.physical_sample_id
   FROM tbl_sample_images
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_images.sample_image_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_images.sample_image_id AS public_db_id,
    tbl_sample_images.sample_image_id,
    tbl_sample_images.date_updated,
    tbl_sample_images.description,
    tbl_sample_images.image_location,
    tbl_sample_images.image_name,
    tbl_sample_images.image_type_id,
    tbl_sample_images.physical_sample_id
   FROM public.tbl_sample_images;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_location_type_sampling_contexts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_location_type_sampling_contexts (
    sample_location_type_sampling_context_id integer NOT NULL,
    sampling_context_id integer NOT NULL,
    sample_location_type_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_location_type_sampling_contexts; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_location_type_sampling_contexts AS
 SELECT tbl_sample_location_type_sampling_contexts.submission_id,
    tbl_sample_location_type_sampling_contexts.source_id,
    tbl_sample_location_type_sampling_contexts.local_db_id AS merged_db_id,
    tbl_sample_location_type_sampling_contexts.local_db_id,
    tbl_sample_location_type_sampling_contexts.public_db_id,
    tbl_sample_location_type_sampling_contexts.sample_location_type_sampling_context_id,
    tbl_sample_location_type_sampling_contexts.sampling_context_id,
    tbl_sample_location_type_sampling_contexts.sample_location_type_id,
    tbl_sample_location_type_sampling_contexts.date_updated
   FROM tbl_sample_location_type_sampling_contexts
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_location_type_sampling_contexts.sample_location_type_sampling_context_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_location_type_sampling_contexts.sample_location_type_sampling_context_id AS public_db_id,
    tbl_sample_location_type_sampling_contexts.sample_location_type_sampling_context_id,
    tbl_sample_location_type_sampling_contexts.sampling_context_id,
    tbl_sample_location_type_sampling_contexts.sample_location_type_id,
    tbl_sample_location_type_sampling_contexts.date_updated
   FROM public.tbl_sample_location_type_sampling_contexts;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_location_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_location_types (
    sample_location_type_id integer NOT NULL,
    location_type character varying(255),
    location_type_description text,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_location_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_location_types AS
 SELECT tbl_sample_location_types.submission_id,
    tbl_sample_location_types.source_id,
    tbl_sample_location_types.local_db_id AS merged_db_id,
    tbl_sample_location_types.local_db_id,
    tbl_sample_location_types.public_db_id,
    tbl_sample_location_types.sample_location_type_id,
    tbl_sample_location_types.location_type,
    tbl_sample_location_types.location_type_description,
    tbl_sample_location_types.date_updated
   FROM tbl_sample_location_types
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_location_types.sample_location_type_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_location_types.sample_location_type_id AS public_db_id,
    tbl_sample_location_types.sample_location_type_id,
    tbl_sample_location_types.location_type,
    tbl_sample_location_types.location_type_description,
    tbl_sample_location_types.date_updated
   FROM public.tbl_sample_location_types;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_locations (
    sample_location_id integer NOT NULL,
    sample_location_type_id integer NOT NULL,
    physical_sample_id integer NOT NULL,
    location character varying(255),
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_locations; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_locations AS
 SELECT tbl_sample_locations.submission_id,
    tbl_sample_locations.source_id,
    tbl_sample_locations.local_db_id AS merged_db_id,
    tbl_sample_locations.local_db_id,
    tbl_sample_locations.public_db_id,
    tbl_sample_locations.sample_location_id,
    tbl_sample_locations.sample_location_type_id,
    tbl_sample_locations.physical_sample_id,
    tbl_sample_locations.location,
    tbl_sample_locations.date_updated
   FROM tbl_sample_locations
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_locations.sample_location_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_locations.sample_location_id AS public_db_id,
    tbl_sample_locations.sample_location_id,
    tbl_sample_locations.sample_location_type_id,
    tbl_sample_locations.physical_sample_id,
    tbl_sample_locations.location,
    tbl_sample_locations.date_updated
   FROM public.tbl_sample_locations;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_notes (
    sample_note_id integer NOT NULL,
    physical_sample_id integer NOT NULL,
    note_type character varying,
    note text NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN tbl_sample_notes.note_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_sample_notes.note_type IS 'origin of the note, e.g. field note, lab note';


--
-- Name: COLUMN tbl_sample_notes.note; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_sample_notes.note IS 'note contents';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_notes; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_notes AS
 SELECT tbl_sample_notes.submission_id,
    tbl_sample_notes.source_id,
    tbl_sample_notes.local_db_id AS merged_db_id,
    tbl_sample_notes.local_db_id,
    tbl_sample_notes.public_db_id,
    tbl_sample_notes.sample_note_id,
    tbl_sample_notes.physical_sample_id,
    tbl_sample_notes.note_type,
    tbl_sample_notes.note,
    tbl_sample_notes.date_updated
   FROM tbl_sample_notes
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_notes.sample_note_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_notes.sample_note_id AS public_db_id,
    tbl_sample_notes.sample_note_id,
    tbl_sample_notes.physical_sample_id,
    tbl_sample_notes.note_type,
    tbl_sample_notes.note,
    tbl_sample_notes.date_updated
   FROM public.tbl_sample_notes;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sample_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sample_types (
    sample_type_id integer NOT NULL,
    type_name character varying(40) NOT NULL,
    description text,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sample_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sample_types AS
 SELECT tbl_sample_types.submission_id,
    tbl_sample_types.source_id,
    tbl_sample_types.local_db_id AS merged_db_id,
    tbl_sample_types.local_db_id,
    tbl_sample_types.public_db_id,
    tbl_sample_types.sample_type_id,
    tbl_sample_types.type_name,
    tbl_sample_types.description,
    tbl_sample_types.date_updated
   FROM tbl_sample_types
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sample_types.sample_type_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sample_types.sample_type_id AS public_db_id,
    tbl_sample_types.sample_type_id,
    tbl_sample_types.type_name,
    tbl_sample_types.description,
    tbl_sample_types.date_updated
   FROM public.tbl_sample_types;


SET search_path = public, pg_catalog;

--
-- Name: tbl_season_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_season_types (
    season_type_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    description text,
    season_type character varying(30)
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_season_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_season_types AS
 SELECT tbl_season_types.submission_id,
    tbl_season_types.source_id,
    tbl_season_types.local_db_id AS merged_db_id,
    tbl_season_types.local_db_id,
    tbl_season_types.public_db_id,
    tbl_season_types.season_type_id,
    tbl_season_types.date_updated,
    tbl_season_types.description,
    tbl_season_types.season_type
   FROM tbl_season_types
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_season_types.season_type_id AS merged_db_id,
    0 AS local_db_id,
    tbl_season_types.season_type_id AS public_db_id,
    tbl_season_types.season_type_id,
    tbl_season_types.date_updated,
    tbl_season_types.description,
    tbl_season_types.season_type
   FROM public.tbl_season_types;


SET search_path = public, pg_catalog;

--
-- Name: tbl_seasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_seasons (
    season_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    season_name character varying(20) DEFAULT NULL::character varying,
    season_type character varying(30) DEFAULT NULL::character varying,
    season_type_id integer,
    sort_order smallint DEFAULT 0
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_seasons; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_seasons AS
 SELECT tbl_seasons.submission_id,
    tbl_seasons.source_id,
    tbl_seasons.local_db_id AS merged_db_id,
    tbl_seasons.local_db_id,
    tbl_seasons.public_db_id,
    tbl_seasons.season_id,
    tbl_seasons.date_updated,
    tbl_seasons.season_name,
    tbl_seasons.season_type,
    tbl_seasons.season_type_id,
    tbl_seasons.sort_order
   FROM tbl_seasons
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_seasons.season_id AS merged_db_id,
    0 AS local_db_id,
    tbl_seasons.season_id AS public_db_id,
    tbl_seasons.season_id,
    tbl_seasons.date_updated,
    tbl_seasons.season_name,
    tbl_seasons.season_type,
    tbl_seasons.season_type_id,
    tbl_seasons.sort_order
   FROM public.tbl_seasons;


SET search_path = public, pg_catalog;

--
-- Name: tbl_site_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_site_images (
    site_image_id integer NOT NULL,
    contact_id integer,
    credit character varying(100),
    date_taken date,
    date_updated timestamp with time zone DEFAULT now(),
    description text,
    image_location text NOT NULL,
    image_name character varying(80),
    image_type_id integer NOT NULL,
    site_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_site_images; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_site_images AS
 SELECT tbl_site_images.submission_id,
    tbl_site_images.source_id,
    tbl_site_images.local_db_id AS merged_db_id,
    tbl_site_images.local_db_id,
    tbl_site_images.public_db_id,
    tbl_site_images.site_image_id,
    tbl_site_images.contact_id,
    tbl_site_images.credit,
    tbl_site_images.date_taken,
    tbl_site_images.date_updated,
    tbl_site_images.description,
    tbl_site_images.image_location,
    tbl_site_images.image_name,
    tbl_site_images.image_type_id,
    tbl_site_images.site_id
   FROM tbl_site_images
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_site_images.site_image_id AS merged_db_id,
    0 AS local_db_id,
    tbl_site_images.site_image_id AS public_db_id,
    tbl_site_images.site_image_id,
    tbl_site_images.contact_id,
    tbl_site_images.credit,
    tbl_site_images.date_taken,
    tbl_site_images.date_updated,
    tbl_site_images.description,
    tbl_site_images.image_location,
    tbl_site_images.image_name,
    tbl_site_images.image_type_id,
    tbl_site_images.site_id
   FROM public.tbl_site_images;


SET search_path = public, pg_catalog;

--
-- Name: tbl_site_locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_site_locations (
    site_location_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    location_id integer NOT NULL,
    site_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_site_locations; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_site_locations AS
 SELECT tbl_site_locations.submission_id,
    tbl_site_locations.source_id,
    tbl_site_locations.local_db_id AS merged_db_id,
    tbl_site_locations.local_db_id,
    tbl_site_locations.public_db_id,
    tbl_site_locations.site_location_id,
    tbl_site_locations.date_updated,
    tbl_site_locations.location_id,
    tbl_site_locations.site_id
   FROM tbl_site_locations
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_site_locations.site_location_id AS merged_db_id,
    0 AS local_db_id,
    tbl_site_locations.site_location_id AS public_db_id,
    tbl_site_locations.site_location_id,
    tbl_site_locations.date_updated,
    tbl_site_locations.location_id,
    tbl_site_locations.site_id
   FROM public.tbl_site_locations;


SET search_path = public, pg_catalog;

--
-- Name: tbl_site_natgridrefs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_site_natgridrefs (
    site_natgridref_id integer NOT NULL,
    site_id integer NOT NULL,
    method_id integer NOT NULL,
    natgridref character varying NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE tbl_site_natgridrefs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_site_natgridrefs IS '20120507pib: removed tbl_national_grids and trasfered storage of coordinate systems to tbl_methods';


--
-- Name: COLUMN tbl_site_natgridrefs.method_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_site_natgridrefs.method_id IS 'points to coordinate system.';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_site_natgridrefs; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_site_natgridrefs AS
 SELECT tbl_site_natgridrefs.submission_id,
    tbl_site_natgridrefs.source_id,
    tbl_site_natgridrefs.local_db_id AS merged_db_id,
    tbl_site_natgridrefs.local_db_id,
    tbl_site_natgridrefs.public_db_id,
    tbl_site_natgridrefs.site_natgridref_id,
    tbl_site_natgridrefs.site_id,
    tbl_site_natgridrefs.method_id,
    tbl_site_natgridrefs.natgridref,
    tbl_site_natgridrefs.date_updated
   FROM tbl_site_natgridrefs
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_site_natgridrefs.site_natgridref_id AS merged_db_id,
    0 AS local_db_id,
    tbl_site_natgridrefs.site_natgridref_id AS public_db_id,
    tbl_site_natgridrefs.site_natgridref_id,
    tbl_site_natgridrefs.site_id,
    tbl_site_natgridrefs.method_id,
    tbl_site_natgridrefs.natgridref,
    tbl_site_natgridrefs.date_updated
   FROM public.tbl_site_natgridrefs;


SET search_path = public, pg_catalog;

--
-- Name: tbl_site_other_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_site_other_records (
    site_other_records_id integer NOT NULL,
    site_id integer,
    biblio_id integer,
    record_type_id integer,
    description text,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN tbl_site_other_records.biblio_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_site_other_records.biblio_id IS 'reference to publication containing data';


--
-- Name: COLUMN tbl_site_other_records.record_type_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_site_other_records.record_type_id IS 'reference to type of data (proxy)';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_site_other_records; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_site_other_records AS
 SELECT tbl_site_other_records.submission_id,
    tbl_site_other_records.source_id,
    tbl_site_other_records.local_db_id AS merged_db_id,
    tbl_site_other_records.local_db_id,
    tbl_site_other_records.public_db_id,
    tbl_site_other_records.site_other_records_id,
    tbl_site_other_records.site_id,
    tbl_site_other_records.biblio_id,
    tbl_site_other_records.record_type_id,
    tbl_site_other_records.description,
    tbl_site_other_records.date_updated
   FROM tbl_site_other_records
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_site_other_records.site_other_records_id AS merged_db_id,
    0 AS local_db_id,
    tbl_site_other_records.site_other_records_id AS public_db_id,
    tbl_site_other_records.site_other_records_id,
    tbl_site_other_records.site_id,
    tbl_site_other_records.biblio_id,
    tbl_site_other_records.record_type_id,
    tbl_site_other_records.description,
    tbl_site_other_records.date_updated
   FROM public.tbl_site_other_records;


SET search_path = public, pg_catalog;

--
-- Name: tbl_site_preservation_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_site_preservation_status (
    site_preservation_status_id integer NOT NULL,
    site_id integer,
    preservation_status_or_threat character varying,
    description text,
    assessment_type character varying,
    assessment_author_contact_id integer,
    date_updated timestamp with time zone DEFAULT now(),
    "Evaluation_date" date
);


--
-- Name: COLUMN tbl_site_preservation_status.site_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_site_preservation_status.site_id IS 'allows multiple preservation/threat records per site';


--
-- Name: COLUMN tbl_site_preservation_status.preservation_status_or_threat; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_site_preservation_status.preservation_status_or_threat IS 'descriptive name for:
preservation status, e.g. (e.g. lost, damaged, threatened) or
main reason for potential or real risk to site (e.g. hydroelectric, oil exploitation, mining, forestry, climate change, erosion)';


--
-- Name: COLUMN tbl_site_preservation_status.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_site_preservation_status.description IS 'brief description of site preservation status or threat to site preservation. include data here that does not fit in the other fields (for now - we may expand these features later if demand exists)';


--
-- Name: COLUMN tbl_site_preservation_status.assessment_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_site_preservation_status.assessment_type IS 'type of assessment giving information on preservation status and threat, e.g. unesco report, archaeological survey';


--
-- Name: COLUMN tbl_site_preservation_status.assessment_author_contact_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_site_preservation_status.assessment_author_contact_id IS 'person or authority in tbl_contacts responsible for the assessment of preservation status and threat';


--
-- Name: COLUMN tbl_site_preservation_status."Evaluation_date"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_site_preservation_status."Evaluation_date" IS 'Date of assessment, either formal or informal';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_site_preservation_status; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_site_preservation_status AS
 SELECT tbl_site_preservation_status.submission_id,
    tbl_site_preservation_status.source_id,
    tbl_site_preservation_status.local_db_id AS merged_db_id,
    tbl_site_preservation_status.local_db_id,
    tbl_site_preservation_status.public_db_id,
    tbl_site_preservation_status.site_preservation_status_id,
    tbl_site_preservation_status.site_id,
    tbl_site_preservation_status.preservation_status_or_threat,
    tbl_site_preservation_status.description,
    tbl_site_preservation_status.assessment_type,
    tbl_site_preservation_status.assessment_author_contact_id,
    tbl_site_preservation_status.date_updated
   FROM tbl_site_preservation_status
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_site_preservation_status.site_preservation_status_id AS merged_db_id,
    0 AS local_db_id,
    tbl_site_preservation_status.site_preservation_status_id AS public_db_id,
    tbl_site_preservation_status.site_preservation_status_id,
    tbl_site_preservation_status.site_id,
    tbl_site_preservation_status.preservation_status_or_threat,
    tbl_site_preservation_status.description,
    tbl_site_preservation_status.assessment_type,
    tbl_site_preservation_status.assessment_author_contact_id,
    tbl_site_preservation_status.date_updated
   FROM public.tbl_site_preservation_status;


SET search_path = public, pg_catalog;

--
-- Name: tbl_site_references; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_site_references (
    site_reference_id integer NOT NULL,
    site_id integer DEFAULT 0,
    biblio_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_site_references; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_site_references AS
 SELECT tbl_site_references.submission_id,
    tbl_site_references.source_id,
    tbl_site_references.local_db_id AS merged_db_id,
    tbl_site_references.local_db_id,
    tbl_site_references.public_db_id,
    tbl_site_references.site_reference_id,
    tbl_site_references.site_id,
    tbl_site_references.biblio_id,
    tbl_site_references.date_updated
   FROM tbl_site_references
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_site_references.site_reference_id AS merged_db_id,
    0 AS local_db_id,
    tbl_site_references.site_reference_id AS public_db_id,
    tbl_site_references.site_reference_id,
    tbl_site_references.site_id,
    tbl_site_references.biblio_id,
    tbl_site_references.date_updated
   FROM public.tbl_site_references;


SET search_path = public, pg_catalog;

--
-- Name: tbl_sites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_sites (
    site_id integer NOT NULL,
    altitude numeric(18,10),
    latitude_dd numeric(18,10),
    longitude_dd numeric(18,10),
    national_site_identifier character varying(255),
    site_description text DEFAULT NULL::character varying,
    site_name character varying(50) DEFAULT NULL::character varying,
    site_preservation_status_id integer,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_sites; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_sites AS
 SELECT tbl_sites.submission_id,
    tbl_sites.source_id,
    tbl_sites.local_db_id AS merged_db_id,
    tbl_sites.local_db_id,
    tbl_sites.public_db_id,
    tbl_sites.site_id,
    tbl_sites.altitude,
    tbl_sites.latitude_dd,
    tbl_sites.longitude_dd,
    tbl_sites.national_site_identifier,
    tbl_sites.site_description,
    tbl_sites.site_name,
    tbl_sites.site_preservation_status_id,
    tbl_sites.date_updated
   FROM tbl_sites
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_sites.site_id AS merged_db_id,
    0 AS local_db_id,
    tbl_sites.site_id AS public_db_id,
    tbl_sites.site_id,
    tbl_sites.altitude,
    tbl_sites.latitude_dd,
    tbl_sites.longitude_dd,
    tbl_sites.national_site_identifier,
    tbl_sites.site_description,
    tbl_sites.site_name,
    tbl_sites.site_preservation_status_id,
    tbl_sites.date_updated
   FROM public.tbl_sites;


SET search_path = public, pg_catalog;

--
-- Name: tbl_species_association_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_species_association_types (
    association_type_id integer NOT NULL,
    association_type_name character varying(255),
    association_description text,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_species_association_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_species_association_types AS
 SELECT tbl_species_association_types.submission_id,
    tbl_species_association_types.source_id,
    tbl_species_association_types.local_db_id AS merged_db_id,
    tbl_species_association_types.local_db_id,
    tbl_species_association_types.public_db_id,
    tbl_species_association_types.association_type_id,
    tbl_species_association_types.association_type_name,
    tbl_species_association_types.association_description,
    tbl_species_association_types.date_updated
   FROM tbl_species_association_types
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_species_association_types.association_type_id AS merged_db_id,
    0 AS local_db_id,
    tbl_species_association_types.association_type_id AS public_db_id,
    tbl_species_association_types.association_type_id,
    tbl_species_association_types.association_type_name,
    tbl_species_association_types.association_description,
    tbl_species_association_types.date_updated
   FROM public.tbl_species_association_types;


SET search_path = public, pg_catalog;

--
-- Name: tbl_species_associations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_species_associations (
    species_association_id integer NOT NULL,
    associated_taxon_id integer NOT NULL,
    biblio_id integer,
    date_updated timestamp with time zone DEFAULT now(),
    taxon_id integer NOT NULL,
    association_type_id integer,
    referencing_type text
);


--
-- Name: COLUMN tbl_species_associations.associated_taxon_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_species_associations.associated_taxon_id IS 'Taxon with which the primary taxon (taxon_id) is associated. ';


--
-- Name: COLUMN tbl_species_associations.biblio_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_species_associations.biblio_id IS 'Reference where relationship between taxa is described or mentioned';


--
-- Name: COLUMN tbl_species_associations.taxon_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_species_associations.taxon_id IS 'Primary taxon in relationship, i.e. this taxon has x relationship with the associated taxon';


--
-- Name: COLUMN tbl_species_associations.association_type_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_species_associations.association_type_id IS 'Type of association between primary taxon (taxon_id) and associated taxon. Note that the direction of the association is important in most cases (e.g. x predates on y)';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_species_associations; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_species_associations AS
 SELECT tbl_species_associations.submission_id,
    tbl_species_associations.source_id,
    tbl_species_associations.local_db_id AS merged_db_id,
    tbl_species_associations.local_db_id,
    tbl_species_associations.public_db_id,
    tbl_species_associations.species_association_id,
    tbl_species_associations.associated_taxon_id,
    tbl_species_associations.biblio_id,
    tbl_species_associations.date_updated,
    tbl_species_associations.taxon_id,
    tbl_species_associations.association_type_id,
    tbl_species_associations.referencing_type
   FROM tbl_species_associations
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_species_associations.species_association_id AS merged_db_id,
    0 AS local_db_id,
    tbl_species_associations.species_association_id AS public_db_id,
    tbl_species_associations.species_association_id,
    tbl_species_associations.associated_taxon_id,
    tbl_species_associations.biblio_id,
    tbl_species_associations.date_updated,
    tbl_species_associations.taxon_id,
    tbl_species_associations.association_type_id,
    tbl_species_associations.referencing_type
   FROM public.tbl_species_associations;


SET search_path = public, pg_catalog;

--
-- Name: tbl_taxa_common_names; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_taxa_common_names (
    taxon_common_name_id integer NOT NULL,
    common_name character varying(255) DEFAULT NULL::character varying,
    date_updated timestamp with time zone DEFAULT now(),
    language_id integer DEFAULT 0,
    taxon_id integer DEFAULT 0
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_taxa_common_names; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_taxa_common_names AS
 SELECT tbl_taxa_common_names.submission_id,
    tbl_taxa_common_names.source_id,
    tbl_taxa_common_names.local_db_id AS merged_db_id,
    tbl_taxa_common_names.local_db_id,
    tbl_taxa_common_names.public_db_id,
    tbl_taxa_common_names.taxon_common_name_id,
    tbl_taxa_common_names.common_name,
    tbl_taxa_common_names.date_updated,
    tbl_taxa_common_names.language_id,
    tbl_taxa_common_names.taxon_id
   FROM tbl_taxa_common_names
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_taxa_common_names.taxon_common_name_id AS merged_db_id,
    0 AS local_db_id,
    tbl_taxa_common_names.taxon_common_name_id AS public_db_id,
    tbl_taxa_common_names.taxon_common_name_id,
    tbl_taxa_common_names.common_name,
    tbl_taxa_common_names.date_updated,
    tbl_taxa_common_names.language_id,
    tbl_taxa_common_names.taxon_id
   FROM public.tbl_taxa_common_names;


SET search_path = public, pg_catalog;

--
-- Name: tbl_taxa_measured_attributes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_taxa_measured_attributes (
    measured_attribute_id integer NOT NULL,
    attribute_measure character varying(20) DEFAULT NULL::character varying,
    attribute_type character varying(25) DEFAULT NULL::character varying,
    attribute_units character varying(10) DEFAULT NULL::character varying,
    data numeric(18,10) DEFAULT 0,
    date_updated timestamp with time zone DEFAULT now(),
    taxon_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_taxa_measured_attributes; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_taxa_measured_attributes AS
 SELECT tbl_taxa_measured_attributes.submission_id,
    tbl_taxa_measured_attributes.source_id,
    tbl_taxa_measured_attributes.local_db_id AS merged_db_id,
    tbl_taxa_measured_attributes.local_db_id,
    tbl_taxa_measured_attributes.public_db_id,
    tbl_taxa_measured_attributes.measured_attribute_id,
    tbl_taxa_measured_attributes.attribute_measure,
    tbl_taxa_measured_attributes.attribute_type,
    tbl_taxa_measured_attributes.attribute_units,
    tbl_taxa_measured_attributes.data,
    tbl_taxa_measured_attributes.date_updated,
    tbl_taxa_measured_attributes.taxon_id
   FROM tbl_taxa_measured_attributes
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_taxa_measured_attributes.measured_attribute_id AS merged_db_id,
    0 AS local_db_id,
    tbl_taxa_measured_attributes.measured_attribute_id AS public_db_id,
    tbl_taxa_measured_attributes.measured_attribute_id,
    tbl_taxa_measured_attributes.attribute_measure,
    tbl_taxa_measured_attributes.attribute_type,
    tbl_taxa_measured_attributes.attribute_units,
    tbl_taxa_measured_attributes.data,
    tbl_taxa_measured_attributes.date_updated,
    tbl_taxa_measured_attributes.taxon_id
   FROM public.tbl_taxa_measured_attributes;


SET search_path = public, pg_catalog;

--
-- Name: tbl_taxa_seasonality; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_taxa_seasonality (
    seasonality_id integer NOT NULL,
    activity_type_id integer NOT NULL,
    season_id integer DEFAULT 0,
    taxon_id integer NOT NULL,
    location_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN tbl_taxa_seasonality.location_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_taxa_seasonality.location_id IS 'geographical relevance of seasonality data';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_taxa_seasonality; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_taxa_seasonality AS
 SELECT tbl_taxa_seasonality.submission_id,
    tbl_taxa_seasonality.source_id,
    tbl_taxa_seasonality.local_db_id AS merged_db_id,
    tbl_taxa_seasonality.local_db_id,
    tbl_taxa_seasonality.public_db_id,
    tbl_taxa_seasonality.seasonality_id,
    tbl_taxa_seasonality.activity_type_id,
    tbl_taxa_seasonality.season_id,
    tbl_taxa_seasonality.taxon_id,
    tbl_taxa_seasonality.location_id,
    tbl_taxa_seasonality.date_updated
   FROM tbl_taxa_seasonality
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_taxa_seasonality.seasonality_id AS merged_db_id,
    0 AS local_db_id,
    tbl_taxa_seasonality.seasonality_id AS public_db_id,
    tbl_taxa_seasonality.seasonality_id,
    tbl_taxa_seasonality.activity_type_id,
    tbl_taxa_seasonality.season_id,
    tbl_taxa_seasonality.taxon_id,
    tbl_taxa_seasonality.location_id,
    tbl_taxa_seasonality.date_updated
   FROM public.tbl_taxa_seasonality;


SET search_path = public, pg_catalog;

--
-- Name: tbl_taxa_synonyms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_taxa_synonyms (
    synonym_id integer NOT NULL,
    biblio_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    family_id integer,
    genus_id integer,
    notes text DEFAULT NULL::character varying,
    taxon_id integer,
    author_id integer,
    synonym character varying(255),
    reference_type character varying
);


--
-- Name: COLUMN tbl_taxa_synonyms.notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_taxa_synonyms.notes IS 'Any information useful to the history or usage of the synonym.';


--
-- Name: COLUMN tbl_taxa_synonyms.synonym; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_taxa_synonyms.synonym IS 'Synonym at level defined by id level. I.e. if synonym is at genus level, then only the genus synonym is included here. Another synonym record is used for the species level synonym for the same taxon only if the name is different to that used in the master list.';


--
-- Name: COLUMN tbl_taxa_synonyms.reference_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_taxa_synonyms.reference_type IS 'Form of information relating to the synonym in the given bibliographic link, e.g. by use, definition, incorrect usage.';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_taxa_synonyms; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_taxa_synonyms AS
 SELECT tbl_taxa_synonyms.submission_id,
    tbl_taxa_synonyms.source_id,
    tbl_taxa_synonyms.local_db_id AS merged_db_id,
    tbl_taxa_synonyms.local_db_id,
    tbl_taxa_synonyms.public_db_id,
    tbl_taxa_synonyms.synonym_id,
    tbl_taxa_synonyms.biblio_id,
    tbl_taxa_synonyms.date_updated,
    tbl_taxa_synonyms.family_id,
    tbl_taxa_synonyms.genus_id,
    tbl_taxa_synonyms.notes,
    tbl_taxa_synonyms.taxon_id,
    tbl_taxa_synonyms.author_id,
    tbl_taxa_synonyms.synonym,
    tbl_taxa_synonyms.reference_type
   FROM tbl_taxa_synonyms
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_taxa_synonyms.synonym_id AS merged_db_id,
    0 AS local_db_id,
    tbl_taxa_synonyms.synonym_id AS public_db_id,
    tbl_taxa_synonyms.synonym_id,
    tbl_taxa_synonyms.biblio_id,
    tbl_taxa_synonyms.date_updated,
    tbl_taxa_synonyms.family_id,
    tbl_taxa_synonyms.genus_id,
    tbl_taxa_synonyms.notes,
    tbl_taxa_synonyms.taxon_id,
    tbl_taxa_synonyms.author_id,
    tbl_taxa_synonyms.synonym,
    tbl_taxa_synonyms.reference_type
   FROM public.tbl_taxa_synonyms;


SET search_path = public, pg_catalog;

--
-- Name: tbl_taxa_tree_families; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_taxa_tree_families (
    family_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    family_name character varying(100) DEFAULT NULL::character varying,
    order_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_taxa_tree_families; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_taxa_tree_families AS
 SELECT tbl_taxa_tree_families.submission_id,
    tbl_taxa_tree_families.source_id,
    tbl_taxa_tree_families.local_db_id AS merged_db_id,
    tbl_taxa_tree_families.local_db_id,
    tbl_taxa_tree_families.public_db_id,
    tbl_taxa_tree_families.family_id,
    tbl_taxa_tree_families.date_updated,
    tbl_taxa_tree_families.family_name,
    tbl_taxa_tree_families.order_id
   FROM tbl_taxa_tree_families
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_taxa_tree_families.family_id AS merged_db_id,
    0 AS local_db_id,
    tbl_taxa_tree_families.family_id AS public_db_id,
    tbl_taxa_tree_families.family_id,
    tbl_taxa_tree_families.date_updated,
    tbl_taxa_tree_families.family_name,
    tbl_taxa_tree_families.order_id
   FROM public.tbl_taxa_tree_families;


SET search_path = public, pg_catalog;

--
-- Name: tbl_taxa_tree_orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_taxa_tree_orders (
    order_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    order_name character varying(50) DEFAULT NULL::character varying,
    record_type_id integer,
    sort_order integer
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_taxa_tree_orders; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_taxa_tree_orders AS
 SELECT tbl_taxa_tree_orders.submission_id,
    tbl_taxa_tree_orders.source_id,
    tbl_taxa_tree_orders.local_db_id AS merged_db_id,
    tbl_taxa_tree_orders.local_db_id,
    tbl_taxa_tree_orders.public_db_id,
    tbl_taxa_tree_orders.order_id,
    tbl_taxa_tree_orders.date_updated,
    tbl_taxa_tree_orders.order_name,
    tbl_taxa_tree_orders.record_type_id,
    tbl_taxa_tree_orders.sort_order
   FROM tbl_taxa_tree_orders
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_taxa_tree_orders.order_id AS merged_db_id,
    0 AS local_db_id,
    tbl_taxa_tree_orders.order_id AS public_db_id,
    tbl_taxa_tree_orders.order_id,
    tbl_taxa_tree_orders.date_updated,
    tbl_taxa_tree_orders.order_name,
    tbl_taxa_tree_orders.record_type_id,
    tbl_taxa_tree_orders.sort_order
   FROM public.tbl_taxa_tree_orders;


SET search_path = public, pg_catalog;

--
-- Name: tbl_taxonomic_order; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_taxonomic_order (
    taxonomic_order_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    taxon_id integer DEFAULT 0,
    taxonomic_code numeric(18,10) DEFAULT 0,
    taxonomic_order_system_id integer DEFAULT 0
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_taxonomic_order; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_taxonomic_order AS
 SELECT tbl_taxonomic_order.submission_id,
    tbl_taxonomic_order.source_id,
    tbl_taxonomic_order.local_db_id AS merged_db_id,
    tbl_taxonomic_order.local_db_id,
    tbl_taxonomic_order.public_db_id,
    tbl_taxonomic_order.taxonomic_order_id,
    tbl_taxonomic_order.date_updated,
    tbl_taxonomic_order.taxon_id,
    tbl_taxonomic_order.taxonomic_code,
    tbl_taxonomic_order.taxonomic_order_system_id
   FROM tbl_taxonomic_order
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_taxonomic_order.taxonomic_order_id AS merged_db_id,
    0 AS local_db_id,
    tbl_taxonomic_order.taxonomic_order_id AS public_db_id,
    tbl_taxonomic_order.taxonomic_order_id,
    tbl_taxonomic_order.date_updated,
    tbl_taxonomic_order.taxon_id,
    tbl_taxonomic_order.taxonomic_code,
    tbl_taxonomic_order.taxonomic_order_system_id
   FROM public.tbl_taxonomic_order;


SET search_path = public, pg_catalog;

--
-- Name: tbl_taxonomic_order_biblio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_taxonomic_order_biblio (
    taxonomic_order_biblio_id integer NOT NULL,
    biblio_id integer DEFAULT 0,
    date_updated timestamp with time zone DEFAULT now(),
    taxonomic_order_system_id integer DEFAULT 0
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_taxonomic_order_biblio; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_taxonomic_order_biblio AS
 SELECT tbl_taxonomic_order_biblio.submission_id,
    tbl_taxonomic_order_biblio.source_id,
    tbl_taxonomic_order_biblio.local_db_id AS merged_db_id,
    tbl_taxonomic_order_biblio.local_db_id,
    tbl_taxonomic_order_biblio.public_db_id,
    tbl_taxonomic_order_biblio.taxonomic_order_biblio_id,
    tbl_taxonomic_order_biblio.biblio_id,
    tbl_taxonomic_order_biblio.date_updated,
    tbl_taxonomic_order_biblio.taxonomic_order_system_id
   FROM tbl_taxonomic_order_biblio
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_taxonomic_order_biblio.taxonomic_order_biblio_id AS merged_db_id,
    0 AS local_db_id,
    tbl_taxonomic_order_biblio.taxonomic_order_biblio_id AS public_db_id,
    tbl_taxonomic_order_biblio.taxonomic_order_biblio_id,
    tbl_taxonomic_order_biblio.biblio_id,
    tbl_taxonomic_order_biblio.date_updated,
    tbl_taxonomic_order_biblio.taxonomic_order_system_id
   FROM public.tbl_taxonomic_order_biblio;


SET search_path = public, pg_catalog;

--
-- Name: tbl_taxonomic_order_systems; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_taxonomic_order_systems (
    taxonomic_order_system_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    system_description text,
    system_name character varying(50) DEFAULT NULL::character varying
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_taxonomic_order_systems; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_taxonomic_order_systems AS
 SELECT tbl_taxonomic_order_systems.submission_id,
    tbl_taxonomic_order_systems.source_id,
    tbl_taxonomic_order_systems.local_db_id AS merged_db_id,
    tbl_taxonomic_order_systems.local_db_id,
    tbl_taxonomic_order_systems.public_db_id,
    tbl_taxonomic_order_systems.taxonomic_order_system_id,
    tbl_taxonomic_order_systems.date_updated,
    tbl_taxonomic_order_systems.system_description,
    tbl_taxonomic_order_systems.system_name
   FROM tbl_taxonomic_order_systems
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_taxonomic_order_systems.taxonomic_order_system_id AS merged_db_id,
    0 AS local_db_id,
    tbl_taxonomic_order_systems.taxonomic_order_system_id AS public_db_id,
    tbl_taxonomic_order_systems.taxonomic_order_system_id,
    tbl_taxonomic_order_systems.date_updated,
    tbl_taxonomic_order_systems.system_description,
    tbl_taxonomic_order_systems.system_name
   FROM public.tbl_taxonomic_order_systems;


SET search_path = public, pg_catalog;

--
-- Name: tbl_taxonomy_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_taxonomy_notes (
    taxonomy_notes_id integer NOT NULL,
    biblio_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    taxon_id integer NOT NULL,
    taxonomy_notes text
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_taxonomy_notes; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_taxonomy_notes AS
 SELECT tbl_taxonomy_notes.submission_id,
    tbl_taxonomy_notes.source_id,
    tbl_taxonomy_notes.local_db_id AS merged_db_id,
    tbl_taxonomy_notes.local_db_id,
    tbl_taxonomy_notes.public_db_id,
    tbl_taxonomy_notes.taxonomy_notes_id,
    tbl_taxonomy_notes.biblio_id,
    tbl_taxonomy_notes.date_updated,
    tbl_taxonomy_notes.taxon_id,
    tbl_taxonomy_notes.taxonomy_notes
   FROM tbl_taxonomy_notes
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_taxonomy_notes.taxonomy_notes_id AS merged_db_id,
    0 AS local_db_id,
    tbl_taxonomy_notes.taxonomy_notes_id AS public_db_id,
    tbl_taxonomy_notes.taxonomy_notes_id,
    tbl_taxonomy_notes.biblio_id,
    tbl_taxonomy_notes.date_updated,
    tbl_taxonomy_notes.taxon_id,
    tbl_taxonomy_notes.taxonomy_notes
   FROM public.tbl_taxonomy_notes;


SET search_path = public, pg_catalog;

--
-- Name: tbl_tephra_dates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_tephra_dates (
    tephra_date_id integer NOT NULL,
    analysis_entity_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    notes text,
    tephra_id integer NOT NULL,
    dating_uncertainty_id integer
);


--
-- Name: TABLE tbl_tephra_dates; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_tephra_dates IS '20130722PIB: Added field dating_uncertainty_id to cater for >< etc.';


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_tephra_dates; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_tephra_dates AS
 SELECT tbl_tephra_dates.submission_id,
    tbl_tephra_dates.source_id,
    tbl_tephra_dates.local_db_id AS merged_db_id,
    tbl_tephra_dates.local_db_id,
    tbl_tephra_dates.public_db_id,
    tbl_tephra_dates.tephra_date_id,
    tbl_tephra_dates.analysis_entity_id,
    tbl_tephra_dates.date_updated,
    tbl_tephra_dates.notes,
    tbl_tephra_dates.tephra_id,
    tbl_tephra_dates.dating_uncertainty_id
   FROM tbl_tephra_dates
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_tephra_dates.tephra_date_id AS merged_db_id,
    0 AS local_db_id,
    tbl_tephra_dates.tephra_date_id AS public_db_id,
    tbl_tephra_dates.tephra_date_id,
    tbl_tephra_dates.analysis_entity_id,
    tbl_tephra_dates.date_updated,
    tbl_tephra_dates.notes,
    tbl_tephra_dates.tephra_id,
    tbl_tephra_dates.dating_uncertainty_id
   FROM public.tbl_tephra_dates;


SET search_path = public, pg_catalog;

--
-- Name: tbl_tephra_refs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_tephra_refs (
    tephra_ref_id integer NOT NULL,
    biblio_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    tephra_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_tephra_refs; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_tephra_refs AS
 SELECT tbl_tephra_refs.submission_id,
    tbl_tephra_refs.source_id,
    tbl_tephra_refs.local_db_id AS merged_db_id,
    tbl_tephra_refs.local_db_id,
    tbl_tephra_refs.public_db_id,
    tbl_tephra_refs.tephra_ref_id,
    tbl_tephra_refs.biblio_id,
    tbl_tephra_refs.date_updated,
    tbl_tephra_refs.tephra_id
   FROM tbl_tephra_refs
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_tephra_refs.tephra_ref_id AS merged_db_id,
    0 AS local_db_id,
    tbl_tephra_refs.tephra_ref_id AS public_db_id,
    tbl_tephra_refs.tephra_ref_id,
    tbl_tephra_refs.biblio_id,
    tbl_tephra_refs.date_updated,
    tbl_tephra_refs.tephra_id
   FROM public.tbl_tephra_refs;


SET search_path = public, pg_catalog;

--
-- Name: tbl_tephras; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_tephras (
    tephra_id integer NOT NULL,
    c14_age numeric(20,5),
    c14_age_older numeric(20,5),
    c14_age_younger numeric(20,5),
    cal_age numeric(20,5),
    cal_age_older numeric(20,5),
    cal_age_younger numeric(20,5),
    date_updated timestamp with time zone DEFAULT now(),
    notes text,
    tephra_name character varying(80)
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_tephras; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_tephras AS
 SELECT tbl_tephras.submission_id,
    tbl_tephras.source_id,
    tbl_tephras.local_db_id AS merged_db_id,
    tbl_tephras.local_db_id,
    tbl_tephras.public_db_id,
    tbl_tephras.tephra_id,
    tbl_tephras.c14_age,
    tbl_tephras.c14_age_older,
    tbl_tephras.c14_age_younger,
    tbl_tephras.cal_age,
    tbl_tephras.cal_age_older,
    tbl_tephras.cal_age_younger,
    tbl_tephras.date_updated,
    tbl_tephras.notes,
    tbl_tephras.tephra_name
   FROM tbl_tephras
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_tephras.tephra_id AS merged_db_id,
    0 AS local_db_id,
    tbl_tephras.tephra_id AS public_db_id,
    tbl_tephras.tephra_id,
    tbl_tephras.c14_age,
    tbl_tephras.c14_age_older,
    tbl_tephras.c14_age_younger,
    tbl_tephras.cal_age,
    tbl_tephras.cal_age_older,
    tbl_tephras.cal_age_younger,
    tbl_tephras.date_updated,
    tbl_tephras.notes,
    tbl_tephras.tephra_name
   FROM public.tbl_tephras;


SET search_path = public, pg_catalog;

--
-- Name: tbl_text_biology; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_text_biology (
    biology_id integer NOT NULL,
    biblio_id integer NOT NULL,
    biology_text text,
    date_updated timestamp with time zone DEFAULT now(),
    taxon_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_text_biology; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_text_biology AS
 SELECT tbl_text_biology.submission_id,
    tbl_text_biology.source_id,
    tbl_text_biology.local_db_id AS merged_db_id,
    tbl_text_biology.local_db_id,
    tbl_text_biology.public_db_id,
    tbl_text_biology.biology_id,
    tbl_text_biology.biblio_id,
    tbl_text_biology.biology_text,
    tbl_text_biology.date_updated,
    tbl_text_biology.taxon_id
   FROM tbl_text_biology
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_text_biology.biology_id AS merged_db_id,
    0 AS local_db_id,
    tbl_text_biology.biology_id AS public_db_id,
    tbl_text_biology.biology_id,
    tbl_text_biology.biblio_id,
    tbl_text_biology.biology_text,
    tbl_text_biology.date_updated,
    tbl_text_biology.taxon_id
   FROM public.tbl_text_biology;


SET search_path = public, pg_catalog;

--
-- Name: tbl_text_distribution; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_text_distribution (
    distribution_id integer NOT NULL,
    biblio_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    distribution_text text,
    taxon_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_text_distribution; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_text_distribution AS
 SELECT tbl_text_distribution.submission_id,
    tbl_text_distribution.source_id,
    tbl_text_distribution.local_db_id AS merged_db_id,
    tbl_text_distribution.local_db_id,
    tbl_text_distribution.public_db_id,
    tbl_text_distribution.distribution_id,
    tbl_text_distribution.biblio_id,
    tbl_text_distribution.date_updated,
    tbl_text_distribution.distribution_text,
    tbl_text_distribution.taxon_id
   FROM tbl_text_distribution
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_text_distribution.distribution_id AS merged_db_id,
    0 AS local_db_id,
    tbl_text_distribution.distribution_id AS public_db_id,
    tbl_text_distribution.distribution_id,
    tbl_text_distribution.biblio_id,
    tbl_text_distribution.date_updated,
    tbl_text_distribution.distribution_text,
    tbl_text_distribution.taxon_id
   FROM public.tbl_text_distribution;


SET search_path = public, pg_catalog;

--
-- Name: tbl_text_identification_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_text_identification_keys (
    key_id integer NOT NULL,
    biblio_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    key_text text,
    taxon_id integer NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_text_identification_keys; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_text_identification_keys AS
 SELECT tbl_text_identification_keys.submission_id,
    tbl_text_identification_keys.source_id,
    tbl_text_identification_keys.local_db_id AS merged_db_id,
    tbl_text_identification_keys.local_db_id,
    tbl_text_identification_keys.public_db_id,
    tbl_text_identification_keys.key_id,
    tbl_text_identification_keys.biblio_id,
    tbl_text_identification_keys.date_updated,
    tbl_text_identification_keys.key_text,
    tbl_text_identification_keys.taxon_id
   FROM tbl_text_identification_keys
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_text_identification_keys.key_id AS merged_db_id,
    0 AS local_db_id,
    tbl_text_identification_keys.key_id AS public_db_id,
    tbl_text_identification_keys.key_id,
    tbl_text_identification_keys.biblio_id,
    tbl_text_identification_keys.date_updated,
    tbl_text_identification_keys.key_text,
    tbl_text_identification_keys.taxon_id
   FROM public.tbl_text_identification_keys;


SET search_path = public, pg_catalog;

--
-- Name: tbl_units; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_units (
    unit_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now(),
    description text,
    unit_abbrev character varying(15),
    unit_name character varying(50) NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_units; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_units AS
 SELECT tbl_units.submission_id,
    tbl_units.source_id,
    tbl_units.local_db_id AS merged_db_id,
    tbl_units.local_db_id,
    tbl_units.public_db_id,
    tbl_units.unit_id,
    tbl_units.date_updated,
    tbl_units.description,
    tbl_units.unit_abbrev,
    tbl_units.unit_name
   FROM tbl_units
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_units.unit_id AS merged_db_id,
    0 AS local_db_id,
    tbl_units.unit_id AS public_db_id,
    tbl_units.unit_id,
    tbl_units.date_updated,
    tbl_units.description,
    tbl_units.unit_abbrev,
    tbl_units.unit_name
   FROM public.tbl_units;


SET search_path = public, pg_catalog;

--
-- Name: tbl_updates_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_updates_log (
    updates_log_id integer NOT NULL,
    table_name character varying(150) NOT NULL,
    last_updated date NOT NULL
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_updates_log; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_updates_log AS
 SELECT tbl_updates_log.submission_id,
    tbl_updates_log.source_id,
    tbl_updates_log.local_db_id AS merged_db_id,
    tbl_updates_log.local_db_id,
    tbl_updates_log.public_db_id,
    tbl_updates_log.updates_log_id,
    tbl_updates_log.table_name,
    tbl_updates_log.last_updated
   FROM tbl_updates_log
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_updates_log.updates_log_id AS merged_db_id,
    0 AS local_db_id,
    tbl_updates_log.updates_log_id AS public_db_id,
    tbl_updates_log.updates_log_id,
    tbl_updates_log.table_name,
    tbl_updates_log.last_updated
   FROM public.tbl_updates_log;


SET search_path = public, pg_catalog;

--
-- Name: tbl_years_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_years_types (
    years_type_id integer NOT NULL,
    name character varying NOT NULL,
    description text,
    date_updated timestamp with time zone DEFAULT now()
);


SET search_path = clearing_house, pg_catalog;

--
-- Name: view_years_types; Type: VIEW; Schema: clearing_house; Owner: -
--

CREATE VIEW view_years_types AS
 SELECT tbl_years_types.submission_id,
    tbl_years_types.source_id,
    tbl_years_types.local_db_id AS merged_db_id,
    tbl_years_types.local_db_id,
    tbl_years_types.public_db_id,
    tbl_years_types.years_type_id,
    tbl_years_types.name,
    tbl_years_types.description,
    tbl_years_types.date_updated
   FROM tbl_years_types
UNION
 SELECT 0 AS submission_id,
    2 AS source_id,
    tbl_years_types.years_type_id AS merged_db_id,
    0 AS local_db_id,
    tbl_years_types.years_type_id AS public_db_id,
    tbl_years_types.years_type_id,
    tbl_years_types.name,
    tbl_years_types.description,
    tbl_years_types.date_updated
   FROM public.tbl_years_types;


SET search_path = metainformation, pg_catalog;

--
-- Name: file_name_data_download_seq; Type: SEQUENCE; Schema: metainformation; Owner: -
--

CREATE SEQUENCE file_name_data_download_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: language_definitions; Type: TABLE; Schema: metainformation; Owner: -
--

CREATE TABLE language_definitions (
    id integer NOT NULL,
    language character varying(8),
    language_name character varying(32),
    active boolean DEFAULT true
);


--
-- Name: language_definitions_id_seq; Type: SEQUENCE; Schema: metainformation; Owner: -
--

CREATE SEQUENCE language_definitions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: language_definitions_id_seq; Type: SEQUENCE OWNED BY; Schema: metainformation; Owner: -
--

ALTER SEQUENCE language_definitions_id_seq OWNED BY language_definitions.id;


--
-- Name: measured_values_by_physical_sample; Type: VIEW; Schema: metainformation; Owner: -
--

CREATE VIEW measured_values_by_physical_sample AS
 SELECT tbl_physical_samples.physical_sample_id,
    max(values_8_0.measured_value) AS max_value_8_0,
    min(values_8_0.measured_value) AS min_value_8_0,
    avg(values_8_0.measured_value) AS value_8_0,
    count(values_8_0.*) AS count_8_0,
    max(values_32_124.measured_value) AS max_value_32_124,
    min(values_32_124.measured_value) AS min_value_32_124,
    avg(values_32_124.measured_value) AS value_32_124,
    count(values_32_124.*) AS count_32_124,
    max(values_32_0.measured_value) AS max_value_32_0,
    min(values_32_0.measured_value) AS min_value_32_0,
    avg(values_32_0.measured_value) AS value_32_0,
    count(values_32_0.*) AS count_32_0,
    max(values_32_112.measured_value) AS max_value_32_112,
    min(values_32_112.measured_value) AS min_value_32_112,
    avg(values_32_112.measured_value) AS value_32_112,
    count(values_32_112.*) AS count_32_112,
    max(values_32_82.measured_value) AS max_value_32_82,
    min(values_32_82.measured_value) AS min_value_32_82,
    avg(values_32_82.measured_value) AS value_32_82,
    count(values_32_82.*) AS count_32_82,
    max(values_33_112.measured_value) AS max_value_33_112,
    min(values_33_112.measured_value) AS min_value_33_112,
    avg(values_33_112.measured_value) AS value_33_112,
    count(values_33_112.*) AS count_33_112,
    max(values_33_82.measured_value) AS max_value_33_82,
    min(values_33_82.measured_value) AS min_value_33_82,
    avg(values_33_82.measured_value) AS value_33_82,
    count(values_33_82.*) AS count_33_82,
    max(values_33_0.measured_value) AS max_value_33_0,
    min(values_33_0.measured_value) AS min_value_33_0,
    avg(values_33_0.measured_value) AS value_33_0,
    count(values_33_0.*) AS count_33_0,
    max(values_33_87.measured_value) AS max_value_33_87,
    min(values_33_87.measured_value) AS min_value_33_87,
    avg(values_33_87.measured_value) AS value_33_87,
    count(values_33_87.*) AS count_33_87,
    max(values_35_124.measured_value) AS max_value_35_124,
    min(values_35_124.measured_value) AS min_value_35_124,
    avg(values_35_124.measured_value) AS value_35_124,
    count(values_35_124.*) AS count_35_124,
    max(values_35_0.measured_value) AS max_value_35_0,
    min(values_35_0.measured_value) AS min_value_35_0,
    avg(values_35_0.measured_value) AS value_35_0,
    count(values_35_0.*) AS count_35_0,
    max(values_35_82.measured_value) AS max_value_35_82,
    min(values_35_82.measured_value) AS min_value_35_82,
    avg(values_35_82.measured_value) AS value_35_82,
    count(values_35_82.*) AS count_35_82,
    max(values_36_0.measured_value) AS max_value_36_0,
    min(values_36_0.measured_value) AS min_value_36_0,
    avg(values_36_0.measured_value) AS value_36_0,
    count(values_36_0.*) AS count_36_0,
    max(values_36_82.measured_value) AS max_value_36_82,
    min(values_36_82.measured_value) AS min_value_36_82,
    avg(values_36_82.measured_value) AS value_36_82,
    count(values_36_82.*) AS count_36_82,
    max(values_37_112.measured_value) AS max_value_37_112,
    min(values_37_112.measured_value) AS min_value_37_112,
    avg(values_37_112.measured_value) AS value_37_112,
    count(values_37_112.*) AS count_37_112,
    max(values_37_124.measured_value) AS max_value_37_124,
    min(values_37_124.measured_value) AS min_value_37_124,
    avg(values_37_124.measured_value) AS value_37_124,
    count(values_37_124.*) AS count_37_124,
    max(values_37_0.measured_value) AS max_value_37_0,
    min(values_37_0.measured_value) AS min_value_37_0,
    avg(values_37_0.measured_value) AS value_37_0,
    count(values_37_0.*) AS count_37_0,
    max(values_74_124.measured_value) AS max_value_74_124,
    min(values_74_124.measured_value) AS min_value_74_124,
    avg(values_74_124.measured_value) AS value_74_124,
    count(values_74_124.*) AS count_74_124,
    max(values_74_82.measured_value) AS max_value_74_82,
    min(values_74_82.measured_value) AS min_value_74_82,
    avg(values_74_82.measured_value) AS value_74_82,
    count(values_74_82.*) AS count_74_82,
    max(values_74_112.measured_value) AS max_value_74_112,
    min(values_74_112.measured_value) AS min_value_74_112,
    avg(values_74_112.measured_value) AS value_74_112,
    count(values_74_112.*) AS count_74_112,
    max(values_74_0.measured_value) AS max_value_74_0,
    min(values_74_0.measured_value) AS min_value_74_0,
    avg(values_74_0.measured_value) AS value_74_0,
    count(values_74_0.*) AS count_74_0,
    max(values_94_0.measured_value) AS max_value_94_0,
    min(values_94_0.measured_value) AS min_value_94_0,
    avg(values_94_0.measured_value) AS value_94_0,
    count(values_94_0.*) AS count_94_0,
    max(values_94_82.measured_value) AS max_value_94_82,
    min(values_94_82.measured_value) AS min_value_94_82,
    avg(values_94_82.measured_value) AS value_94_82,
    count(values_94_82.*) AS count_94_82,
    max(values_106_0.measured_value) AS max_value_106_0,
    min(values_106_0.measured_value) AS min_value_106_0,
    avg(values_106_0.measured_value) AS value_106_0,
    count(values_106_0.*) AS count_106_0,
    max(values_107_0.measured_value) AS max_value_107_0,
    min(values_107_0.measured_value) AS min_value_107_0,
    avg(values_107_0.measured_value) AS value_107_0,
    count(values_107_0.*) AS count_107_0,
    max(values_109_0.measured_value) AS max_value_109_0,
    min(values_109_0.measured_value) AS min_value_109_0,
    avg(values_109_0.measured_value) AS value_109_0,
    count(values_109_0.*) AS count_109_0,
    max(values_110_0.measured_value) AS max_value_110_0,
    min(values_110_0.measured_value) AS min_value_110_0,
    avg(values_110_0.measured_value) AS value_110_0,
    count(values_110_0.*) AS count_110_0,
    max(values_111_0.measured_value) AS max_value_111_0,
    min(values_111_0.measured_value) AS min_value_111_0,
    avg(values_111_0.measured_value) AS value_111_0,
    count(values_111_0.*) AS count_111_0,
    max(values_117_0.measured_value) AS max_value_117_0,
    min(values_117_0.measured_value) AS min_value_117_0,
    avg(values_117_0.measured_value) AS value_117_0,
    count(values_117_0.*) AS count_117_0,
    max(values_118_0.measured_value) AS max_value_118_0,
    min(values_118_0.measured_value) AS min_value_118_0,
    avg(values_118_0.measured_value) AS value_118_0,
    count(values_118_0.*) AS count_118_0,
    max(values_119_0.measured_value) AS max_value_119_0,
    min(values_119_0.measured_value) AS min_value_119_0,
    avg(values_119_0.measured_value) AS value_119_0,
    count(values_119_0.*) AS count_119_0
   FROM ((((((((((((((((((((((((((((((((public.tbl_analysis_entities
     JOIN public.tbl_physical_samples ON ((tbl_physical_samples.physical_sample_id = tbl_analysis_entities.physical_sample_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM ((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
          WHERE (tbl_datasets.method_id = 8)) values_8_0 ON ((tbl_analysis_entities.analysis_entity_id = values_8_0.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM (((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
             LEFT JOIN public.tbl_analysis_entity_prep_methods ON ((tbl_analysis_entity_prep_methods.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
          WHERE ((tbl_datasets.method_id = 32) AND (COALESCE(tbl_analysis_entity_prep_methods.method_id, 0) = 124))) values_32_124 ON ((tbl_analysis_entities.analysis_entity_id = values_32_124.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM ((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
          WHERE (tbl_datasets.method_id = 32)) values_32_0 ON ((tbl_analysis_entities.analysis_entity_id = values_32_0.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM (((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
             LEFT JOIN public.tbl_analysis_entity_prep_methods ON ((tbl_analysis_entity_prep_methods.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
          WHERE ((tbl_datasets.method_id = 32) AND (COALESCE(tbl_analysis_entity_prep_methods.method_id, 0) = 112))) values_32_112 ON ((tbl_analysis_entities.analysis_entity_id = values_32_112.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM (((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
             LEFT JOIN public.tbl_analysis_entity_prep_methods ON ((tbl_analysis_entity_prep_methods.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
          WHERE ((tbl_datasets.method_id = 32) AND (COALESCE(tbl_analysis_entity_prep_methods.method_id, 0) = 82))) values_32_82 ON ((tbl_analysis_entities.analysis_entity_id = values_32_82.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM (((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
             LEFT JOIN public.tbl_analysis_entity_prep_methods ON ((tbl_analysis_entity_prep_methods.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
          WHERE ((tbl_datasets.method_id = 33) AND (COALESCE(tbl_analysis_entity_prep_methods.method_id, 0) = 112))) values_33_112 ON ((tbl_analysis_entities.analysis_entity_id = values_33_112.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM (((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
             LEFT JOIN public.tbl_analysis_entity_prep_methods ON ((tbl_analysis_entity_prep_methods.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
          WHERE ((tbl_datasets.method_id = 33) AND (COALESCE(tbl_analysis_entity_prep_methods.method_id, 0) = 82))) values_33_82 ON ((tbl_analysis_entities.analysis_entity_id = values_33_82.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM ((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
          WHERE (tbl_datasets.method_id = 33)) values_33_0 ON ((tbl_analysis_entities.analysis_entity_id = values_33_0.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM (((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
             LEFT JOIN public.tbl_analysis_entity_prep_methods ON ((tbl_analysis_entity_prep_methods.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
          WHERE ((tbl_datasets.method_id = 33) AND (COALESCE(tbl_analysis_entity_prep_methods.method_id, 0) = 87))) values_33_87 ON ((tbl_analysis_entities.analysis_entity_id = values_33_87.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM (((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
             LEFT JOIN public.tbl_analysis_entity_prep_methods ON ((tbl_analysis_entity_prep_methods.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
          WHERE ((tbl_datasets.method_id = 35) AND (COALESCE(tbl_analysis_entity_prep_methods.method_id, 0) = 124))) values_35_124 ON ((tbl_analysis_entities.analysis_entity_id = values_35_124.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM ((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
          WHERE (tbl_datasets.method_id = 35)) values_35_0 ON ((tbl_analysis_entities.analysis_entity_id = values_35_0.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM (((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
             LEFT JOIN public.tbl_analysis_entity_prep_methods ON ((tbl_analysis_entity_prep_methods.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
          WHERE ((tbl_datasets.method_id = 35) AND (COALESCE(tbl_analysis_entity_prep_methods.method_id, 0) = 82))) values_35_82 ON ((tbl_analysis_entities.analysis_entity_id = values_35_82.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM ((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
          WHERE (tbl_datasets.method_id = 36)) values_36_0 ON ((tbl_analysis_entities.analysis_entity_id = values_36_0.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM (((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
             LEFT JOIN public.tbl_analysis_entity_prep_methods ON ((tbl_analysis_entity_prep_methods.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
          WHERE ((tbl_datasets.method_id = 36) AND (COALESCE(tbl_analysis_entity_prep_methods.method_id, 0) = 82))) values_36_82 ON ((tbl_analysis_entities.analysis_entity_id = values_36_82.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM (((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
             LEFT JOIN public.tbl_analysis_entity_prep_methods ON ((tbl_analysis_entity_prep_methods.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
          WHERE ((tbl_datasets.method_id = 37) AND (COALESCE(tbl_analysis_entity_prep_methods.method_id, 0) = 112))) values_37_112 ON ((tbl_analysis_entities.analysis_entity_id = values_37_112.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM (((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
             LEFT JOIN public.tbl_analysis_entity_prep_methods ON ((tbl_analysis_entity_prep_methods.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
          WHERE ((tbl_datasets.method_id = 37) AND (COALESCE(tbl_analysis_entity_prep_methods.method_id, 0) = 124))) values_37_124 ON ((tbl_analysis_entities.analysis_entity_id = values_37_124.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM ((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
          WHERE (tbl_datasets.method_id = 37)) values_37_0 ON ((tbl_analysis_entities.analysis_entity_id = values_37_0.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM (((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
             LEFT JOIN public.tbl_analysis_entity_prep_methods ON ((tbl_analysis_entity_prep_methods.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
          WHERE ((tbl_datasets.method_id = 74) AND (COALESCE(tbl_analysis_entity_prep_methods.method_id, 0) = 124))) values_74_124 ON ((tbl_analysis_entities.analysis_entity_id = values_74_124.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM (((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
             LEFT JOIN public.tbl_analysis_entity_prep_methods ON ((tbl_analysis_entity_prep_methods.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
          WHERE ((tbl_datasets.method_id = 74) AND (COALESCE(tbl_analysis_entity_prep_methods.method_id, 0) = 82))) values_74_82 ON ((tbl_analysis_entities.analysis_entity_id = values_74_82.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM (((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
             LEFT JOIN public.tbl_analysis_entity_prep_methods ON ((tbl_analysis_entity_prep_methods.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
          WHERE ((tbl_datasets.method_id = 74) AND (COALESCE(tbl_analysis_entity_prep_methods.method_id, 0) = 112))) values_74_112 ON ((tbl_analysis_entities.analysis_entity_id = values_74_112.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM ((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
          WHERE (tbl_datasets.method_id = 74)) values_74_0 ON ((tbl_analysis_entities.analysis_entity_id = values_74_0.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM ((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
          WHERE (tbl_datasets.method_id = 94)) values_94_0 ON ((tbl_analysis_entities.analysis_entity_id = values_94_0.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM (((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
             LEFT JOIN public.tbl_analysis_entity_prep_methods ON ((tbl_analysis_entity_prep_methods.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
          WHERE ((tbl_datasets.method_id = 94) AND (COALESCE(tbl_analysis_entity_prep_methods.method_id, 0) = 82))) values_94_82 ON ((tbl_analysis_entities.analysis_entity_id = values_94_82.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM ((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
          WHERE (tbl_datasets.method_id = 106)) values_106_0 ON ((tbl_analysis_entities.analysis_entity_id = values_106_0.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM ((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
          WHERE (tbl_datasets.method_id = 107)) values_107_0 ON ((tbl_analysis_entities.analysis_entity_id = values_107_0.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM ((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
          WHERE (tbl_datasets.method_id = 109)) values_109_0 ON ((tbl_analysis_entities.analysis_entity_id = values_109_0.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM ((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
          WHERE (tbl_datasets.method_id = 110)) values_110_0 ON ((tbl_analysis_entities.analysis_entity_id = values_110_0.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM ((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
          WHERE (tbl_datasets.method_id = 111)) values_111_0 ON ((tbl_analysis_entities.analysis_entity_id = values_111_0.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM ((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
          WHERE (tbl_datasets.method_id = 117)) values_117_0 ON ((tbl_analysis_entities.analysis_entity_id = values_117_0.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM ((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
          WHERE (tbl_datasets.method_id = 118)) values_118_0 ON ((tbl_analysis_entities.analysis_entity_id = values_118_0.analysis_entity_id)))
     LEFT JOIN ( SELECT tbl_measured_values.measured_value,
            tbl_measured_values.analysis_entity_id
           FROM ((public.tbl_measured_values
             JOIN public.tbl_analysis_entities tbl_analysis_entities_1 ON ((tbl_measured_values.analysis_entity_id = tbl_analysis_entities_1.analysis_entity_id)))
             JOIN public.tbl_datasets ON ((tbl_datasets.dataset_id = tbl_analysis_entities_1.dataset_id)))
          WHERE (tbl_datasets.method_id = 119)) values_119_0 ON ((tbl_analysis_entities.analysis_entity_id = values_119_0.analysis_entity_id)))
  GROUP BY tbl_physical_samples.physical_sample_id
  ORDER BY tbl_physical_samples.physical_sample_id;


--
-- Name: original_phrases; Type: TABLE; Schema: metainformation; Owner: -
--

CREATE TABLE original_phrases (
    id integer NOT NULL,
    phrase text NOT NULL
);


--
-- Name: original_phrases_id_seq; Type: SEQUENCE; Schema: metainformation; Owner: -
--

CREATE SEQUENCE original_phrases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: original_phrases_id_seq; Type: SEQUENCE OWNED BY; Schema: metainformation; Owner: -
--

ALTER SEQUENCE original_phrases_id_seq OWNED BY original_phrases.id;


--
-- Name: tbl_denormalized_measured_values; Type: TABLE; Schema: metainformation; Owner: -
--

CREATE TABLE tbl_denormalized_measured_values (
    physical_sample_id integer,
    value_8_0 numeric,
    value_32_124 numeric,
    value_32_0 numeric,
    value_32_112 numeric,
    value_32_82 numeric,
    value_33_112 numeric,
    value_33_82 numeric,
    value_33_0 numeric,
    value_33_87 numeric,
    value_35_124 numeric,
    value_35_0 numeric,
    value_35_82 numeric,
    value_36_0 numeric,
    value_36_82 numeric,
    value_37_112 numeric,
    value_37_124 numeric,
    value_37_0 numeric,
    value_74_124 numeric,
    value_74_82 numeric,
    value_74_112 numeric,
    value_74_0 numeric,
    value_94_0 numeric,
    value_94_82 numeric,
    value_106_0 numeric,
    value_107_0 numeric,
    value_109_0 numeric,
    value_110_0 numeric,
    value_111_0 numeric,
    value_117_0 numeric,
    value_118_0 numeric,
    value_119_0 numeric
);


--
-- Name: tbl_foreign_relations; Type: TABLE; Schema: metainformation; Owner: -
--

CREATE TABLE tbl_foreign_relations (
    source_table information_schema.sql_identifier NOT NULL,
    source_column information_schema.sql_identifier NOT NULL,
    target_table information_schema.sql_identifier NOT NULL,
    target_column information_schema.sql_identifier NOT NULL,
    weight integer,
    source_target_logic text,
    target_source_logic text
);


--
-- Name: tbl_view_states; Type: TABLE; Schema: metainformation; Owner: -
--

CREATE TABLE tbl_view_states (
    view_state_id integer NOT NULL,
    view_state text,
    creatation_date timestamp with time zone DEFAULT clock_timestamp(),
    session_id character varying(256)
);


--
-- Name: tbl_view_states_view_state_id_seq; Type: SEQUENCE; Schema: metainformation; Owner: -
--

CREATE SEQUENCE tbl_view_states_view_state_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_view_states_view_state_id_seq; Type: SEQUENCE OWNED BY; Schema: metainformation; Owner: -
--

ALTER SEQUENCE tbl_view_states_view_state_id_seq OWNED BY tbl_view_states.view_state_id;


--
-- Name: translated_phrases; Type: TABLE; Schema: metainformation; Owner: -
--

CREATE TABLE translated_phrases (
    id integer NOT NULL,
    original_phrase_id integer NOT NULL,
    translated_phrase text,
    language character varying(8)
);


--
-- Name: translated_phrases_id_seq; Type: SEQUENCE; Schema: metainformation; Owner: -
--

CREATE SEQUENCE translated_phrases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: translated_phrases_id_seq; Type: SEQUENCE OWNED BY; Schema: metainformation; Owner: -
--

ALTER SEQUENCE translated_phrases_id_seq OWNED BY translated_phrases.id;


SET search_path = public, pg_catalog;

--
-- Name: tbl_abundance_elements_abundance_element_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_abundance_elements_abundance_element_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_abundance_elements_abundance_element_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_abundance_elements_abundance_element_id_seq OWNED BY tbl_abundance_elements.abundance_element_id;


--
-- Name: tbl_abundance_ident_levels_abundance_ident_level_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_abundance_ident_levels_abundance_ident_level_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_abundance_ident_levels_abundance_ident_level_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_abundance_ident_levels_abundance_ident_level_id_seq OWNED BY tbl_abundance_ident_levels.abundance_ident_level_id;


--
-- Name: tbl_abundance_modifications_abundance_modification_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_abundance_modifications_abundance_modification_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_abundance_modifications_abundance_modification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_abundance_modifications_abundance_modification_id_seq OWNED BY tbl_abundance_modifications.abundance_modification_id;


--
-- Name: tbl_abundances_abundance_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_abundances_abundance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_abundances_abundance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_abundances_abundance_id_seq OWNED BY tbl_abundances.abundance_id;


--
-- Name: tbl_activity_types_activity_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_activity_types_activity_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_activity_types_activity_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_activity_types_activity_type_id_seq OWNED BY tbl_activity_types.activity_type_id;


--
-- Name: tbl_aggregate_datasets_aggregate_dataset_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_aggregate_datasets_aggregate_dataset_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_aggregate_datasets_aggregate_dataset_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_aggregate_datasets_aggregate_dataset_id_seq OWNED BY tbl_aggregate_datasets.aggregate_dataset_id;


--
-- Name: tbl_aggregate_order_types_aggregate_order_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_aggregate_order_types_aggregate_order_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_aggregate_order_types_aggregate_order_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_aggregate_order_types_aggregate_order_type_id_seq OWNED BY tbl_aggregate_order_types.aggregate_order_type_id;


--
-- Name: tbl_aggregate_sample_ages_aggregate_sample_age_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_aggregate_sample_ages_aggregate_sample_age_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_aggregate_sample_ages_aggregate_sample_age_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_aggregate_sample_ages_aggregate_sample_age_id_seq OWNED BY tbl_aggregate_sample_ages.aggregate_sample_age_id;


--
-- Name: tbl_aggregate_samples_aggregate_sample_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_aggregate_samples_aggregate_sample_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_aggregate_samples_aggregate_sample_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_aggregate_samples_aggregate_sample_id_seq OWNED BY tbl_aggregate_samples.aggregate_sample_id;


--
-- Name: tbl_alt_ref_types_alt_ref_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_alt_ref_types_alt_ref_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_alt_ref_types_alt_ref_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_alt_ref_types_alt_ref_type_id_seq OWNED BY tbl_alt_ref_types.alt_ref_type_id;


--
-- Name: tbl_analysis_entities_analysis_entity_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_analysis_entities_analysis_entity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_analysis_entities_analysis_entity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_analysis_entities_analysis_entity_id_seq OWNED BY tbl_analysis_entities.analysis_entity_id;


--
-- Name: tbl_analysis_entity_ages_analysis_entity_age_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_analysis_entity_ages_analysis_entity_age_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_analysis_entity_ages_analysis_entity_age_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_analysis_entity_ages_analysis_entity_age_id_seq OWNED BY tbl_analysis_entity_ages.analysis_entity_age_id;


--
-- Name: tbl_analysis_entity_dimensions_analysis_entity_dimension_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_analysis_entity_dimensions_analysis_entity_dimension_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_analysis_entity_dimensions_analysis_entity_dimension_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_analysis_entity_dimensions_analysis_entity_dimension_id_seq OWNED BY tbl_analysis_entity_dimensions.analysis_entity_dimension_id;


--
-- Name: tbl_analysis_entity_prep_meth_analysis_entity_prep_method_i_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_analysis_entity_prep_meth_analysis_entity_prep_method_i_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_analysis_entity_prep_meth_analysis_entity_prep_method_i_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_analysis_entity_prep_meth_analysis_entity_prep_method_i_seq OWNED BY tbl_analysis_entity_prep_methods.analysis_entity_prep_method_id;


--
-- Name: tbl_association_types_association_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_association_types_association_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_association_types_association_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_association_types_association_type_id_seq OWNED BY tbl_species_association_types.association_type_id;


--
-- Name: tbl_biblio_biblio_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_biblio_biblio_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_biblio_biblio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_biblio_biblio_id_seq OWNED BY tbl_biblio.biblio_id;


--
-- Name: tbl_biblio_keywords_biblio_keyword_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_biblio_keywords_biblio_keyword_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_biblio_keywords_biblio_keyword_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_biblio_keywords_biblio_keyword_id_seq OWNED BY tbl_biblio_keywords.biblio_keyword_id;


--
-- Name: tbl_ceramics_ceramics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_ceramics_ceramics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_ceramics_ceramics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_ceramics_ceramics_id_seq OWNED BY tbl_ceramics.ceramics_id;


--
-- Name: tbl_ceramics_measurement_look_ceramics_measurement_lookup_i_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_ceramics_measurement_look_ceramics_measurement_lookup_i_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_ceramics_measurement_look_ceramics_measurement_lookup_i_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_ceramics_measurement_look_ceramics_measurement_lookup_i_seq OWNED BY tbl_ceramics_measurement_lookup.ceramics_measurement_lookup_id;


--
-- Name: tbl_ceramics_measurements_ceramics_measurement_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_ceramics_measurements_ceramics_measurement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_ceramics_measurements_ceramics_measurement_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_ceramics_measurements_ceramics_measurement_id_seq OWNED BY tbl_ceramics_measurements.ceramics_measurement_id;


--
-- Name: tbl_chron_control_types_chron_control_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_chron_control_types_chron_control_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_chron_control_types_chron_control_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_chron_control_types_chron_control_type_id_seq OWNED BY tbl_chron_control_types.chron_control_type_id;


--
-- Name: tbl_chron_controls_chron_control_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_chron_controls_chron_control_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_chron_controls_chron_control_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_chron_controls_chron_control_id_seq OWNED BY tbl_chron_controls.chron_control_id;


--
-- Name: tbl_chronologies_chronology_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_chronologies_chronology_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_chronologies_chronology_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_chronologies_chronology_id_seq OWNED BY tbl_chronologies.chronology_id;


--
-- Name: tbl_collections_or_journals_collection_or_journal_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_collections_or_journals_collection_or_journal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_collections_or_journals_collection_or_journal_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_collections_or_journals_collection_or_journal_id_seq OWNED BY tbl_collections_or_journals.collection_or_journal_id;


--
-- Name: tbl_colours_colour_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_colours_colour_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_colours_colour_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_colours_colour_id_seq OWNED BY tbl_colours.colour_id;


--
-- Name: tbl_contact_types_contact_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_contact_types_contact_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_contact_types_contact_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_contact_types_contact_type_id_seq OWNED BY tbl_contact_types.contact_type_id;


--
-- Name: tbl_contacts_contact_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_contacts_contact_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_contacts_contact_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_contacts_contact_id_seq OWNED BY tbl_contacts.contact_id;


--
-- Name: tbl_coordinate_method_dimensi_coordinate_method_dimension_i_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_coordinate_method_dimensi_coordinate_method_dimension_i_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_coordinate_method_dimensi_coordinate_method_dimension_i_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_coordinate_method_dimensi_coordinate_method_dimension_i_seq OWNED BY tbl_coordinate_method_dimensions.coordinate_method_dimension_id;


--
-- Name: tbl_data_type_groups_data_type_group_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_data_type_groups_data_type_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_data_type_groups_data_type_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_data_type_groups_data_type_group_id_seq OWNED BY tbl_data_type_groups.data_type_group_id;


--
-- Name: tbl_data_types_data_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_data_types_data_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_data_types_data_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_data_types_data_type_id_seq OWNED BY tbl_data_types.data_type_id;


--
-- Name: tbl_dataset_contacts_dataset_contact_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_dataset_contacts_dataset_contact_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_dataset_contacts_dataset_contact_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_dataset_contacts_dataset_contact_id_seq OWNED BY tbl_dataset_contacts.dataset_contact_id;


--
-- Name: tbl_dataset_masters_master_set_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_dataset_masters_master_set_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_dataset_masters_master_set_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_dataset_masters_master_set_id_seq OWNED BY tbl_dataset_masters.master_set_id;


--
-- Name: tbl_dataset_submission_types_submission_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_dataset_submission_types_submission_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_dataset_submission_types_submission_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_dataset_submission_types_submission_type_id_seq OWNED BY tbl_dataset_submission_types.submission_type_id;


--
-- Name: tbl_dataset_submissions_dataset_submission_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_dataset_submissions_dataset_submission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_dataset_submissions_dataset_submission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_dataset_submissions_dataset_submission_id_seq OWNED BY tbl_dataset_submissions.dataset_submission_id;


--
-- Name: tbl_datasets_dataset_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_datasets_dataset_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_datasets_dataset_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_datasets_dataset_id_seq OWNED BY tbl_datasets.dataset_id;


--
-- Name: tbl_dating_labs_dating_lab_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_dating_labs_dating_lab_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_dating_labs_dating_lab_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_dating_labs_dating_lab_id_seq OWNED BY tbl_dating_labs.dating_lab_id;


--
-- Name: tbl_dating_material_dating_material_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_dating_material_dating_material_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_dating_material_dating_material_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_dating_material_dating_material_id_seq OWNED BY tbl_dating_material.dating_material_id;


--
-- Name: tbl_dating_uncertainty_dating_uncertainty_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_dating_uncertainty_dating_uncertainty_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_dating_uncertainty_dating_uncertainty_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_dating_uncertainty_dating_uncertainty_id_seq OWNED BY tbl_dating_uncertainty.dating_uncertainty_id;


--
-- Name: tbl_dendro_date_notes_dendro_date_note_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_dendro_date_notes_dendro_date_note_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_dendro_date_notes_dendro_date_note_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_dendro_date_notes_dendro_date_note_id_seq OWNED BY tbl_dendro_date_notes.dendro_date_note_id;


--
-- Name: tbl_dendro_dates_dendro_date_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_dendro_dates_dendro_date_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_dendro_dates_dendro_date_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_dendro_dates_dendro_date_id_seq OWNED BY tbl_dendro_dates.dendro_date_id;


--
-- Name: tbl_dendro_dendro_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_dendro_dendro_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_dendro_dendro_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_dendro_dendro_id_seq OWNED BY tbl_dendro.dendro_id;


--
-- Name: tbl_dendro_measurement_lookup_dendro_measurement_lookup_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_dendro_measurement_lookup_dendro_measurement_lookup_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_dendro_measurement_lookup_dendro_measurement_lookup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_dendro_measurement_lookup_dendro_measurement_lookup_id_seq OWNED BY tbl_dendro_measurement_lookup.dendro_measurement_lookup_id;


--
-- Name: tbl_dendro_measurements_dendro_measurement_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_dendro_measurements_dendro_measurement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_dendro_measurements_dendro_measurement_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_dendro_measurements_dendro_measurement_id_seq OWNED BY tbl_dendro_measurements.dendro_measurement_id;


--
-- Name: tbl_dimensions_dimension_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_dimensions_dimension_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_dimensions_dimension_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_dimensions_dimension_id_seq OWNED BY tbl_dimensions.dimension_id;


--
-- Name: tbl_ecocode_definitions_ecocode_definition_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_ecocode_definitions_ecocode_definition_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_ecocode_definitions_ecocode_definition_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_ecocode_definitions_ecocode_definition_id_seq OWNED BY tbl_ecocode_definitions.ecocode_definition_id;


--
-- Name: tbl_ecocode_groups_ecocode_group_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_ecocode_groups_ecocode_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_ecocode_groups_ecocode_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_ecocode_groups_ecocode_group_id_seq OWNED BY tbl_ecocode_groups.ecocode_group_id;


--
-- Name: tbl_ecocode_systems_ecocode_system_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_ecocode_systems_ecocode_system_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_ecocode_systems_ecocode_system_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_ecocode_systems_ecocode_system_id_seq OWNED BY tbl_ecocode_systems.ecocode_system_id;


--
-- Name: tbl_ecocodes_ecocode_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_ecocodes_ecocode_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_ecocodes_ecocode_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_ecocodes_ecocode_id_seq OWNED BY tbl_ecocodes.ecocode_id;


--
-- Name: tbl_feature_types_feature_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_feature_types_feature_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_feature_types_feature_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_feature_types_feature_type_id_seq OWNED BY tbl_feature_types.feature_type_id;


--
-- Name: tbl_features_feature_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_features_feature_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_features_feature_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_features_feature_id_seq OWNED BY tbl_features.feature_id;


--
-- Name: tbl_geochron_refs_geochron_ref_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_geochron_refs_geochron_ref_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_geochron_refs_geochron_ref_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_geochron_refs_geochron_ref_id_seq OWNED BY tbl_geochron_refs.geochron_ref_id;


--
-- Name: tbl_geochronology_geochron_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_geochronology_geochron_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_geochronology_geochron_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_geochronology_geochron_id_seq OWNED BY tbl_geochronology.geochron_id;


--
-- Name: tbl_horizons_horizon_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_horizons_horizon_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_horizons_horizon_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_horizons_horizon_id_seq OWNED BY tbl_horizons.horizon_id;


--
-- Name: tbl_identification_levels_identification_level_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_identification_levels_identification_level_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_identification_levels_identification_level_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_identification_levels_identification_level_id_seq OWNED BY tbl_identification_levels.identification_level_id;


--
-- Name: tbl_image_types_image_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_image_types_image_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_image_types_image_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_image_types_image_type_id_seq OWNED BY tbl_image_types.image_type_id;


--
-- Name: tbl_imported_taxa_replacements_imported_taxa_replacement_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_imported_taxa_replacements_imported_taxa_replacement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_imported_taxa_replacements_imported_taxa_replacement_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_imported_taxa_replacements_imported_taxa_replacement_id_seq OWNED BY tbl_imported_taxa_replacements.imported_taxa_replacement_id;


--
-- Name: tbl_keywords_keyword_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_keywords_keyword_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_keywords_keyword_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_keywords_keyword_id_seq OWNED BY tbl_keywords.keyword_id;


--
-- Name: tbl_languages_language_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_languages_language_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_languages_language_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_languages_language_id_seq OWNED BY tbl_languages.language_id;


--
-- Name: tbl_lithology_lithology_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_lithology_lithology_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_lithology_lithology_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_lithology_lithology_id_seq OWNED BY tbl_lithology.lithology_id;


--
-- Name: tbl_location_types_location_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_location_types_location_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_location_types_location_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_location_types_location_type_id_seq OWNED BY tbl_location_types.location_type_id;


--
-- Name: tbl_locations_location_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_locations_location_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_locations_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_locations_location_id_seq OWNED BY tbl_locations.location_id;


--
-- Name: tbl_mcr_names_taxon_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_mcr_names_taxon_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_mcr_names_taxon_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_mcr_names_taxon_id_seq OWNED BY tbl_mcr_names.taxon_id;


--
-- Name: tbl_mcr_summary_data_mcr_summary_data_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_mcr_summary_data_mcr_summary_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_mcr_summary_data_mcr_summary_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_mcr_summary_data_mcr_summary_data_id_seq OWNED BY tbl_mcr_summary_data.mcr_summary_data_id;


--
-- Name: tbl_mcrdata_birmbeetledat_mcrdata_birmbeetledat_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_mcrdata_birmbeetledat_mcrdata_birmbeetledat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_mcrdata_birmbeetledat_mcrdata_birmbeetledat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_mcrdata_birmbeetledat_mcrdata_birmbeetledat_id_seq OWNED BY tbl_mcrdata_birmbeetledat.mcrdata_birmbeetledat_id;


--
-- Name: tbl_measured_value_dimensions_measured_value_dimension_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_measured_value_dimensions_measured_value_dimension_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_measured_value_dimensions_measured_value_dimension_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_measured_value_dimensions_measured_value_dimension_id_seq OWNED BY tbl_measured_value_dimensions.measured_value_dimension_id;


--
-- Name: tbl_measured_values_measured_value_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_measured_values_measured_value_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_measured_values_measured_value_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_measured_values_measured_value_id_seq OWNED BY tbl_measured_values.measured_value_id;


--
-- Name: tbl_method_groups_method_group_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_method_groups_method_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_method_groups_method_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_method_groups_method_group_id_seq OWNED BY tbl_method_groups.method_group_id;


--
-- Name: tbl_methods_method_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_methods_method_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_methods_method_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_methods_method_id_seq OWNED BY tbl_methods.method_id;


--
-- Name: tbl_modification_types_modification_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_modification_types_modification_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_modification_types_modification_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_modification_types_modification_type_id_seq OWNED BY tbl_modification_types.modification_type_id;


--
-- Name: tbl_physical_sample_features_physical_sample_feature_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_physical_sample_features_physical_sample_feature_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_physical_sample_features_physical_sample_feature_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_physical_sample_features_physical_sample_feature_id_seq OWNED BY tbl_physical_sample_features.physical_sample_feature_id;


--
-- Name: tbl_physical_samples_physical_sample_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_physical_samples_physical_sample_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_physical_samples_physical_sample_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_physical_samples_physical_sample_id_seq OWNED BY tbl_physical_samples.physical_sample_id;


--
-- Name: tbl_project_stage_project_stage_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_project_stage_project_stage_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_project_stage_project_stage_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_project_stage_project_stage_id_seq OWNED BY tbl_project_stages.project_stage_id;


--
-- Name: tbl_project_types_project_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_project_types_project_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_project_types_project_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_project_types_project_type_id_seq OWNED BY tbl_project_types.project_type_id;


--
-- Name: tbl_projects_project_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_projects_project_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_projects_project_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_projects_project_id_seq OWNED BY tbl_projects.project_id;


--
-- Name: tbl_publication_types_publication_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_publication_types_publication_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_publication_types_publication_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_publication_types_publication_type_id_seq OWNED BY tbl_publication_types.publication_type_id;


--
-- Name: tbl_publishers_publisher_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_publishers_publisher_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_publishers_publisher_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_publishers_publisher_id_seq OWNED BY tbl_publishers.publisher_id;


--
-- Name: tbl_radiocarbon_calibration_radiocarbon_calibration_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_radiocarbon_calibration_radiocarbon_calibration_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_radiocarbon_calibration_radiocarbon_calibration_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_radiocarbon_calibration_radiocarbon_calibration_id_seq OWNED BY tbl_radiocarbon_calibration.radiocarbon_calibration_id;


--
-- Name: tbl_rdb_codes_rdb_code_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_rdb_codes_rdb_code_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_rdb_codes_rdb_code_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_rdb_codes_rdb_code_id_seq OWNED BY tbl_rdb_codes.rdb_code_id;


--
-- Name: tbl_rdb_rdb_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_rdb_rdb_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_rdb_rdb_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_rdb_rdb_id_seq OWNED BY tbl_rdb.rdb_id;


--
-- Name: tbl_rdb_systems_rdb_system_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_rdb_systems_rdb_system_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_rdb_systems_rdb_system_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_rdb_systems_rdb_system_id_seq OWNED BY tbl_rdb_systems.rdb_system_id;


--
-- Name: tbl_record_types_record_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_record_types_record_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_record_types_record_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_record_types_record_type_id_seq OWNED BY tbl_record_types.record_type_id;


--
-- Name: tbl_relative_age_refs_relative_age_ref_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_relative_age_refs_relative_age_ref_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_relative_age_refs_relative_age_ref_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_relative_age_refs_relative_age_ref_id_seq OWNED BY tbl_relative_age_refs.relative_age_ref_id;


--
-- Name: tbl_relative_age_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_relative_age_types (
    relative_age_type_id integer NOT NULL,
    age_type character varying,
    description text,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE tbl_relative_age_types; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_relative_age_types IS '20130723PIB: replaced date_updated column with new one with same name but correct data type
20140226EE: replaced date_updated column with correct time data type';


--
-- Name: COLUMN tbl_relative_age_types.age_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_relative_age_types.age_type IS 'name of chronological age type, e.g. archaeological period, single calendar date, calendar age range, blytt-sernander';


--
-- Name: COLUMN tbl_relative_age_types.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tbl_relative_age_types.description IS 'description of chronological age type, e.g. period defined by archaeological and or geological dates representing cultural activity period, climate period defined by palaeo-vegetation records';


--
-- Name: tbl_relative_age_types_relative_age_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_relative_age_types_relative_age_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_relative_age_types_relative_age_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_relative_age_types_relative_age_type_id_seq OWNED BY tbl_relative_age_types.relative_age_type_id;


--
-- Name: tbl_relative_ages_relative_age_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_relative_ages_relative_age_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_relative_ages_relative_age_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_relative_ages_relative_age_id_seq OWNED BY tbl_relative_ages.relative_age_id;


--
-- Name: tbl_relative_dates_relative_date_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_relative_dates_relative_date_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_relative_dates_relative_date_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_relative_dates_relative_date_id_seq OWNED BY tbl_relative_dates.relative_date_id;


--
-- Name: tbl_sample_alt_refs_sample_alt_ref_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_alt_refs_sample_alt_ref_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_alt_refs_sample_alt_ref_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_alt_refs_sample_alt_ref_id_seq OWNED BY tbl_sample_alt_refs.sample_alt_ref_id;


--
-- Name: tbl_sample_colours_sample_colour_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_colours_sample_colour_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_colours_sample_colour_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_colours_sample_colour_id_seq OWNED BY tbl_sample_colours.sample_colour_id;


--
-- Name: tbl_sample_coordinates_sample_coordinates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_coordinates_sample_coordinates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_coordinates_sample_coordinates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_coordinates_sample_coordinates_id_seq OWNED BY tbl_sample_coordinates.sample_coordinate_id;


--
-- Name: tbl_sample_description_sample_sample_description_sample_gro_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_description_sample_sample_description_sample_gro_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_description_sample_sample_description_sample_gro_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_description_sample_sample_description_sample_gro_seq OWNED BY tbl_sample_description_sample_group_contexts.sample_description_sample_group_context_id;


--
-- Name: tbl_sample_description_types_sample_description_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_description_types_sample_description_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_description_types_sample_description_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_description_types_sample_description_type_id_seq OWNED BY tbl_sample_description_types.sample_description_type_id;


--
-- Name: tbl_sample_descriptions_sample_description_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_descriptions_sample_description_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_descriptions_sample_description_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_descriptions_sample_description_id_seq OWNED BY tbl_sample_descriptions.sample_description_id;


--
-- Name: tbl_sample_dimensions_sample_dimension_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_dimensions_sample_dimension_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_dimensions_sample_dimension_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_dimensions_sample_dimension_id_seq OWNED BY tbl_sample_dimensions.sample_dimension_id;


--
-- Name: tbl_sample_geometry_sample_geometry_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_geometry_sample_geometry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_group_coordinates_sample_group_position_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_group_coordinates_sample_group_position_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_group_coordinates_sample_group_position_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_group_coordinates_sample_group_position_id_seq OWNED BY tbl_sample_group_coordinates.sample_group_position_id;


--
-- Name: tbl_sample_group_description__sample_group_desciption_sampl_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_group_description__sample_group_desciption_sampl_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_group_description__sample_group_desciption_sampl_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_group_description__sample_group_desciption_sampl_seq OWNED BY tbl_sample_group_description_type_sampling_contexts.sample_group_description_type_sampling_context_id;


--
-- Name: tbl_sample_group_description__sample_group_description_type_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_group_description__sample_group_description_type_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_group_description__sample_group_description_type_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_group_description__sample_group_description_type_seq OWNED BY tbl_sample_group_description_types.sample_group_description_type_id;


--
-- Name: tbl_sample_group_descriptions_sample_group_description_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_group_descriptions_sample_group_description_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_group_descriptions_sample_group_description_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_group_descriptions_sample_group_description_id_seq OWNED BY tbl_sample_group_descriptions.sample_group_description_id;


--
-- Name: tbl_sample_group_dimensions_sample_group_dimension_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_group_dimensions_sample_group_dimension_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_group_dimensions_sample_group_dimension_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_group_dimensions_sample_group_dimension_id_seq OWNED BY tbl_sample_group_dimensions.sample_group_dimension_id;


--
-- Name: tbl_sample_group_images_sample_group_image_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_group_images_sample_group_image_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_group_images_sample_group_image_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_group_images_sample_group_image_id_seq OWNED BY tbl_sample_group_images.sample_group_image_id;


--
-- Name: tbl_sample_group_notes_sample_group_note_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_group_notes_sample_group_note_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_group_notes_sample_group_note_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_group_notes_sample_group_note_id_seq OWNED BY tbl_sample_group_notes.sample_group_note_id;


--
-- Name: tbl_sample_group_references_sample_group_reference_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_group_references_sample_group_reference_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_group_references_sample_group_reference_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_group_references_sample_group_reference_id_seq OWNED BY tbl_sample_group_references.sample_group_reference_id;


--
-- Name: tbl_sample_group_sampling_contexts_sampling_context_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_group_sampling_contexts_sampling_context_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_group_sampling_contexts_sampling_context_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_group_sampling_contexts_sampling_context_id_seq OWNED BY tbl_sample_group_sampling_contexts.sampling_context_id;


--
-- Name: tbl_sample_groups_sample_group_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_groups_sample_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_groups_sample_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_groups_sample_group_id_seq OWNED BY tbl_sample_groups.sample_group_id;


--
-- Name: tbl_sample_horizons_sample_horizon_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_horizons_sample_horizon_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_horizons_sample_horizon_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_horizons_sample_horizon_id_seq OWNED BY tbl_sample_horizons.sample_horizon_id;


--
-- Name: tbl_sample_images_sample_image_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_images_sample_image_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_images_sample_image_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_images_sample_image_id_seq OWNED BY tbl_sample_images.sample_image_id;


--
-- Name: tbl_sample_location_sampling__sample_location_type_sampling_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_location_sampling__sample_location_type_sampling_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_location_sampling__sample_location_type_sampling_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_location_sampling__sample_location_type_sampling_seq OWNED BY tbl_sample_location_type_sampling_contexts.sample_location_type_sampling_context_id;


--
-- Name: tbl_sample_location_sampling_contex_sample_location_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_location_sampling_contex_sample_location_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_location_sampling_contex_sample_location_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_location_sampling_contex_sample_location_type_id_seq OWNED BY tbl_sample_location_type_sampling_contexts.sample_location_type_id;


--
-- Name: tbl_sample_location_types_sample_location_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_location_types_sample_location_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_location_types_sample_location_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_location_types_sample_location_type_id_seq OWNED BY tbl_sample_location_types.sample_location_type_id;


--
-- Name: tbl_sample_locations_sample_location_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_locations_sample_location_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_locations_sample_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_locations_sample_location_id_seq OWNED BY tbl_sample_locations.sample_location_id;


--
-- Name: tbl_sample_notes_sample_note_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_notes_sample_note_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_notes_sample_note_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_notes_sample_note_id_seq OWNED BY tbl_sample_notes.sample_note_id;


--
-- Name: tbl_sample_types_sample_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sample_types_sample_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sample_types_sample_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sample_types_sample_type_id_seq OWNED BY tbl_sample_types.sample_type_id;


--
-- Name: tbl_season_types_season_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_season_types_season_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_season_types_season_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_season_types_season_type_id_seq OWNED BY tbl_season_types.season_type_id;


--
-- Name: tbl_seasons_season_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_seasons_season_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_seasons_season_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_seasons_season_id_seq OWNED BY tbl_seasons.season_id;


--
-- Name: tbl_site_images_site_image_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_site_images_site_image_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_site_images_site_image_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_site_images_site_image_id_seq OWNED BY tbl_site_images.site_image_id;


--
-- Name: tbl_site_locations_site_location_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_site_locations_site_location_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_site_locations_site_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_site_locations_site_location_id_seq OWNED BY tbl_site_locations.site_location_id;


--
-- Name: tbl_site_natgridrefs_site_natgridref_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_site_natgridrefs_site_natgridref_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_site_natgridrefs_site_natgridref_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_site_natgridrefs_site_natgridref_id_seq OWNED BY tbl_site_natgridrefs.site_natgridref_id;


--
-- Name: tbl_site_other_records_site_other_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_site_other_records_site_other_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_site_other_records_site_other_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_site_other_records_site_other_records_id_seq OWNED BY tbl_site_other_records.site_other_records_id;


--
-- Name: tbl_site_preservation_status_site_preservation_status_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_site_preservation_status_site_preservation_status_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_site_preservation_status_site_preservation_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_site_preservation_status_site_preservation_status_id_seq OWNED BY tbl_site_preservation_status.site_preservation_status_id;


--
-- Name: tbl_site_references_site_reference_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_site_references_site_reference_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_site_references_site_reference_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_site_references_site_reference_id_seq OWNED BY tbl_site_references.site_reference_id;


--
-- Name: tbl_sites_site_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_sites_site_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_sites_site_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_sites_site_id_seq OWNED BY tbl_sites.site_id;


--
-- Name: tbl_species_associations_species_association_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_species_associations_species_association_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_species_associations_species_association_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_species_associations_species_association_id_seq OWNED BY tbl_species_associations.species_association_id;


--
-- Name: tbl_taxa_common_names_taxon_common_name_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_taxa_common_names_taxon_common_name_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_taxa_common_names_taxon_common_name_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_taxa_common_names_taxon_common_name_id_seq OWNED BY tbl_taxa_common_names.taxon_common_name_id;


--
-- Name: tbl_taxa_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_taxa_images (
    taxa_images_id integer NOT NULL,
    image_name character varying,
    description text,
    image_location text,
    image_type_id integer,
    taxon_id integer NOT NULL,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE tbl_taxa_images; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_taxa_images IS '20140226EE: changed the data type for date_updated';


--
-- Name: tbl_taxa_images_taxa_images_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_taxa_images_taxa_images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_taxa_images_taxa_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_taxa_images_taxa_images_id_seq OWNED BY tbl_taxa_images.taxa_images_id;


--
-- Name: tbl_taxa_measured_attributes_measured_attribute_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_taxa_measured_attributes_measured_attribute_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_taxa_measured_attributes_measured_attribute_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_taxa_measured_attributes_measured_attribute_id_seq OWNED BY tbl_taxa_measured_attributes.measured_attribute_id;


--
-- Name: tbl_taxa_reference_specimens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tbl_taxa_reference_specimens (
    taxa_reference_specimen_id integer NOT NULL,
    taxon_id integer NOT NULL,
    contact_id integer NOT NULL,
    notes text,
    date_updated timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE tbl_taxa_reference_specimens; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tbl_taxa_reference_specimens IS '20140226EE: changed date_updated to correct data type';


--
-- Name: tbl_taxa_reference_specimens_taxa_reference_specimen_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_taxa_reference_specimens_taxa_reference_specimen_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_taxa_reference_specimens_taxa_reference_specimen_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_taxa_reference_specimens_taxa_reference_specimen_id_seq OWNED BY tbl_taxa_reference_specimens.taxa_reference_specimen_id;


--
-- Name: tbl_taxa_seasonality_seasonality_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_taxa_seasonality_seasonality_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_taxa_seasonality_seasonality_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_taxa_seasonality_seasonality_id_seq OWNED BY tbl_taxa_seasonality.seasonality_id;


--
-- Name: tbl_taxa_synonyms_synonym_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_taxa_synonyms_synonym_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_taxa_synonyms_synonym_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_taxa_synonyms_synonym_id_seq OWNED BY tbl_taxa_synonyms.synonym_id;


--
-- Name: tbl_taxa_tree_authors_author_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_taxa_tree_authors_author_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_taxa_tree_authors_author_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_taxa_tree_authors_author_id_seq OWNED BY tbl_taxa_tree_authors.author_id;


--
-- Name: tbl_taxa_tree_families_family_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_taxa_tree_families_family_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_taxa_tree_families_family_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_taxa_tree_families_family_id_seq OWNED BY tbl_taxa_tree_families.family_id;


--
-- Name: tbl_taxa_tree_genera_genus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_taxa_tree_genera_genus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_taxa_tree_genera_genus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_taxa_tree_genera_genus_id_seq OWNED BY tbl_taxa_tree_genera.genus_id;


--
-- Name: tbl_taxa_tree_master_taxon_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_taxa_tree_master_taxon_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_taxa_tree_master_taxon_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_taxa_tree_master_taxon_id_seq OWNED BY tbl_taxa_tree_master.taxon_id;


--
-- Name: tbl_taxa_tree_orders_order_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_taxa_tree_orders_order_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_taxa_tree_orders_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_taxa_tree_orders_order_id_seq OWNED BY tbl_taxa_tree_orders.order_id;


--
-- Name: tbl_taxonomic_order_biblio_taxonomic_order_biblio_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_taxonomic_order_biblio_taxonomic_order_biblio_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_taxonomic_order_biblio_taxonomic_order_biblio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_taxonomic_order_biblio_taxonomic_order_biblio_id_seq OWNED BY tbl_taxonomic_order_biblio.taxonomic_order_biblio_id;


--
-- Name: tbl_taxonomic_order_systems_taxonomic_order_system_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_taxonomic_order_systems_taxonomic_order_system_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_taxonomic_order_systems_taxonomic_order_system_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_taxonomic_order_systems_taxonomic_order_system_id_seq OWNED BY tbl_taxonomic_order_systems.taxonomic_order_system_id;


--
-- Name: tbl_taxonomic_order_taxonomic_order_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_taxonomic_order_taxonomic_order_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_taxonomic_order_taxonomic_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_taxonomic_order_taxonomic_order_id_seq OWNED BY tbl_taxonomic_order.taxonomic_order_id;


--
-- Name: tbl_taxonomy_notes_taxonomy_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_taxonomy_notes_taxonomy_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_taxonomy_notes_taxonomy_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_taxonomy_notes_taxonomy_notes_id_seq OWNED BY tbl_taxonomy_notes.taxonomy_notes_id;


--
-- Name: tbl_tephra_dates_tephra_date_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_tephra_dates_tephra_date_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_tephra_dates_tephra_date_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_tephra_dates_tephra_date_id_seq OWNED BY tbl_tephra_dates.tephra_date_id;


--
-- Name: tbl_tephra_refs_tephra_ref_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_tephra_refs_tephra_ref_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_tephra_refs_tephra_ref_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_tephra_refs_tephra_ref_id_seq OWNED BY tbl_tephra_refs.tephra_ref_id;


--
-- Name: tbl_tephras_tephra_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_tephras_tephra_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_tephras_tephra_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_tephras_tephra_id_seq OWNED BY tbl_tephras.tephra_id;


--
-- Name: tbl_text_biology_biology_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_text_biology_biology_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_text_biology_biology_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_text_biology_biology_id_seq OWNED BY tbl_text_biology.biology_id;


--
-- Name: tbl_text_distribution_distribution_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_text_distribution_distribution_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_text_distribution_distribution_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_text_distribution_distribution_id_seq OWNED BY tbl_text_distribution.distribution_id;


--
-- Name: tbl_text_identification_keys_key_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_text_identification_keys_key_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_text_identification_keys_key_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_text_identification_keys_key_id_seq OWNED BY tbl_text_identification_keys.key_id;


--
-- Name: tbl_units_unit_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_units_unit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_units_unit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_units_unit_id_seq OWNED BY tbl_units.unit_id;


--
-- Name: tbl_years_types_years_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tbl_years_types_years_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tbl_years_types_years_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tbl_years_types_years_type_id_seq OWNED BY tbl_years_types.years_type_id;


--
-- Name: view_taxa_tree; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW view_taxa_tree AS
 SELECT tbl_taxa_tree_authors.author_name,
    tbl_taxa_tree_master.species,
    tbl_taxa_tree_genera.genus_name,
    tbl_taxa_tree_families.family_name,
    tbl_taxa_tree_orders.order_name,
    tbl_taxa_tree_orders.sort_order
   FROM tbl_taxa_tree_orders,
    tbl_taxa_tree_master,
    tbl_taxa_tree_genera,
    tbl_taxa_tree_families,
    tbl_taxa_tree_authors
  WHERE ((((tbl_taxa_tree_master.genus_id = tbl_taxa_tree_genera.genus_id) AND (tbl_taxa_tree_genera.family_id = tbl_taxa_tree_families.family_id)) AND (tbl_taxa_tree_families.order_id = tbl_taxa_tree_orders.order_id)) AND (tbl_taxa_tree_authors.author_id = tbl_taxa_tree_master.author_id));


--
-- Name: VIEW view_taxa_tree; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW view_taxa_tree IS 'Used to view the entire taxanomic tree in one go.';


--
-- Name: view_taxa_tree_select; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW view_taxa_tree_select AS
 SELECT a.author_name AS author,
    s.species,
    s.taxon_id,
    g.genus_name AS genus,
    g.genus_id,
    f.family_name AS family,
    f.family_id,
    o.order_name,
    o.order_id
   FROM ((((tbl_taxa_tree_master s
     JOIN tbl_taxa_tree_genera g ON ((s.genus_id = g.genus_id)))
     JOIN tbl_taxa_tree_families f ON ((g.family_id = f.family_id)))
     JOIN tbl_taxa_tree_orders o ON ((f.order_id = o.order_id)))
     LEFT JOIN tbl_taxa_tree_authors a ON ((s.author_id = a.author_id)));


--
-- Name: VIEW view_taxa_tree_select; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW view_taxa_tree_select IS 'view with all taxa with one row per taxon. Includes the primary ids for each of the included items for easy selections.';


SET search_path = clearing_house, pg_catalog;

--
-- Name: tbl_clearinghouse_accepted_submissions accepted_submission_id; Type: DEFAULT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_accepted_submissions ALTER COLUMN accepted_submission_id SET DEFAULT nextval('tbl_clearinghouse_accepted_submissio_accepted_submission_id_seq'::regclass);


--
-- Name: tbl_clearinghouse_activity_log activity_log_id; Type: DEFAULT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_activity_log ALTER COLUMN activity_log_id SET DEFAULT nextval('tbl_clearinghouse_activity_log_activity_log_id_seq'::regclass);


--
-- Name: tbl_clearinghouse_info_references info_reference_id; Type: DEFAULT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_info_references ALTER COLUMN info_reference_id SET DEFAULT nextval('tbl_clearinghouse_info_references_info_reference_id_seq'::regclass);


--
-- Name: tbl_clearinghouse_sessions session_id; Type: DEFAULT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_sessions ALTER COLUMN session_id SET DEFAULT nextval('tbl_clearinghouse_sessions_session_id_seq'::regclass);


--
-- Name: tbl_clearinghouse_settings setting_id; Type: DEFAULT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_settings ALTER COLUMN setting_id SET DEFAULT nextval('tbl_clearinghouse_settings_setting_id_seq'::regclass);


--
-- Name: tbl_clearinghouse_signal_log signal_log_id; Type: DEFAULT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_signal_log ALTER COLUMN signal_log_id SET DEFAULT nextval('tbl_clearinghouse_signal_log_signal_log_id_seq'::regclass);


--
-- Name: tbl_clearinghouse_signals signal_id; Type: DEFAULT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_signals ALTER COLUMN signal_id SET DEFAULT nextval('tbl_clearinghouse_signals_signal_id_seq'::regclass);


--
-- Name: tbl_clearinghouse_submission_reject_entities reject_entity_id; Type: DEFAULT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submission_reject_entities ALTER COLUMN reject_entity_id SET DEFAULT nextval('tbl_clearinghouse_submission_reject_entiti_reject_entity_id_seq'::regclass);


--
-- Name: tbl_clearinghouse_submission_rejects submission_reject_id; Type: DEFAULT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submission_rejects ALTER COLUMN submission_reject_id SET DEFAULT nextval('tbl_clearinghouse_submission_rejects_submission_reject_id_seq'::regclass);


--
-- Name: tbl_clearinghouse_submission_tables table_id; Type: DEFAULT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submission_tables ALTER COLUMN table_id SET DEFAULT nextval('tbl_clearinghouse_submission_tables_table_id_seq'::regclass);


--
-- Name: tbl_clearinghouse_submission_xml_content_columns column_id; Type: DEFAULT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submission_xml_content_columns ALTER COLUMN column_id SET DEFAULT nextval('tbl_clearinghouse_submission_xml_content_columns_column_id_seq'::regclass);


--
-- Name: tbl_clearinghouse_submission_xml_content_records record_id; Type: DEFAULT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submission_xml_content_records ALTER COLUMN record_id SET DEFAULT nextval('tbl_clearinghouse_submission_xml_content_records_record_id_seq'::regclass);


--
-- Name: tbl_clearinghouse_submission_xml_content_tables content_table_id; Type: DEFAULT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submission_xml_content_tables ALTER COLUMN content_table_id SET DEFAULT nextval('tbl_clearinghouse_submission_xml_content_t_content_table_id_seq'::regclass);


--
-- Name: tbl_clearinghouse_submission_xml_content_values value_id; Type: DEFAULT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submission_xml_content_values ALTER COLUMN value_id SET DEFAULT nextval('tbl_clearinghouse_submission_xml_content_values_value_id_seq'::regclass);


--
-- Name: tbl_clearinghouse_submissions submission_id; Type: DEFAULT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submissions ALTER COLUMN submission_id SET DEFAULT nextval('tbl_clearinghouse_submissions_submission_id_seq'::regclass);


--
-- Name: tbl_clearinghouse_users user_id; Type: DEFAULT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_users ALTER COLUMN user_id SET DEFAULT nextval('tbl_clearinghouse_users_user_id_seq'::regclass);


SET search_path = metainformation, pg_catalog;

--
-- Name: language_definitions id; Type: DEFAULT; Schema: metainformation; Owner: -
--

ALTER TABLE ONLY language_definitions ALTER COLUMN id SET DEFAULT nextval('language_definitions_id_seq'::regclass);


--
-- Name: original_phrases id; Type: DEFAULT; Schema: metainformation; Owner: -
--

ALTER TABLE ONLY original_phrases ALTER COLUMN id SET DEFAULT nextval('original_phrases_id_seq'::regclass);


--
-- Name: tbl_view_states view_state_id; Type: DEFAULT; Schema: metainformation; Owner: -
--

ALTER TABLE ONLY tbl_view_states ALTER COLUMN view_state_id SET DEFAULT nextval('tbl_view_states_view_state_id_seq'::regclass);


--
-- Name: translated_phrases id; Type: DEFAULT; Schema: metainformation; Owner: -
--

ALTER TABLE ONLY translated_phrases ALTER COLUMN id SET DEFAULT nextval('translated_phrases_id_seq'::regclass);


SET search_path = public, pg_catalog;

--
-- Name: tbl_abundance_elements abundance_element_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_abundance_elements ALTER COLUMN abundance_element_id SET DEFAULT nextval('tbl_abundance_elements_abundance_element_id_seq'::regclass);


--
-- Name: tbl_abundance_ident_levels abundance_ident_level_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_abundance_ident_levels ALTER COLUMN abundance_ident_level_id SET DEFAULT nextval('tbl_abundance_ident_levels_abundance_ident_level_id_seq'::regclass);


--
-- Name: tbl_abundance_modifications abundance_modification_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_abundance_modifications ALTER COLUMN abundance_modification_id SET DEFAULT nextval('tbl_abundance_modifications_abundance_modification_id_seq'::regclass);


--
-- Name: tbl_abundances abundance_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_abundances ALTER COLUMN abundance_id SET DEFAULT nextval('tbl_abundances_abundance_id_seq'::regclass);


--
-- Name: tbl_activity_types activity_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_activity_types ALTER COLUMN activity_type_id SET DEFAULT nextval('tbl_activity_types_activity_type_id_seq'::regclass);


--
-- Name: tbl_aggregate_datasets aggregate_dataset_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_aggregate_datasets ALTER COLUMN aggregate_dataset_id SET DEFAULT nextval('tbl_aggregate_datasets_aggregate_dataset_id_seq'::regclass);


--
-- Name: tbl_aggregate_order_types aggregate_order_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_aggregate_order_types ALTER COLUMN aggregate_order_type_id SET DEFAULT nextval('tbl_aggregate_order_types_aggregate_order_type_id_seq'::regclass);


--
-- Name: tbl_aggregate_sample_ages aggregate_sample_age_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_aggregate_sample_ages ALTER COLUMN aggregate_sample_age_id SET DEFAULT nextval('tbl_aggregate_sample_ages_aggregate_sample_age_id_seq'::regclass);


--
-- Name: tbl_aggregate_samples aggregate_sample_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_aggregate_samples ALTER COLUMN aggregate_sample_id SET DEFAULT nextval('tbl_aggregate_samples_aggregate_sample_id_seq'::regclass);


--
-- Name: tbl_alt_ref_types alt_ref_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_alt_ref_types ALTER COLUMN alt_ref_type_id SET DEFAULT nextval('tbl_alt_ref_types_alt_ref_type_id_seq'::regclass);


--
-- Name: tbl_analysis_entities analysis_entity_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_analysis_entities ALTER COLUMN analysis_entity_id SET DEFAULT nextval('tbl_analysis_entities_analysis_entity_id_seq'::regclass);


--
-- Name: tbl_analysis_entity_ages analysis_entity_age_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_analysis_entity_ages ALTER COLUMN analysis_entity_age_id SET DEFAULT nextval('tbl_analysis_entity_ages_analysis_entity_age_id_seq'::regclass);


--
-- Name: tbl_analysis_entity_dimensions analysis_entity_dimension_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_analysis_entity_dimensions ALTER COLUMN analysis_entity_dimension_id SET DEFAULT nextval('tbl_analysis_entity_dimensions_analysis_entity_dimension_id_seq'::regclass);


--
-- Name: tbl_analysis_entity_prep_methods analysis_entity_prep_method_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_analysis_entity_prep_methods ALTER COLUMN analysis_entity_prep_method_id SET DEFAULT nextval('tbl_analysis_entity_prep_meth_analysis_entity_prep_method_i_seq'::regclass);


--
-- Name: tbl_biblio biblio_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_biblio ALTER COLUMN biblio_id SET DEFAULT nextval('tbl_biblio_biblio_id_seq'::regclass);


--
-- Name: tbl_biblio_keywords biblio_keyword_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_biblio_keywords ALTER COLUMN biblio_keyword_id SET DEFAULT nextval('tbl_biblio_keywords_biblio_keyword_id_seq'::regclass);


--
-- Name: tbl_ceramics ceramics_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ceramics ALTER COLUMN ceramics_id SET DEFAULT nextval('tbl_ceramics_ceramics_id_seq'::regclass);


--
-- Name: tbl_ceramics_measurement_lookup ceramics_measurement_lookup_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ceramics_measurement_lookup ALTER COLUMN ceramics_measurement_lookup_id SET DEFAULT nextval('tbl_ceramics_measurement_look_ceramics_measurement_lookup_i_seq'::regclass);


--
-- Name: tbl_ceramics_measurements ceramics_measurement_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ceramics_measurements ALTER COLUMN ceramics_measurement_id SET DEFAULT nextval('tbl_ceramics_measurements_ceramics_measurement_id_seq'::regclass);


--
-- Name: tbl_chron_control_types chron_control_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_chron_control_types ALTER COLUMN chron_control_type_id SET DEFAULT nextval('tbl_chron_control_types_chron_control_type_id_seq'::regclass);


--
-- Name: tbl_chron_controls chron_control_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_chron_controls ALTER COLUMN chron_control_id SET DEFAULT nextval('tbl_chron_controls_chron_control_id_seq'::regclass);


--
-- Name: tbl_chronologies chronology_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_chronologies ALTER COLUMN chronology_id SET DEFAULT nextval('tbl_chronologies_chronology_id_seq'::regclass);


--
-- Name: tbl_collections_or_journals collection_or_journal_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_collections_or_journals ALTER COLUMN collection_or_journal_id SET DEFAULT nextval('tbl_collections_or_journals_collection_or_journal_id_seq'::regclass);


--
-- Name: tbl_colours colour_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_colours ALTER COLUMN colour_id SET DEFAULT nextval('tbl_colours_colour_id_seq'::regclass);


--
-- Name: tbl_contact_types contact_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_contact_types ALTER COLUMN contact_type_id SET DEFAULT nextval('tbl_contact_types_contact_type_id_seq'::regclass);


--
-- Name: tbl_contacts contact_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_contacts ALTER COLUMN contact_id SET DEFAULT nextval('tbl_contacts_contact_id_seq'::regclass);


--
-- Name: tbl_coordinate_method_dimensions coordinate_method_dimension_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_coordinate_method_dimensions ALTER COLUMN coordinate_method_dimension_id SET DEFAULT nextval('tbl_coordinate_method_dimensi_coordinate_method_dimension_i_seq'::regclass);


--
-- Name: tbl_data_type_groups data_type_group_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_data_type_groups ALTER COLUMN data_type_group_id SET DEFAULT nextval('tbl_data_type_groups_data_type_group_id_seq'::regclass);


--
-- Name: tbl_data_types data_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_data_types ALTER COLUMN data_type_id SET DEFAULT nextval('tbl_data_types_data_type_id_seq'::regclass);


--
-- Name: tbl_dataset_contacts dataset_contact_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dataset_contacts ALTER COLUMN dataset_contact_id SET DEFAULT nextval('tbl_dataset_contacts_dataset_contact_id_seq'::regclass);


--
-- Name: tbl_dataset_masters master_set_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dataset_masters ALTER COLUMN master_set_id SET DEFAULT nextval('tbl_dataset_masters_master_set_id_seq'::regclass);


--
-- Name: tbl_dataset_submission_types submission_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dataset_submission_types ALTER COLUMN submission_type_id SET DEFAULT nextval('tbl_dataset_submission_types_submission_type_id_seq'::regclass);


--
-- Name: tbl_dataset_submissions dataset_submission_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dataset_submissions ALTER COLUMN dataset_submission_id SET DEFAULT nextval('tbl_dataset_submissions_dataset_submission_id_seq'::regclass);


--
-- Name: tbl_datasets dataset_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_datasets ALTER COLUMN dataset_id SET DEFAULT nextval('tbl_datasets_dataset_id_seq'::regclass);


--
-- Name: tbl_dating_labs dating_lab_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dating_labs ALTER COLUMN dating_lab_id SET DEFAULT nextval('tbl_dating_labs_dating_lab_id_seq'::regclass);


--
-- Name: tbl_dating_material dating_material_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dating_material ALTER COLUMN dating_material_id SET DEFAULT nextval('tbl_dating_material_dating_material_id_seq'::regclass);


--
-- Name: tbl_dating_uncertainty dating_uncertainty_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dating_uncertainty ALTER COLUMN dating_uncertainty_id SET DEFAULT nextval('tbl_dating_uncertainty_dating_uncertainty_id_seq'::regclass);


--
-- Name: tbl_dendro dendro_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dendro ALTER COLUMN dendro_id SET DEFAULT nextval('tbl_dendro_dendro_id_seq'::regclass);


--
-- Name: tbl_dendro_date_notes dendro_date_note_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dendro_date_notes ALTER COLUMN dendro_date_note_id SET DEFAULT nextval('tbl_dendro_date_notes_dendro_date_note_id_seq'::regclass);


--
-- Name: tbl_dendro_dates dendro_date_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dendro_dates ALTER COLUMN dendro_date_id SET DEFAULT nextval('tbl_dendro_dates_dendro_date_id_seq'::regclass);


--
-- Name: tbl_dendro_measurement_lookup dendro_measurement_lookup_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dendro_measurement_lookup ALTER COLUMN dendro_measurement_lookup_id SET DEFAULT nextval('tbl_dendro_measurement_lookup_dendro_measurement_lookup_id_seq'::regclass);


--
-- Name: tbl_dendro_measurements dendro_measurement_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dendro_measurements ALTER COLUMN dendro_measurement_id SET DEFAULT nextval('tbl_dendro_measurements_dendro_measurement_id_seq'::regclass);


--
-- Name: tbl_dimensions dimension_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dimensions ALTER COLUMN dimension_id SET DEFAULT nextval('tbl_dimensions_dimension_id_seq'::regclass);


--
-- Name: tbl_ecocode_definitions ecocode_definition_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ecocode_definitions ALTER COLUMN ecocode_definition_id SET DEFAULT nextval('tbl_ecocode_definitions_ecocode_definition_id_seq'::regclass);


--
-- Name: tbl_ecocode_groups ecocode_group_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ecocode_groups ALTER COLUMN ecocode_group_id SET DEFAULT nextval('tbl_ecocode_groups_ecocode_group_id_seq'::regclass);


--
-- Name: tbl_ecocode_systems ecocode_system_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ecocode_systems ALTER COLUMN ecocode_system_id SET DEFAULT nextval('tbl_ecocode_systems_ecocode_system_id_seq'::regclass);


--
-- Name: tbl_ecocodes ecocode_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ecocodes ALTER COLUMN ecocode_id SET DEFAULT nextval('tbl_ecocodes_ecocode_id_seq'::regclass);


--
-- Name: tbl_feature_types feature_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_feature_types ALTER COLUMN feature_type_id SET DEFAULT nextval('tbl_feature_types_feature_type_id_seq'::regclass);


--
-- Name: tbl_features feature_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_features ALTER COLUMN feature_id SET DEFAULT nextval('tbl_features_feature_id_seq'::regclass);


--
-- Name: tbl_geochron_refs geochron_ref_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_geochron_refs ALTER COLUMN geochron_ref_id SET DEFAULT nextval('tbl_geochron_refs_geochron_ref_id_seq'::regclass);


--
-- Name: tbl_geochronology geochron_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_geochronology ALTER COLUMN geochron_id SET DEFAULT nextval('tbl_geochronology_geochron_id_seq'::regclass);


--
-- Name: tbl_horizons horizon_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_horizons ALTER COLUMN horizon_id SET DEFAULT nextval('tbl_horizons_horizon_id_seq'::regclass);


--
-- Name: tbl_identification_levels identification_level_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_identification_levels ALTER COLUMN identification_level_id SET DEFAULT nextval('tbl_identification_levels_identification_level_id_seq'::regclass);


--
-- Name: tbl_image_types image_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_image_types ALTER COLUMN image_type_id SET DEFAULT nextval('tbl_image_types_image_type_id_seq'::regclass);


--
-- Name: tbl_imported_taxa_replacements imported_taxa_replacement_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_imported_taxa_replacements ALTER COLUMN imported_taxa_replacement_id SET DEFAULT nextval('tbl_imported_taxa_replacements_imported_taxa_replacement_id_seq'::regclass);


--
-- Name: tbl_keywords keyword_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_keywords ALTER COLUMN keyword_id SET DEFAULT nextval('tbl_keywords_keyword_id_seq'::regclass);


--
-- Name: tbl_languages language_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_languages ALTER COLUMN language_id SET DEFAULT nextval('tbl_languages_language_id_seq'::regclass);


--
-- Name: tbl_lithology lithology_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_lithology ALTER COLUMN lithology_id SET DEFAULT nextval('tbl_lithology_lithology_id_seq'::regclass);


--
-- Name: tbl_location_types location_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_location_types ALTER COLUMN location_type_id SET DEFAULT nextval('tbl_location_types_location_type_id_seq'::regclass);


--
-- Name: tbl_locations location_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_locations ALTER COLUMN location_id SET DEFAULT nextval('tbl_locations_location_id_seq'::regclass);


--
-- Name: tbl_mcr_names taxon_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_mcr_names ALTER COLUMN taxon_id SET DEFAULT nextval('tbl_mcr_names_taxon_id_seq'::regclass);


--
-- Name: tbl_mcr_summary_data mcr_summary_data_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_mcr_summary_data ALTER COLUMN mcr_summary_data_id SET DEFAULT nextval('tbl_mcr_summary_data_mcr_summary_data_id_seq'::regclass);


--
-- Name: tbl_mcrdata_birmbeetledat mcrdata_birmbeetledat_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_mcrdata_birmbeetledat ALTER COLUMN mcrdata_birmbeetledat_id SET DEFAULT nextval('tbl_mcrdata_birmbeetledat_mcrdata_birmbeetledat_id_seq'::regclass);


--
-- Name: tbl_measured_value_dimensions measured_value_dimension_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_measured_value_dimensions ALTER COLUMN measured_value_dimension_id SET DEFAULT nextval('tbl_measured_value_dimensions_measured_value_dimension_id_seq'::regclass);


--
-- Name: tbl_measured_values measured_value_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_measured_values ALTER COLUMN measured_value_id SET DEFAULT nextval('tbl_measured_values_measured_value_id_seq'::regclass);


--
-- Name: tbl_method_groups method_group_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_method_groups ALTER COLUMN method_group_id SET DEFAULT nextval('tbl_method_groups_method_group_id_seq'::regclass);


--
-- Name: tbl_methods method_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_methods ALTER COLUMN method_id SET DEFAULT nextval('tbl_methods_method_id_seq'::regclass);


--
-- Name: tbl_modification_types modification_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_modification_types ALTER COLUMN modification_type_id SET DEFAULT nextval('tbl_modification_types_modification_type_id_seq'::regclass);


--
-- Name: tbl_physical_sample_features physical_sample_feature_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_physical_sample_features ALTER COLUMN physical_sample_feature_id SET DEFAULT nextval('tbl_physical_sample_features_physical_sample_feature_id_seq'::regclass);


--
-- Name: tbl_physical_samples physical_sample_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_physical_samples ALTER COLUMN physical_sample_id SET DEFAULT nextval('tbl_physical_samples_physical_sample_id_seq'::regclass);


--
-- Name: tbl_project_stages project_stage_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_project_stages ALTER COLUMN project_stage_id SET DEFAULT nextval('tbl_project_stage_project_stage_id_seq'::regclass);


--
-- Name: tbl_project_types project_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_project_types ALTER COLUMN project_type_id SET DEFAULT nextval('tbl_project_types_project_type_id_seq'::regclass);


--
-- Name: tbl_projects project_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_projects ALTER COLUMN project_id SET DEFAULT nextval('tbl_projects_project_id_seq'::regclass);


--
-- Name: tbl_publication_types publication_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_publication_types ALTER COLUMN publication_type_id SET DEFAULT nextval('tbl_publication_types_publication_type_id_seq'::regclass);


--
-- Name: tbl_publishers publisher_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_publishers ALTER COLUMN publisher_id SET DEFAULT nextval('tbl_publishers_publisher_id_seq'::regclass);


--
-- Name: tbl_radiocarbon_calibration radiocarbon_calibration_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_radiocarbon_calibration ALTER COLUMN radiocarbon_calibration_id SET DEFAULT nextval('tbl_radiocarbon_calibration_radiocarbon_calibration_id_seq'::regclass);


--
-- Name: tbl_rdb rdb_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_rdb ALTER COLUMN rdb_id SET DEFAULT nextval('tbl_rdb_rdb_id_seq'::regclass);


--
-- Name: tbl_rdb_codes rdb_code_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_rdb_codes ALTER COLUMN rdb_code_id SET DEFAULT nextval('tbl_rdb_codes_rdb_code_id_seq'::regclass);


--
-- Name: tbl_rdb_systems rdb_system_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_rdb_systems ALTER COLUMN rdb_system_id SET DEFAULT nextval('tbl_rdb_systems_rdb_system_id_seq'::regclass);


--
-- Name: tbl_record_types record_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_record_types ALTER COLUMN record_type_id SET DEFAULT nextval('tbl_record_types_record_type_id_seq'::regclass);


--
-- Name: tbl_relative_age_refs relative_age_ref_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_relative_age_refs ALTER COLUMN relative_age_ref_id SET DEFAULT nextval('tbl_relative_age_refs_relative_age_ref_id_seq'::regclass);


--
-- Name: tbl_relative_age_types relative_age_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_relative_age_types ALTER COLUMN relative_age_type_id SET DEFAULT nextval('tbl_relative_age_types_relative_age_type_id_seq'::regclass);


--
-- Name: tbl_relative_ages relative_age_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_relative_ages ALTER COLUMN relative_age_id SET DEFAULT nextval('tbl_relative_ages_relative_age_id_seq'::regclass);


--
-- Name: tbl_relative_dates relative_date_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_relative_dates ALTER COLUMN relative_date_id SET DEFAULT nextval('tbl_relative_dates_relative_date_id_seq'::regclass);


--
-- Name: tbl_sample_alt_refs sample_alt_ref_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_alt_refs ALTER COLUMN sample_alt_ref_id SET DEFAULT nextval('tbl_sample_alt_refs_sample_alt_ref_id_seq'::regclass);


--
-- Name: tbl_sample_colours sample_colour_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_colours ALTER COLUMN sample_colour_id SET DEFAULT nextval('tbl_sample_colours_sample_colour_id_seq'::regclass);


--
-- Name: tbl_sample_coordinates sample_coordinate_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_coordinates ALTER COLUMN sample_coordinate_id SET DEFAULT nextval('tbl_sample_coordinates_sample_coordinates_id_seq'::regclass);


--
-- Name: tbl_sample_description_sample_group_contexts sample_description_sample_group_context_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_description_sample_group_contexts ALTER COLUMN sample_description_sample_group_context_id SET DEFAULT nextval('tbl_sample_description_sample_sample_description_sample_gro_seq'::regclass);


--
-- Name: tbl_sample_description_types sample_description_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_description_types ALTER COLUMN sample_description_type_id SET DEFAULT nextval('tbl_sample_description_types_sample_description_type_id_seq'::regclass);


--
-- Name: tbl_sample_descriptions sample_description_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_descriptions ALTER COLUMN sample_description_id SET DEFAULT nextval('tbl_sample_descriptions_sample_description_id_seq'::regclass);


--
-- Name: tbl_sample_dimensions sample_dimension_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_dimensions ALTER COLUMN sample_dimension_id SET DEFAULT nextval('tbl_sample_dimensions_sample_dimension_id_seq'::regclass);


--
-- Name: tbl_sample_group_coordinates sample_group_position_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_coordinates ALTER COLUMN sample_group_position_id SET DEFAULT nextval('tbl_sample_group_coordinates_sample_group_position_id_seq'::regclass);


--
-- Name: tbl_sample_group_description_type_sampling_contexts sample_group_description_type_sampling_context_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_description_type_sampling_contexts ALTER COLUMN sample_group_description_type_sampling_context_id SET DEFAULT nextval('tbl_sample_group_description__sample_group_desciption_sampl_seq'::regclass);


--
-- Name: tbl_sample_group_description_types sample_group_description_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_description_types ALTER COLUMN sample_group_description_type_id SET DEFAULT nextval('tbl_sample_group_description__sample_group_description_type_seq'::regclass);


--
-- Name: tbl_sample_group_descriptions sample_group_description_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_descriptions ALTER COLUMN sample_group_description_id SET DEFAULT nextval('tbl_sample_group_descriptions_sample_group_description_id_seq'::regclass);


--
-- Name: tbl_sample_group_dimensions sample_group_dimension_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_dimensions ALTER COLUMN sample_group_dimension_id SET DEFAULT nextval('tbl_sample_group_dimensions_sample_group_dimension_id_seq'::regclass);


--
-- Name: tbl_sample_group_images sample_group_image_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_images ALTER COLUMN sample_group_image_id SET DEFAULT nextval('tbl_sample_group_images_sample_group_image_id_seq'::regclass);


--
-- Name: tbl_sample_group_notes sample_group_note_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_notes ALTER COLUMN sample_group_note_id SET DEFAULT nextval('tbl_sample_group_notes_sample_group_note_id_seq'::regclass);


--
-- Name: tbl_sample_group_references sample_group_reference_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_references ALTER COLUMN sample_group_reference_id SET DEFAULT nextval('tbl_sample_group_references_sample_group_reference_id_seq'::regclass);


--
-- Name: tbl_sample_group_sampling_contexts sampling_context_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_sampling_contexts ALTER COLUMN sampling_context_id SET DEFAULT nextval('tbl_sample_group_sampling_contexts_sampling_context_id_seq'::regclass);


--
-- Name: tbl_sample_groups sample_group_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_groups ALTER COLUMN sample_group_id SET DEFAULT nextval('tbl_sample_groups_sample_group_id_seq'::regclass);


--
-- Name: tbl_sample_horizons sample_horizon_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_horizons ALTER COLUMN sample_horizon_id SET DEFAULT nextval('tbl_sample_horizons_sample_horizon_id_seq'::regclass);


--
-- Name: tbl_sample_images sample_image_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_images ALTER COLUMN sample_image_id SET DEFAULT nextval('tbl_sample_images_sample_image_id_seq'::regclass);


--
-- Name: tbl_sample_location_type_sampling_contexts sample_location_type_sampling_context_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_location_type_sampling_contexts ALTER COLUMN sample_location_type_sampling_context_id SET DEFAULT nextval('tbl_sample_location_sampling__sample_location_type_sampling_seq'::regclass);


--
-- Name: tbl_sample_location_type_sampling_contexts sample_location_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_location_type_sampling_contexts ALTER COLUMN sample_location_type_id SET DEFAULT nextval('tbl_sample_location_sampling_contex_sample_location_type_id_seq'::regclass);


--
-- Name: tbl_sample_location_types sample_location_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_location_types ALTER COLUMN sample_location_type_id SET DEFAULT nextval('tbl_sample_location_types_sample_location_type_id_seq'::regclass);


--
-- Name: tbl_sample_locations sample_location_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_locations ALTER COLUMN sample_location_id SET DEFAULT nextval('tbl_sample_locations_sample_location_id_seq'::regclass);


--
-- Name: tbl_sample_notes sample_note_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_notes ALTER COLUMN sample_note_id SET DEFAULT nextval('tbl_sample_notes_sample_note_id_seq'::regclass);


--
-- Name: tbl_sample_types sample_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_types ALTER COLUMN sample_type_id SET DEFAULT nextval('tbl_sample_types_sample_type_id_seq'::regclass);


--
-- Name: tbl_season_types season_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_season_types ALTER COLUMN season_type_id SET DEFAULT nextval('tbl_season_types_season_type_id_seq'::regclass);


--
-- Name: tbl_seasons season_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_seasons ALTER COLUMN season_id SET DEFAULT nextval('tbl_seasons_season_id_seq'::regclass);


--
-- Name: tbl_site_images site_image_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_images ALTER COLUMN site_image_id SET DEFAULT nextval('tbl_site_images_site_image_id_seq'::regclass);


--
-- Name: tbl_site_locations site_location_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_locations ALTER COLUMN site_location_id SET DEFAULT nextval('tbl_site_locations_site_location_id_seq'::regclass);


--
-- Name: tbl_site_natgridrefs site_natgridref_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_natgridrefs ALTER COLUMN site_natgridref_id SET DEFAULT nextval('tbl_site_natgridrefs_site_natgridref_id_seq'::regclass);


--
-- Name: tbl_site_other_records site_other_records_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_other_records ALTER COLUMN site_other_records_id SET DEFAULT nextval('tbl_site_other_records_site_other_records_id_seq'::regclass);


--
-- Name: tbl_site_preservation_status site_preservation_status_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_preservation_status ALTER COLUMN site_preservation_status_id SET DEFAULT nextval('tbl_site_preservation_status_site_preservation_status_id_seq'::regclass);


--
-- Name: tbl_site_references site_reference_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_references ALTER COLUMN site_reference_id SET DEFAULT nextval('tbl_site_references_site_reference_id_seq'::regclass);


--
-- Name: tbl_sites site_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sites ALTER COLUMN site_id SET DEFAULT nextval('tbl_sites_site_id_seq'::regclass);


--
-- Name: tbl_species_association_types association_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_species_association_types ALTER COLUMN association_type_id SET DEFAULT nextval('tbl_association_types_association_type_id_seq'::regclass);


--
-- Name: tbl_species_associations species_association_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_species_associations ALTER COLUMN species_association_id SET DEFAULT nextval('tbl_species_associations_species_association_id_seq'::regclass);


--
-- Name: tbl_taxa_common_names taxon_common_name_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_common_names ALTER COLUMN taxon_common_name_id SET DEFAULT nextval('tbl_taxa_common_names_taxon_common_name_id_seq'::regclass);


--
-- Name: tbl_taxa_images taxa_images_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_images ALTER COLUMN taxa_images_id SET DEFAULT nextval('tbl_taxa_images_taxa_images_id_seq'::regclass);


--
-- Name: tbl_taxa_measured_attributes measured_attribute_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_measured_attributes ALTER COLUMN measured_attribute_id SET DEFAULT nextval('tbl_taxa_measured_attributes_measured_attribute_id_seq'::regclass);


--
-- Name: tbl_taxa_reference_specimens taxa_reference_specimen_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_reference_specimens ALTER COLUMN taxa_reference_specimen_id SET DEFAULT nextval('tbl_taxa_reference_specimens_taxa_reference_specimen_id_seq'::regclass);


--
-- Name: tbl_taxa_seasonality seasonality_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_seasonality ALTER COLUMN seasonality_id SET DEFAULT nextval('tbl_taxa_seasonality_seasonality_id_seq'::regclass);


--
-- Name: tbl_taxa_synonyms synonym_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_synonyms ALTER COLUMN synonym_id SET DEFAULT nextval('tbl_taxa_synonyms_synonym_id_seq'::regclass);


--
-- Name: tbl_taxa_tree_authors author_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_tree_authors ALTER COLUMN author_id SET DEFAULT nextval('tbl_taxa_tree_authors_author_id_seq'::regclass);


--
-- Name: tbl_taxa_tree_families family_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_tree_families ALTER COLUMN family_id SET DEFAULT nextval('tbl_taxa_tree_families_family_id_seq'::regclass);


--
-- Name: tbl_taxa_tree_genera genus_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_tree_genera ALTER COLUMN genus_id SET DEFAULT nextval('tbl_taxa_tree_genera_genus_id_seq'::regclass);


--
-- Name: tbl_taxa_tree_master taxon_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_tree_master ALTER COLUMN taxon_id SET DEFAULT nextval('tbl_taxa_tree_master_taxon_id_seq'::regclass);


--
-- Name: tbl_taxa_tree_orders order_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_tree_orders ALTER COLUMN order_id SET DEFAULT nextval('tbl_taxa_tree_orders_order_id_seq'::regclass);


--
-- Name: tbl_taxonomic_order taxonomic_order_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxonomic_order ALTER COLUMN taxonomic_order_id SET DEFAULT nextval('tbl_taxonomic_order_taxonomic_order_id_seq'::regclass);


--
-- Name: tbl_taxonomic_order_biblio taxonomic_order_biblio_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxonomic_order_biblio ALTER COLUMN taxonomic_order_biblio_id SET DEFAULT nextval('tbl_taxonomic_order_biblio_taxonomic_order_biblio_id_seq'::regclass);


--
-- Name: tbl_taxonomic_order_systems taxonomic_order_system_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxonomic_order_systems ALTER COLUMN taxonomic_order_system_id SET DEFAULT nextval('tbl_taxonomic_order_systems_taxonomic_order_system_id_seq'::regclass);


--
-- Name: tbl_taxonomy_notes taxonomy_notes_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxonomy_notes ALTER COLUMN taxonomy_notes_id SET DEFAULT nextval('tbl_taxonomy_notes_taxonomy_notes_id_seq'::regclass);


--
-- Name: tbl_tephra_dates tephra_date_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_tephra_dates ALTER COLUMN tephra_date_id SET DEFAULT nextval('tbl_tephra_dates_tephra_date_id_seq'::regclass);


--
-- Name: tbl_tephra_refs tephra_ref_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_tephra_refs ALTER COLUMN tephra_ref_id SET DEFAULT nextval('tbl_tephra_refs_tephra_ref_id_seq'::regclass);


--
-- Name: tbl_tephras tephra_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_tephras ALTER COLUMN tephra_id SET DEFAULT nextval('tbl_tephras_tephra_id_seq'::regclass);


--
-- Name: tbl_text_biology biology_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_text_biology ALTER COLUMN biology_id SET DEFAULT nextval('tbl_text_biology_biology_id_seq'::regclass);


--
-- Name: tbl_text_distribution distribution_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_text_distribution ALTER COLUMN distribution_id SET DEFAULT nextval('tbl_text_distribution_distribution_id_seq'::regclass);


--
-- Name: tbl_text_identification_keys key_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_text_identification_keys ALTER COLUMN key_id SET DEFAULT nextval('tbl_text_identification_keys_key_id_seq'::regclass);


--
-- Name: tbl_units unit_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_units ALTER COLUMN unit_id SET DEFAULT nextval('tbl_units_unit_id_seq'::regclass);


--
-- Name: tbl_years_types years_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_years_types ALTER COLUMN years_type_id SET DEFAULT nextval('tbl_years_types_years_type_id_seq'::regclass);


SET search_path = clearing_house, pg_catalog;

--
-- Name: tbl_clearinghouse_activity_log pk_activity_log_id; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_activity_log
    ADD CONSTRAINT pk_activity_log_id PRIMARY KEY (activity_log_id);


--
-- Name: tbl_clearinghouse_signals pk_clearinghouse_signals_signal_id; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_signals
    ADD CONSTRAINT pk_clearinghouse_signals_signal_id PRIMARY KEY (signal_id);


--
-- Name: tbl_clearinghouse_data_provider_grades pk_grade_id; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_data_provider_grades
    ADD CONSTRAINT pk_grade_id PRIMARY KEY (grade_id);


--
-- Name: tbl_clearinghouse_user_roles pk_role_id; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_user_roles
    ADD CONSTRAINT pk_role_id PRIMARY KEY (role_id);


--
-- Name: tbl_clearinghouse_signal_log pk_signal_log_id; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_signal_log
    ADD CONSTRAINT pk_signal_log_id PRIMARY KEY (signal_log_id);


--
-- Name: tbl_clearinghouse_submissions pk_submission_id; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submissions
    ADD CONSTRAINT pk_submission_id PRIMARY KEY (submission_id);


--
-- Name: tbl_clearinghouse_submission_states pk_submission_state_id; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submission_states
    ADD CONSTRAINT pk_submission_state_id PRIMARY KEY (submission_state_id);


--
-- Name: tbl_abundance_elements pk_tbl_abundance_elements; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_abundance_elements
    ADD CONSTRAINT pk_tbl_abundance_elements PRIMARY KEY (submission_id, source_id, abundance_element_id);


--
-- Name: tbl_abundance_ident_levels pk_tbl_abundance_ident_levels; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_abundance_ident_levels
    ADD CONSTRAINT pk_tbl_abundance_ident_levels PRIMARY KEY (submission_id, source_id, abundance_ident_level_id);


--
-- Name: tbl_abundance_modifications pk_tbl_abundance_modifications; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_abundance_modifications
    ADD CONSTRAINT pk_tbl_abundance_modifications PRIMARY KEY (submission_id, source_id, abundance_modification_id);


--
-- Name: tbl_abundances pk_tbl_abundances; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_abundances
    ADD CONSTRAINT pk_tbl_abundances PRIMARY KEY (submission_id, source_id, abundance_id);


--
-- Name: tbl_activity_types pk_tbl_activity_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_activity_types
    ADD CONSTRAINT pk_tbl_activity_types PRIMARY KEY (submission_id, source_id, activity_type_id);


--
-- Name: tbl_aggregate_datasets pk_tbl_aggregate_datasets; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_aggregate_datasets
    ADD CONSTRAINT pk_tbl_aggregate_datasets PRIMARY KEY (submission_id, source_id, aggregate_dataset_id);


--
-- Name: tbl_aggregate_order_types pk_tbl_aggregate_order_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_aggregate_order_types
    ADD CONSTRAINT pk_tbl_aggregate_order_types PRIMARY KEY (submission_id, source_id, aggregate_order_type_id);


--
-- Name: tbl_aggregate_sample_ages pk_tbl_aggregate_sample_ages; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_aggregate_sample_ages
    ADD CONSTRAINT pk_tbl_aggregate_sample_ages PRIMARY KEY (submission_id, source_id, aggregate_sample_age_id);


--
-- Name: tbl_aggregate_samples pk_tbl_aggregate_samples; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_aggregate_samples
    ADD CONSTRAINT pk_tbl_aggregate_samples PRIMARY KEY (submission_id, source_id, aggregate_sample_id);


--
-- Name: tbl_alt_ref_types pk_tbl_alt_ref_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_alt_ref_types
    ADD CONSTRAINT pk_tbl_alt_ref_types PRIMARY KEY (submission_id, source_id, alt_ref_type_id);


--
-- Name: tbl_analysis_entities pk_tbl_analysis_entities; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_analysis_entities
    ADD CONSTRAINT pk_tbl_analysis_entities PRIMARY KEY (submission_id, source_id, analysis_entity_id);


--
-- Name: tbl_analysis_entity_ages pk_tbl_analysis_entity_ages; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_analysis_entity_ages
    ADD CONSTRAINT pk_tbl_analysis_entity_ages PRIMARY KEY (submission_id, source_id, analysis_entity_age_id);


--
-- Name: tbl_analysis_entity_dimensions pk_tbl_analysis_entity_dimensions; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_analysis_entity_dimensions
    ADD CONSTRAINT pk_tbl_analysis_entity_dimensions PRIMARY KEY (submission_id, source_id, analysis_entity_dimension_id);


--
-- Name: tbl_analysis_entity_prep_methods pk_tbl_analysis_entity_prep_methods; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_analysis_entity_prep_methods
    ADD CONSTRAINT pk_tbl_analysis_entity_prep_methods PRIMARY KEY (submission_id, source_id, analysis_entity_prep_method_id);


--
-- Name: tbl_biblio pk_tbl_biblio; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_biblio
    ADD CONSTRAINT pk_tbl_biblio PRIMARY KEY (submission_id, source_id, biblio_id);


--
-- Name: tbl_biblio_keywords pk_tbl_biblio_keywords; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_biblio_keywords
    ADD CONSTRAINT pk_tbl_biblio_keywords PRIMARY KEY (submission_id, source_id, biblio_keyword_id);


--
-- Name: tbl_bugs_abundance_codes pk_tbl_bugs_abundance_codes; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_bugs_abundance_codes
    ADD CONSTRAINT pk_tbl_bugs_abundance_codes PRIMARY KEY (submission_id, source_id, bugs_abundance_code_id);


--
-- Name: tbl_bugs_biblio pk_tbl_bugs_biblio; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_bugs_biblio
    ADD CONSTRAINT pk_tbl_bugs_biblio PRIMARY KEY (submission_id, source_id, bugs_biblio_id);


--
-- Name: tbl_bugs_dates_calendar pk_tbl_bugs_dates_calendar; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_bugs_dates_calendar
    ADD CONSTRAINT pk_tbl_bugs_dates_calendar PRIMARY KEY (submission_id, source_id, bugs_dates_calendar_id);


--
-- Name: tbl_bugs_dates_period pk_tbl_bugs_dates_period; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_bugs_dates_period
    ADD CONSTRAINT pk_tbl_bugs_dates_period PRIMARY KEY (submission_id, source_id, bugs_dates_period_id);


--
-- Name: tbl_bugs_dates_radio pk_tbl_bugs_dates_radio; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_bugs_dates_radio
    ADD CONSTRAINT pk_tbl_bugs_dates_radio PRIMARY KEY (submission_id, source_id, bugs_dates_radio_id);


--
-- Name: tbl_bugs_datesmethods pk_tbl_bugs_datesmethods; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_bugs_datesmethods
    ADD CONSTRAINT pk_tbl_bugs_datesmethods PRIMARY KEY (submission_id, source_id, bugs_datesmethods_id);


--
-- Name: tbl_bugs_periods pk_tbl_bugs_periods; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_bugs_periods
    ADD CONSTRAINT pk_tbl_bugs_periods PRIMARY KEY (submission_id, source_id, bugs_dates_relative_id);


--
-- Name: tbl_bugs_physical_samples pk_tbl_bugs_physical_samples; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_bugs_physical_samples
    ADD CONSTRAINT pk_tbl_bugs_physical_samples PRIMARY KEY (submission_id, source_id, bugs_physical_sample_id);


--
-- Name: tbl_bugs_sample_groups pk_tbl_bugs_sample_groups; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_bugs_sample_groups
    ADD CONSTRAINT pk_tbl_bugs_sample_groups PRIMARY KEY (submission_id, source_id, bugs_sample_group_id);


--
-- Name: tbl_bugs_sites pk_tbl_bugs_sites; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_bugs_sites
    ADD CONSTRAINT pk_tbl_bugs_sites PRIMARY KEY (submission_id, source_id, bugs_sites_id);


--
-- Name: tbl_ceramics pk_tbl_ceramics; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_ceramics
    ADD CONSTRAINT pk_tbl_ceramics PRIMARY KEY (submission_id, source_id, ceramics_id);


--
-- Name: tbl_ceramics_measurement_lookup pk_tbl_ceramics_measurement_lookup; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_ceramics_measurement_lookup
    ADD CONSTRAINT pk_tbl_ceramics_measurement_lookup PRIMARY KEY (submission_id, source_id, ceramics_measurement_lookup_id);


--
-- Name: tbl_ceramics_measurements pk_tbl_ceramics_measurements; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_ceramics_measurements
    ADD CONSTRAINT pk_tbl_ceramics_measurements PRIMARY KEY (submission_id, source_id, ceramics_measurement_id);


--
-- Name: tbl_chron_control_types pk_tbl_chron_control_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_chron_control_types
    ADD CONSTRAINT pk_tbl_chron_control_types PRIMARY KEY (submission_id, source_id, chron_control_type_id);


--
-- Name: tbl_chron_controls pk_tbl_chron_controls; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_chron_controls
    ADD CONSTRAINT pk_tbl_chron_controls PRIMARY KEY (submission_id, source_id, chron_control_id);


--
-- Name: tbl_chronologies pk_tbl_chronologies; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_chronologies
    ADD CONSTRAINT pk_tbl_chronologies PRIMARY KEY (submission_id, source_id, chronology_id);


--
-- Name: tbl_clearinghouse_accepted_submissions pk_tbl_clearinghouse_accepted_submissions; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_accepted_submissions
    ADD CONSTRAINT pk_tbl_clearinghouse_accepted_submissions PRIMARY KEY (accepted_submission_id);


--
-- Name: tbl_clearinghouse_info_references pk_tbl_clearinghouse_info_references; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_info_references
    ADD CONSTRAINT pk_tbl_clearinghouse_info_references PRIMARY KEY (info_reference_id);


--
-- Name: tbl_clearinghouse_reject_entity_types pk_tbl_clearinghouse_reject_entity_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_reject_entity_types
    ADD CONSTRAINT pk_tbl_clearinghouse_reject_entity_types PRIMARY KEY (entity_type_id);


--
-- Name: tbl_clearinghouse_reports pk_tbl_clearinghouse_reports; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_reports
    ADD CONSTRAINT pk_tbl_clearinghouse_reports PRIMARY KEY (report_id);


--
-- Name: tbl_clearinghouse_sessions pk_tbl_clearinghouse_sessions_session_id; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_sessions
    ADD CONSTRAINT pk_tbl_clearinghouse_sessions_session_id PRIMARY KEY (session_id);


--
-- Name: tbl_clearinghouse_settings pk_tbl_clearinghouse_settings; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_settings
    ADD CONSTRAINT pk_tbl_clearinghouse_settings PRIMARY KEY (setting_id);


--
-- Name: tbl_clearinghouse_submission_reject_entities pk_tbl_clearinghouse_submission_reject_entities; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submission_reject_entities
    ADD CONSTRAINT pk_tbl_clearinghouse_submission_reject_entities PRIMARY KEY (reject_entity_id);


--
-- Name: tbl_clearinghouse_submission_rejects pk_tbl_clearinghouse_submission_rejects; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submission_rejects
    ADD CONSTRAINT pk_tbl_clearinghouse_submission_rejects PRIMARY KEY (submission_reject_id);


--
-- Name: tbl_clearinghouse_submission_tables pk_tbl_clearinghouse_submission_tables; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submission_tables
    ADD CONSTRAINT pk_tbl_clearinghouse_submission_tables PRIMARY KEY (table_id);


--
-- Name: tbl_clearinghouse_use_cases pk_tbl_clearinghouse_use_cases; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_use_cases
    ADD CONSTRAINT pk_tbl_clearinghouse_use_cases PRIMARY KEY (use_case_id);


--
-- Name: tbl_collections_or_journals pk_tbl_collections_or_journals; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_collections_or_journals
    ADD CONSTRAINT pk_tbl_collections_or_journals PRIMARY KEY (submission_id, source_id, collection_or_journal_id);


--
-- Name: tbl_colours pk_tbl_colours; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_colours
    ADD CONSTRAINT pk_tbl_colours PRIMARY KEY (submission_id, source_id, colour_id);


--
-- Name: tbl_contact_types pk_tbl_contact_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_contact_types
    ADD CONSTRAINT pk_tbl_contact_types PRIMARY KEY (submission_id, source_id, contact_type_id);


--
-- Name: tbl_contacts pk_tbl_contacts; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_contacts
    ADD CONSTRAINT pk_tbl_contacts PRIMARY KEY (submission_id, source_id, contact_id);


--
-- Name: tbl_coordinate_method_dimensions pk_tbl_coordinate_method_dimensions; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_coordinate_method_dimensions
    ADD CONSTRAINT pk_tbl_coordinate_method_dimensions PRIMARY KEY (submission_id, source_id, coordinate_method_dimension_id);


--
-- Name: tbl_data_type_groups pk_tbl_data_type_groups; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_data_type_groups
    ADD CONSTRAINT pk_tbl_data_type_groups PRIMARY KEY (submission_id, source_id, data_type_group_id);


--
-- Name: tbl_data_types pk_tbl_data_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_data_types
    ADD CONSTRAINT pk_tbl_data_types PRIMARY KEY (submission_id, source_id, data_type_id);


--
-- Name: tbl_dataset_contacts pk_tbl_dataset_contacts; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_dataset_contacts
    ADD CONSTRAINT pk_tbl_dataset_contacts PRIMARY KEY (submission_id, source_id, dataset_contact_id);


--
-- Name: tbl_dataset_masters pk_tbl_dataset_masters; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_dataset_masters
    ADD CONSTRAINT pk_tbl_dataset_masters PRIMARY KEY (submission_id, source_id, master_set_id);


--
-- Name: tbl_dataset_submission_types pk_tbl_dataset_submission_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_dataset_submission_types
    ADD CONSTRAINT pk_tbl_dataset_submission_types PRIMARY KEY (submission_id, source_id, submission_type_id);


--
-- Name: tbl_dataset_submissions pk_tbl_dataset_submissions; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_dataset_submissions
    ADD CONSTRAINT pk_tbl_dataset_submissions PRIMARY KEY (submission_id, source_id, dataset_submission_id);


--
-- Name: tbl_datasets pk_tbl_datasets; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_datasets
    ADD CONSTRAINT pk_tbl_datasets PRIMARY KEY (submission_id, source_id, dataset_id);


--
-- Name: tbl_dating_labs pk_tbl_dating_labs; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_dating_labs
    ADD CONSTRAINT pk_tbl_dating_labs PRIMARY KEY (submission_id, source_id, dating_lab_id);


--
-- Name: tbl_dating_material pk_tbl_dating_material; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_dating_material
    ADD CONSTRAINT pk_tbl_dating_material PRIMARY KEY (submission_id, source_id, dating_material_id);


--
-- Name: tbl_dating_uncertainty pk_tbl_dating_uncertainty; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_dating_uncertainty
    ADD CONSTRAINT pk_tbl_dating_uncertainty PRIMARY KEY (submission_id, source_id, dating_uncertainty_id);


--
-- Name: tbl_dendro pk_tbl_dendro; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_dendro
    ADD CONSTRAINT pk_tbl_dendro PRIMARY KEY (submission_id, source_id, dendro_id);


--
-- Name: tbl_dendro_date_notes pk_tbl_dendro_date_notes; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_dendro_date_notes
    ADD CONSTRAINT pk_tbl_dendro_date_notes PRIMARY KEY (submission_id, source_id, dendro_date_note_id);


--
-- Name: tbl_dendro_dates pk_tbl_dendro_dates; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_dendro_dates
    ADD CONSTRAINT pk_tbl_dendro_dates PRIMARY KEY (submission_id, source_id, dendro_date_id);


--
-- Name: tbl_dendro_measurement_lookup pk_tbl_dendro_measurement_lookup; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_dendro_measurement_lookup
    ADD CONSTRAINT pk_tbl_dendro_measurement_lookup PRIMARY KEY (submission_id, source_id, dendro_measurement_lookup_id);


--
-- Name: tbl_dendro_measurements pk_tbl_dendro_measurements; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_dendro_measurements
    ADD CONSTRAINT pk_tbl_dendro_measurements PRIMARY KEY (submission_id, source_id, dendro_measurement_id);


--
-- Name: tbl_dimensions pk_tbl_dimensions; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_dimensions
    ADD CONSTRAINT pk_tbl_dimensions PRIMARY KEY (submission_id, source_id, dimension_id);


--
-- Name: tbl_ecocode_definitions pk_tbl_ecocode_definitions; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_ecocode_definitions
    ADD CONSTRAINT pk_tbl_ecocode_definitions PRIMARY KEY (submission_id, source_id, ecocode_definition_id);


--
-- Name: tbl_ecocode_groups pk_tbl_ecocode_groups; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_ecocode_groups
    ADD CONSTRAINT pk_tbl_ecocode_groups PRIMARY KEY (submission_id, source_id, ecocode_group_id);


--
-- Name: tbl_ecocode_systems pk_tbl_ecocode_systems; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_ecocode_systems
    ADD CONSTRAINT pk_tbl_ecocode_systems PRIMARY KEY (submission_id, source_id, ecocode_system_id);


--
-- Name: tbl_ecocodes pk_tbl_ecocodes; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_ecocodes
    ADD CONSTRAINT pk_tbl_ecocodes PRIMARY KEY (submission_id, source_id, ecocode_id);


--
-- Name: tbl_feature_types pk_tbl_feature_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_feature_types
    ADD CONSTRAINT pk_tbl_feature_types PRIMARY KEY (submission_id, source_id, feature_type_id);


--
-- Name: tbl_features pk_tbl_features; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_features
    ADD CONSTRAINT pk_tbl_features PRIMARY KEY (submission_id, source_id, feature_id);


--
-- Name: tbl_foreign_relations pk_tbl_foreign_relations; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_foreign_relations
    ADD CONSTRAINT pk_tbl_foreign_relations PRIMARY KEY (submission_id, source_id, source_table, source_column, target_table, target_column);


--
-- Name: tbl_geochron_refs pk_tbl_geochron_refs; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_geochron_refs
    ADD CONSTRAINT pk_tbl_geochron_refs PRIMARY KEY (submission_id, source_id, geochron_ref_id);


--
-- Name: tbl_geochronology pk_tbl_geochronology; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_geochronology
    ADD CONSTRAINT pk_tbl_geochronology PRIMARY KEY (submission_id, source_id, geochron_id);


--
-- Name: tbl_horizons pk_tbl_horizons; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_horizons
    ADD CONSTRAINT pk_tbl_horizons PRIMARY KEY (submission_id, source_id, horizon_id);


--
-- Name: tbl_identification_levels pk_tbl_identification_levels; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_identification_levels
    ADD CONSTRAINT pk_tbl_identification_levels PRIMARY KEY (submission_id, source_id, identification_level_id);


--
-- Name: tbl_image_types pk_tbl_image_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_image_types
    ADD CONSTRAINT pk_tbl_image_types PRIMARY KEY (submission_id, source_id, image_type_id);


--
-- Name: tbl_imported_taxa_replacements pk_tbl_imported_taxa_replacements; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_imported_taxa_replacements
    ADD CONSTRAINT pk_tbl_imported_taxa_replacements PRIMARY KEY (submission_id, source_id, imported_taxa_replacement_id);


--
-- Name: tbl_keywords pk_tbl_keywords; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_keywords
    ADD CONSTRAINT pk_tbl_keywords PRIMARY KEY (submission_id, source_id, keyword_id);


--
-- Name: tbl_languages pk_tbl_languages; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_languages
    ADD CONSTRAINT pk_tbl_languages PRIMARY KEY (submission_id, source_id, language_id);


--
-- Name: tbl_lithology pk_tbl_lithology; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_lithology
    ADD CONSTRAINT pk_tbl_lithology PRIMARY KEY (submission_id, source_id, lithology_id);


--
-- Name: tbl_location_types pk_tbl_location_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_location_types
    ADD CONSTRAINT pk_tbl_location_types PRIMARY KEY (submission_id, source_id, location_type_id);


--
-- Name: tbl_locations pk_tbl_locations; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_locations
    ADD CONSTRAINT pk_tbl_locations PRIMARY KEY (submission_id, source_id, location_id);


--
-- Name: tbl_mcr_names pk_tbl_mcr_names; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_mcr_names
    ADD CONSTRAINT pk_tbl_mcr_names PRIMARY KEY (submission_id, source_id, taxon_id);


--
-- Name: tbl_mcr_summary_data pk_tbl_mcr_summary_data; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_mcr_summary_data
    ADD CONSTRAINT pk_tbl_mcr_summary_data PRIMARY KEY (submission_id, source_id, mcr_summary_data_id);


--
-- Name: tbl_mcrdata_birmbeetledat pk_tbl_mcrdata_birmbeetledat; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_mcrdata_birmbeetledat
    ADD CONSTRAINT pk_tbl_mcrdata_birmbeetledat PRIMARY KEY (submission_id, source_id, mcrdata_birmbeetledat_id);


--
-- Name: tbl_measured_value_dimensions pk_tbl_measured_value_dimensions; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_measured_value_dimensions
    ADD CONSTRAINT pk_tbl_measured_value_dimensions PRIMARY KEY (submission_id, source_id, measured_value_dimension_id);


--
-- Name: tbl_measured_values pk_tbl_measured_values; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_measured_values
    ADD CONSTRAINT pk_tbl_measured_values PRIMARY KEY (submission_id, source_id, measured_value_id);


--
-- Name: tbl_method_groups pk_tbl_method_groups; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_method_groups
    ADD CONSTRAINT pk_tbl_method_groups PRIMARY KEY (submission_id, source_id, method_group_id);


--
-- Name: tbl_methods pk_tbl_methods; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_methods
    ADD CONSTRAINT pk_tbl_methods PRIMARY KEY (submission_id, source_id, method_id);


--
-- Name: tbl_modification_types pk_tbl_modification_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_modification_types
    ADD CONSTRAINT pk_tbl_modification_types PRIMARY KEY (submission_id, source_id, modification_type_id);


--
-- Name: tbl_physical_sample_features pk_tbl_physical_sample_features; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_physical_sample_features
    ADD CONSTRAINT pk_tbl_physical_sample_features PRIMARY KEY (submission_id, source_id, physical_sample_feature_id);


--
-- Name: tbl_physical_samples pk_tbl_physical_samples; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_physical_samples
    ADD CONSTRAINT pk_tbl_physical_samples PRIMARY KEY (submission_id, source_id, physical_sample_id);


--
-- Name: tbl_project_stages pk_tbl_project_stages; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_project_stages
    ADD CONSTRAINT pk_tbl_project_stages PRIMARY KEY (submission_id, source_id, project_stage_id);


--
-- Name: tbl_project_types pk_tbl_project_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_project_types
    ADD CONSTRAINT pk_tbl_project_types PRIMARY KEY (submission_id, source_id, project_type_id);


--
-- Name: tbl_projects pk_tbl_projects; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_projects
    ADD CONSTRAINT pk_tbl_projects PRIMARY KEY (submission_id, source_id, project_id);


--
-- Name: tbl_publication_types pk_tbl_publication_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_publication_types
    ADD CONSTRAINT pk_tbl_publication_types PRIMARY KEY (submission_id, source_id, publication_type_id);


--
-- Name: tbl_publishers pk_tbl_publishers; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_publishers
    ADD CONSTRAINT pk_tbl_publishers PRIMARY KEY (submission_id, source_id, publisher_id);


--
-- Name: tbl_radiocarbon_calibration pk_tbl_radiocarbon_calibration; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_radiocarbon_calibration
    ADD CONSTRAINT pk_tbl_radiocarbon_calibration PRIMARY KEY (submission_id, source_id, radiocarbon_calibration_id);


--
-- Name: tbl_rdb pk_tbl_rdb; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_rdb
    ADD CONSTRAINT pk_tbl_rdb PRIMARY KEY (submission_id, source_id, rdb_id);


--
-- Name: tbl_rdb_codes pk_tbl_rdb_codes; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_rdb_codes
    ADD CONSTRAINT pk_tbl_rdb_codes PRIMARY KEY (submission_id, source_id, rdb_code_id);


--
-- Name: tbl_rdb_systems pk_tbl_rdb_systems; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_rdb_systems
    ADD CONSTRAINT pk_tbl_rdb_systems PRIMARY KEY (submission_id, source_id, rdb_system_id);


--
-- Name: tbl_record_types pk_tbl_record_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_record_types
    ADD CONSTRAINT pk_tbl_record_types PRIMARY KEY (submission_id, source_id, record_type_id);


--
-- Name: tbl_relative_age_refs pk_tbl_relative_age_refs; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_relative_age_refs
    ADD CONSTRAINT pk_tbl_relative_age_refs PRIMARY KEY (submission_id, source_id, relative_age_ref_id);


--
-- Name: tbl_relative_age_types pk_tbl_relative_age_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_relative_age_types
    ADD CONSTRAINT pk_tbl_relative_age_types PRIMARY KEY (submission_id, source_id, relative_age_type_id);


--
-- Name: tbl_relative_ages pk_tbl_relative_ages; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_relative_ages
    ADD CONSTRAINT pk_tbl_relative_ages PRIMARY KEY (submission_id, source_id, relative_age_id);


--
-- Name: tbl_relative_dates pk_tbl_relative_dates; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_relative_dates
    ADD CONSTRAINT pk_tbl_relative_dates PRIMARY KEY (submission_id, source_id, relative_date_id);


--
-- Name: tbl_sample_alt_refs pk_tbl_sample_alt_refs; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_alt_refs
    ADD CONSTRAINT pk_tbl_sample_alt_refs PRIMARY KEY (submission_id, source_id, sample_alt_ref_id);


--
-- Name: tbl_sample_colours pk_tbl_sample_colours; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_colours
    ADD CONSTRAINT pk_tbl_sample_colours PRIMARY KEY (submission_id, source_id, sample_colour_id);


--
-- Name: tbl_sample_coordinates pk_tbl_sample_coordinates; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_coordinates
    ADD CONSTRAINT pk_tbl_sample_coordinates PRIMARY KEY (submission_id, source_id, sample_coordinate_id);


--
-- Name: tbl_sample_description_sample_group_contexts pk_tbl_sample_description_sample_group_contexts; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_description_sample_group_contexts
    ADD CONSTRAINT pk_tbl_sample_description_sample_group_contexts PRIMARY KEY (submission_id, source_id, sample_description_sample_group_context_id);


--
-- Name: tbl_sample_description_types pk_tbl_sample_description_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_description_types
    ADD CONSTRAINT pk_tbl_sample_description_types PRIMARY KEY (submission_id, source_id, sample_description_type_id);


--
-- Name: tbl_sample_descriptions pk_tbl_sample_descriptions; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_descriptions
    ADD CONSTRAINT pk_tbl_sample_descriptions PRIMARY KEY (submission_id, source_id, sample_description_id);


--
-- Name: tbl_sample_dimensions pk_tbl_sample_dimensions; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_dimensions
    ADD CONSTRAINT pk_tbl_sample_dimensions PRIMARY KEY (submission_id, source_id, sample_dimension_id);


--
-- Name: tbl_sample_group_coordinates pk_tbl_sample_group_coordinates; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_coordinates
    ADD CONSTRAINT pk_tbl_sample_group_coordinates PRIMARY KEY (submission_id, source_id, sample_group_position_id);


--
-- Name: tbl_sample_group_description_type_sampling_contexts pk_tbl_sample_group_description_type_sampling_contexts; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_description_type_sampling_contexts
    ADD CONSTRAINT pk_tbl_sample_group_description_type_sampling_contexts PRIMARY KEY (submission_id, source_id, sample_group_description_type_sampling_context_id);


--
-- Name: tbl_sample_group_description_types pk_tbl_sample_group_description_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_description_types
    ADD CONSTRAINT pk_tbl_sample_group_description_types PRIMARY KEY (submission_id, source_id, sample_group_description_type_id);


--
-- Name: tbl_sample_group_descriptions pk_tbl_sample_group_descriptions; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_descriptions
    ADD CONSTRAINT pk_tbl_sample_group_descriptions PRIMARY KEY (submission_id, source_id, sample_group_description_id);


--
-- Name: tbl_sample_group_dimensions pk_tbl_sample_group_dimensions; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_dimensions
    ADD CONSTRAINT pk_tbl_sample_group_dimensions PRIMARY KEY (submission_id, source_id, sample_group_dimension_id);


--
-- Name: tbl_sample_group_images pk_tbl_sample_group_images; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_images
    ADD CONSTRAINT pk_tbl_sample_group_images PRIMARY KEY (submission_id, source_id, sample_group_image_id);


--
-- Name: tbl_sample_group_notes pk_tbl_sample_group_notes; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_notes
    ADD CONSTRAINT pk_tbl_sample_group_notes PRIMARY KEY (submission_id, source_id, sample_group_note_id);


--
-- Name: tbl_sample_group_references pk_tbl_sample_group_references; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_references
    ADD CONSTRAINT pk_tbl_sample_group_references PRIMARY KEY (submission_id, source_id, sample_group_reference_id);


--
-- Name: tbl_sample_group_sampling_contexts pk_tbl_sample_group_sampling_contexts; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_sampling_contexts
    ADD CONSTRAINT pk_tbl_sample_group_sampling_contexts PRIMARY KEY (submission_id, source_id, sampling_context_id);


--
-- Name: tbl_sample_groups pk_tbl_sample_groups; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_groups
    ADD CONSTRAINT pk_tbl_sample_groups PRIMARY KEY (submission_id, source_id, sample_group_id);


--
-- Name: tbl_sample_horizons pk_tbl_sample_horizons; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_horizons
    ADD CONSTRAINT pk_tbl_sample_horizons PRIMARY KEY (submission_id, source_id, sample_horizon_id);


--
-- Name: tbl_sample_images pk_tbl_sample_images; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_images
    ADD CONSTRAINT pk_tbl_sample_images PRIMARY KEY (submission_id, source_id, sample_image_id);


--
-- Name: tbl_sample_location_type_sampling_contexts pk_tbl_sample_location_type_sampling_contexts; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_location_type_sampling_contexts
    ADD CONSTRAINT pk_tbl_sample_location_type_sampling_contexts PRIMARY KEY (submission_id, source_id, sample_location_type_sampling_context_id);


--
-- Name: tbl_sample_location_types pk_tbl_sample_location_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_location_types
    ADD CONSTRAINT pk_tbl_sample_location_types PRIMARY KEY (submission_id, source_id, sample_location_type_id);


--
-- Name: tbl_sample_locations pk_tbl_sample_locations; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_locations
    ADD CONSTRAINT pk_tbl_sample_locations PRIMARY KEY (submission_id, source_id, sample_location_id);


--
-- Name: tbl_sample_notes pk_tbl_sample_notes; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_notes
    ADD CONSTRAINT pk_tbl_sample_notes PRIMARY KEY (submission_id, source_id, sample_note_id);


--
-- Name: tbl_sample_types pk_tbl_sample_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sample_types
    ADD CONSTRAINT pk_tbl_sample_types PRIMARY KEY (submission_id, source_id, sample_type_id);


--
-- Name: tbl_season_types pk_tbl_season_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_season_types
    ADD CONSTRAINT pk_tbl_season_types PRIMARY KEY (submission_id, source_id, season_type_id);


--
-- Name: tbl_seasons pk_tbl_seasons; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_seasons
    ADD CONSTRAINT pk_tbl_seasons PRIMARY KEY (submission_id, source_id, season_id);


--
-- Name: tbl_site_images pk_tbl_site_images; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_site_images
    ADD CONSTRAINT pk_tbl_site_images PRIMARY KEY (submission_id, source_id, site_image_id);


--
-- Name: tbl_site_locations pk_tbl_site_locations; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_site_locations
    ADD CONSTRAINT pk_tbl_site_locations PRIMARY KEY (submission_id, source_id, site_location_id);


--
-- Name: tbl_site_natgridrefs pk_tbl_site_natgridrefs; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_site_natgridrefs
    ADD CONSTRAINT pk_tbl_site_natgridrefs PRIMARY KEY (submission_id, source_id, site_natgridref_id);


--
-- Name: tbl_site_other_records pk_tbl_site_other_records; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_site_other_records
    ADD CONSTRAINT pk_tbl_site_other_records PRIMARY KEY (submission_id, source_id, site_other_records_id);


--
-- Name: tbl_site_preservation_status pk_tbl_site_preservation_status; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_site_preservation_status
    ADD CONSTRAINT pk_tbl_site_preservation_status PRIMARY KEY (submission_id, source_id, site_preservation_status_id);


--
-- Name: tbl_site_references pk_tbl_site_references; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_site_references
    ADD CONSTRAINT pk_tbl_site_references PRIMARY KEY (submission_id, source_id, site_reference_id);


--
-- Name: tbl_sites pk_tbl_sites; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_sites
    ADD CONSTRAINT pk_tbl_sites PRIMARY KEY (submission_id, source_id, site_id);


--
-- Name: tbl_species_association_types pk_tbl_species_association_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_species_association_types
    ADD CONSTRAINT pk_tbl_species_association_types PRIMARY KEY (submission_id, source_id, association_type_id);


--
-- Name: tbl_species_associations pk_tbl_species_associations; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_species_associations
    ADD CONSTRAINT pk_tbl_species_associations PRIMARY KEY (submission_id, source_id, species_association_id);


--
-- Name: tbl_clearinghouse_submission_xml_content_columns pk_tbl_submission_xml_content_columns_column_id; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submission_xml_content_columns
    ADD CONSTRAINT pk_tbl_submission_xml_content_columns_column_id PRIMARY KEY (column_id);


--
-- Name: tbl_clearinghouse_submission_xml_content_tables pk_tbl_submission_xml_content_meta_tables_table_id; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submission_xml_content_tables
    ADD CONSTRAINT pk_tbl_submission_xml_content_meta_tables_table_id PRIMARY KEY (content_table_id);


--
-- Name: tbl_clearinghouse_submission_xml_content_values pk_tbl_submission_xml_content_record_values_value_id; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submission_xml_content_values
    ADD CONSTRAINT pk_tbl_submission_xml_content_record_values_value_id PRIMARY KEY (value_id);


--
-- Name: tbl_clearinghouse_submission_xml_content_records pk_tbl_submission_xml_content_records_record_id; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submission_xml_content_records
    ADD CONSTRAINT pk_tbl_submission_xml_content_records_record_id PRIMARY KEY (record_id);


--
-- Name: tbl_taxa_common_names pk_tbl_taxa_common_names; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_taxa_common_names
    ADD CONSTRAINT pk_tbl_taxa_common_names PRIMARY KEY (submission_id, source_id, taxon_common_name_id);


--
-- Name: tbl_taxa_images pk_tbl_taxa_images; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_taxa_images
    ADD CONSTRAINT pk_tbl_taxa_images PRIMARY KEY (submission_id, source_id, taxa_images_id);


--
-- Name: tbl_taxa_measured_attributes pk_tbl_taxa_measured_attributes; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_taxa_measured_attributes
    ADD CONSTRAINT pk_tbl_taxa_measured_attributes PRIMARY KEY (submission_id, source_id, measured_attribute_id);


--
-- Name: tbl_taxa_reference_specimens pk_tbl_taxa_reference_specimens; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_taxa_reference_specimens
    ADD CONSTRAINT pk_tbl_taxa_reference_specimens PRIMARY KEY (submission_id, source_id, taxa_reference_specimen_id);


--
-- Name: tbl_taxa_seasonality pk_tbl_taxa_seasonality; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_taxa_seasonality
    ADD CONSTRAINT pk_tbl_taxa_seasonality PRIMARY KEY (submission_id, source_id, seasonality_id);


--
-- Name: tbl_taxa_synonyms pk_tbl_taxa_synonyms; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_taxa_synonyms
    ADD CONSTRAINT pk_tbl_taxa_synonyms PRIMARY KEY (submission_id, source_id, synonym_id);


--
-- Name: tbl_taxa_tree_authors pk_tbl_taxa_tree_authors; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_taxa_tree_authors
    ADD CONSTRAINT pk_tbl_taxa_tree_authors PRIMARY KEY (submission_id, source_id, author_id);


--
-- Name: tbl_taxa_tree_families pk_tbl_taxa_tree_families; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_taxa_tree_families
    ADD CONSTRAINT pk_tbl_taxa_tree_families PRIMARY KEY (submission_id, source_id, family_id);


--
-- Name: tbl_taxa_tree_genera pk_tbl_taxa_tree_genera; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_taxa_tree_genera
    ADD CONSTRAINT pk_tbl_taxa_tree_genera PRIMARY KEY (submission_id, source_id, genus_id);


--
-- Name: tbl_taxa_tree_master pk_tbl_taxa_tree_master; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_taxa_tree_master
    ADD CONSTRAINT pk_tbl_taxa_tree_master PRIMARY KEY (submission_id, source_id, taxon_id);


--
-- Name: tbl_taxa_tree_orders pk_tbl_taxa_tree_orders; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_taxa_tree_orders
    ADD CONSTRAINT pk_tbl_taxa_tree_orders PRIMARY KEY (submission_id, source_id, order_id);


--
-- Name: tbl_taxonomic_order pk_tbl_taxonomic_order; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_taxonomic_order
    ADD CONSTRAINT pk_tbl_taxonomic_order PRIMARY KEY (submission_id, source_id, taxonomic_order_id);


--
-- Name: tbl_taxonomic_order_biblio pk_tbl_taxonomic_order_biblio; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_taxonomic_order_biblio
    ADD CONSTRAINT pk_tbl_taxonomic_order_biblio PRIMARY KEY (submission_id, source_id, taxonomic_order_biblio_id);


--
-- Name: tbl_taxonomic_order_systems pk_tbl_taxonomic_order_systems; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_taxonomic_order_systems
    ADD CONSTRAINT pk_tbl_taxonomic_order_systems PRIMARY KEY (submission_id, source_id, taxonomic_order_system_id);


--
-- Name: tbl_taxonomy_notes pk_tbl_taxonomy_notes; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_taxonomy_notes
    ADD CONSTRAINT pk_tbl_taxonomy_notes PRIMARY KEY (submission_id, source_id, taxonomy_notes_id);


--
-- Name: tbl_tephra_dates pk_tbl_tephra_dates; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_tephra_dates
    ADD CONSTRAINT pk_tbl_tephra_dates PRIMARY KEY (submission_id, source_id, tephra_date_id);


--
-- Name: tbl_tephra_refs pk_tbl_tephra_refs; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_tephra_refs
    ADD CONSTRAINT pk_tbl_tephra_refs PRIMARY KEY (submission_id, source_id, tephra_ref_id);


--
-- Name: tbl_tephras pk_tbl_tephras; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_tephras
    ADD CONSTRAINT pk_tbl_tephras PRIMARY KEY (submission_id, source_id, tephra_id);


--
-- Name: tbl_text_biology pk_tbl_text_biology; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_text_biology
    ADD CONSTRAINT pk_tbl_text_biology PRIMARY KEY (submission_id, source_id, biology_id);


--
-- Name: tbl_text_distribution pk_tbl_text_distribution; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_text_distribution
    ADD CONSTRAINT pk_tbl_text_distribution PRIMARY KEY (submission_id, source_id, distribution_id);


--
-- Name: tbl_text_identification_keys pk_tbl_text_identification_keys; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_text_identification_keys
    ADD CONSTRAINT pk_tbl_text_identification_keys PRIMARY KEY (submission_id, source_id, key_id);


--
-- Name: tbl_units pk_tbl_units; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_units
    ADD CONSTRAINT pk_tbl_units PRIMARY KEY (submission_id, source_id, unit_id);


--
-- Name: tbl_updates_log pk_tbl_updates_log; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_updates_log
    ADD CONSTRAINT pk_tbl_updates_log PRIMARY KEY (submission_id, source_id, updates_log_id);


--
-- Name: tbl_years_types pk_tbl_years_types; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_years_types
    ADD CONSTRAINT pk_tbl_years_types PRIMARY KEY (submission_id, source_id, years_type_id);


--
-- Name: tbl_clearinghouse_users pk_user_id; Type: CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_users
    ADD CONSTRAINT pk_user_id PRIMARY KEY (user_id);


SET search_path = metainformation, pg_catalog;

--
-- Name: tbl_foreign_relations foreign_relations_id_pk; Type: CONSTRAINT; Schema: metainformation; Owner: -
--

ALTER TABLE ONLY tbl_foreign_relations
    ADD CONSTRAINT foreign_relations_id_pk PRIMARY KEY (source_table, source_column, target_table, target_column);


--
-- Name: language_definitions language_definitions_pkey; Type: CONSTRAINT; Schema: metainformation; Owner: -
--

ALTER TABLE ONLY language_definitions
    ADD CONSTRAINT language_definitions_pkey PRIMARY KEY (id);


--
-- Name: original_phrases original_phrases_pkey; Type: CONSTRAINT; Schema: metainformation; Owner: -
--

ALTER TABLE ONLY original_phrases
    ADD CONSTRAINT original_phrases_pkey PRIMARY KEY (id);


--
-- Name: translated_phrases translated_phrases_original_phrase_id_key; Type: CONSTRAINT; Schema: metainformation; Owner: -
--

ALTER TABLE ONLY translated_phrases
    ADD CONSTRAINT translated_phrases_original_phrase_id_key UNIQUE (original_phrase_id);


--
-- Name: translated_phrases translated_phrases_pkey; Type: CONSTRAINT; Schema: metainformation; Owner: -
--

ALTER TABLE ONLY translated_phrases
    ADD CONSTRAINT translated_phrases_pkey PRIMARY KEY (id);


--
-- Name: tbl_view_states view_state_pkey; Type: CONSTRAINT; Schema: metainformation; Owner: -
--

ALTER TABLE ONLY tbl_view_states
    ADD CONSTRAINT view_state_pkey PRIMARY KEY (view_state_id);


SET search_path = public, pg_catalog;

--
-- Name: tbl_project_stages dataset_stage_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_project_stages
    ADD CONSTRAINT dataset_stage_id PRIMARY KEY (project_stage_id);


--
-- Name: tbl_mcr_summary_data key_mcr_summary_data_taxon_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_mcr_summary_data
    ADD CONSTRAINT key_mcr_summary_data_taxon_id UNIQUE (taxon_id);


--
-- Name: tbl_abundance_elements pk_abundance_elements; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_abundance_elements
    ADD CONSTRAINT pk_abundance_elements PRIMARY KEY (abundance_element_id);


--
-- Name: tbl_abundance_ident_levels pk_abundance_ident_levels; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_abundance_ident_levels
    ADD CONSTRAINT pk_abundance_ident_levels PRIMARY KEY (abundance_ident_level_id);


--
-- Name: tbl_abundance_modifications pk_abundance_modifications; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_abundance_modifications
    ADD CONSTRAINT pk_abundance_modifications PRIMARY KEY (abundance_modification_id);


--
-- Name: tbl_abundances pk_abundances; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_abundances
    ADD CONSTRAINT pk_abundances PRIMARY KEY (abundance_id);


--
-- Name: tbl_activity_types pk_activity_types; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_activity_types
    ADD CONSTRAINT pk_activity_types PRIMARY KEY (activity_type_id);


--
-- Name: tbl_aggregate_datasets pk_aggregate_datasets; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_aggregate_datasets
    ADD CONSTRAINT pk_aggregate_datasets PRIMARY KEY (aggregate_dataset_id);


--
-- Name: tbl_aggregate_order_types pk_aggregate_order_types; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_aggregate_order_types
    ADD CONSTRAINT pk_aggregate_order_types PRIMARY KEY (aggregate_order_type_id);


--
-- Name: tbl_aggregate_sample_ages pk_aggregate_sample_ages; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_aggregate_sample_ages
    ADD CONSTRAINT pk_aggregate_sample_ages PRIMARY KEY (aggregate_sample_age_id);


--
-- Name: tbl_aggregate_samples pk_aggregate_samples; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_aggregate_samples
    ADD CONSTRAINT pk_aggregate_samples PRIMARY KEY (aggregate_sample_id);


--
-- Name: tbl_alt_ref_types pk_alt_ref_types; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_alt_ref_types
    ADD CONSTRAINT pk_alt_ref_types PRIMARY KEY (alt_ref_type_id);


--
-- Name: tbl_analysis_entities pk_analysis_entities; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_analysis_entities
    ADD CONSTRAINT pk_analysis_entities PRIMARY KEY (analysis_entity_id);


--
-- Name: tbl_biblio pk_biblio; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_biblio
    ADD CONSTRAINT pk_biblio PRIMARY KEY (biblio_id);


--
-- Name: tbl_chron_control_types pk_chron_control_types; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_chron_control_types
    ADD CONSTRAINT pk_chron_control_types PRIMARY KEY (chron_control_type_id);


--
-- Name: tbl_chron_controls pk_chron_controls; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_chron_controls
    ADD CONSTRAINT pk_chron_controls PRIMARY KEY (chron_control_id);


--
-- Name: tbl_chronologies pk_chronologies; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_chronologies
    ADD CONSTRAINT pk_chronologies PRIMARY KEY (chronology_id);


--
-- Name: tbl_collections_or_journals pk_collections_or_journals; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_collections_or_journals
    ADD CONSTRAINT pk_collections_or_journals PRIMARY KEY (collection_or_journal_id);


--
-- Name: tbl_colours pk_colours; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_colours
    ADD CONSTRAINT pk_colours PRIMARY KEY (colour_id);


--
-- Name: tbl_contact_types pk_contact_types; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_contact_types
    ADD CONSTRAINT pk_contact_types PRIMARY KEY (contact_type_id);


--
-- Name: tbl_contacts pk_contacts; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_contacts
    ADD CONSTRAINT pk_contacts PRIMARY KEY (contact_id);


--
-- Name: tbl_data_type_groups pk_data_type_groups; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_data_type_groups
    ADD CONSTRAINT pk_data_type_groups PRIMARY KEY (data_type_group_id);


--
-- Name: tbl_dataset_contacts pk_dataset_contacts; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dataset_contacts
    ADD CONSTRAINT pk_dataset_contacts PRIMARY KEY (dataset_contact_id);


--
-- Name: tbl_dataset_masters pk_dataset_masters; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dataset_masters
    ADD CONSTRAINT pk_dataset_masters PRIMARY KEY (master_set_id);


--
-- Name: tbl_dataset_submission_types pk_dataset_submission_types; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dataset_submission_types
    ADD CONSTRAINT pk_dataset_submission_types PRIMARY KEY (submission_type_id);


--
-- Name: tbl_dataset_submissions pk_dataset_submissions; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dataset_submissions
    ADD CONSTRAINT pk_dataset_submissions PRIMARY KEY (dataset_submission_id);


--
-- Name: tbl_datasets pk_datasets; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_datasets
    ADD CONSTRAINT pk_datasets PRIMARY KEY (dataset_id);


--
-- Name: tbl_dating_labs pk_dating_labs; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dating_labs
    ADD CONSTRAINT pk_dating_labs PRIMARY KEY (dating_lab_id);


--
-- Name: tbl_dimensions pk_dimensions; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dimensions
    ADD CONSTRAINT pk_dimensions PRIMARY KEY (dimension_id);


--
-- Name: tbl_ecocode_definitions pk_ecocode_definitions; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ecocode_definitions
    ADD CONSTRAINT pk_ecocode_definitions PRIMARY KEY (ecocode_definition_id);


--
-- Name: tbl_ecocode_groups pk_ecocode_groups; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ecocode_groups
    ADD CONSTRAINT pk_ecocode_groups PRIMARY KEY (ecocode_group_id);


--
-- Name: tbl_ecocode_systems pk_ecocode_systems; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ecocode_systems
    ADD CONSTRAINT pk_ecocode_systems PRIMARY KEY (ecocode_system_id);


--
-- Name: tbl_ecocodes pk_ecocodes; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ecocodes
    ADD CONSTRAINT pk_ecocodes PRIMARY KEY (ecocode_id);


--
-- Name: tbl_feature_types pk_feature_type_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_feature_types
    ADD CONSTRAINT pk_feature_type_id PRIMARY KEY (feature_type_id);


--
-- Name: tbl_features pk_features; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_features
    ADD CONSTRAINT pk_features PRIMARY KEY (feature_id);


--
-- Name: tbl_geochron_refs pk_geochron_refs; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_geochron_refs
    ADD CONSTRAINT pk_geochron_refs PRIMARY KEY (geochron_ref_id);


--
-- Name: tbl_geochronology pk_geochronology; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_geochronology
    ADD CONSTRAINT pk_geochronology PRIMARY KEY (geochron_id);


--
-- Name: tbl_horizons pk_horizons; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_horizons
    ADD CONSTRAINT pk_horizons PRIMARY KEY (horizon_id);


--
-- Name: tbl_identification_levels pk_identification_levels; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_identification_levels
    ADD CONSTRAINT pk_identification_levels PRIMARY KEY (identification_level_id);


--
-- Name: tbl_image_types pk_image_types; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_image_types
    ADD CONSTRAINT pk_image_types PRIMARY KEY (image_type_id);


--
-- Name: tbl_imported_taxa_replacements pk_imported_taxa_replacements; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_imported_taxa_replacements
    ADD CONSTRAINT pk_imported_taxa_replacements PRIMARY KEY (imported_taxa_replacement_id);


--
-- Name: tbl_languages pk_languages; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_languages
    ADD CONSTRAINT pk_languages PRIMARY KEY (language_id);


--
-- Name: tbl_lithology pk_lithologies; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_lithology
    ADD CONSTRAINT pk_lithologies PRIMARY KEY (lithology_id);


--
-- Name: tbl_location_types pk_location_types; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_location_types
    ADD CONSTRAINT pk_location_types PRIMARY KEY (location_type_id);


--
-- Name: tbl_locations pk_locations; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_locations
    ADD CONSTRAINT pk_locations PRIMARY KEY (location_id);


--
-- Name: tbl_mcr_names pk_mcr_names; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_mcr_names
    ADD CONSTRAINT pk_mcr_names PRIMARY KEY (taxon_id);


--
-- Name: tbl_mcr_summary_data pk_mcr_summary_data; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_mcr_summary_data
    ADD CONSTRAINT pk_mcr_summary_data PRIMARY KEY (mcr_summary_data_id);


--
-- Name: tbl_mcrdata_birmbeetledat pk_mcrdata_birmbeetledat; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_mcrdata_birmbeetledat
    ADD CONSTRAINT pk_mcrdata_birmbeetledat PRIMARY KEY (mcrdata_birmbeetledat_id);


--
-- Name: tbl_measured_values pk_measured_values; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_measured_values
    ADD CONSTRAINT pk_measured_values PRIMARY KEY (measured_value_id);


--
-- Name: tbl_measured_value_dimensions pk_measured_weights; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_measured_value_dimensions
    ADD CONSTRAINT pk_measured_weights PRIMARY KEY (measured_value_dimension_id);


--
-- Name: tbl_method_groups pk_method_groups; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_method_groups
    ADD CONSTRAINT pk_method_groups PRIMARY KEY (method_group_id);


--
-- Name: tbl_methods pk_methods; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_methods
    ADD CONSTRAINT pk_methods PRIMARY KEY (method_id);


--
-- Name: tbl_modification_types pk_modification_types; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_modification_types
    ADD CONSTRAINT pk_modification_types PRIMARY KEY (modification_type_id);


--
-- Name: tbl_physical_samples pk_physical_samples; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_physical_samples
    ADD CONSTRAINT pk_physical_samples PRIMARY KEY (physical_sample_id);


--
-- Name: tbl_project_types pk_project_type_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_project_types
    ADD CONSTRAINT pk_project_type_id PRIMARY KEY (project_type_id);


--
-- Name: tbl_projects pk_projects; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_projects
    ADD CONSTRAINT pk_projects PRIMARY KEY (project_id);


--
-- Name: tbl_publication_types pk_publication_types; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_publication_types
    ADD CONSTRAINT pk_publication_types PRIMARY KEY (publication_type_id);


--
-- Name: tbl_publishers pk_publishers; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_publishers
    ADD CONSTRAINT pk_publishers PRIMARY KEY (publisher_id);


--
-- Name: tbl_radiocarbon_calibration pk_radiocarbon_calibration; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_radiocarbon_calibration
    ADD CONSTRAINT pk_radiocarbon_calibration PRIMARY KEY (radiocarbon_calibration_id);


--
-- Name: tbl_rdb pk_rdb; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_rdb
    ADD CONSTRAINT pk_rdb PRIMARY KEY (rdb_id);


--
-- Name: tbl_rdb_codes pk_rdb_codes; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_rdb_codes
    ADD CONSTRAINT pk_rdb_codes PRIMARY KEY (rdb_code_id);


--
-- Name: tbl_rdb_systems pk_rdb_systems; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_rdb_systems
    ADD CONSTRAINT pk_rdb_systems PRIMARY KEY (rdb_system_id);


--
-- Name: tbl_record_types pk_record_types; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_record_types
    ADD CONSTRAINT pk_record_types PRIMARY KEY (record_type_id);


--
-- Name: tbl_relative_age_refs pk_relative_age_refs; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_relative_age_refs
    ADD CONSTRAINT pk_relative_age_refs PRIMARY KEY (relative_age_ref_id);


--
-- Name: tbl_relative_ages pk_relative_ages; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_relative_ages
    ADD CONSTRAINT pk_relative_ages PRIMARY KEY (relative_age_id);


--
-- Name: tbl_relative_dates pk_relative_dates; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_relative_dates
    ADD CONSTRAINT pk_relative_dates PRIMARY KEY (relative_date_id);


--
-- Name: tbl_analysis_entity_ages pk_sample_ages; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_analysis_entity_ages
    ADD CONSTRAINT pk_sample_ages PRIMARY KEY (analysis_entity_age_id);


--
-- Name: tbl_sample_alt_refs pk_sample_alt_refs; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_alt_refs
    ADD CONSTRAINT pk_sample_alt_refs PRIMARY KEY (sample_alt_ref_id);


--
-- Name: tbl_sample_colours pk_sample_colours; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_colours
    ADD CONSTRAINT pk_sample_colours PRIMARY KEY (sample_colour_id);


--
-- Name: tbl_sample_dimensions pk_sample_dimensions; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_dimensions
    ADD CONSTRAINT pk_sample_dimensions PRIMARY KEY (sample_dimension_id);


--
-- Name: tbl_sample_group_descriptions pk_sample_group_description_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_descriptions
    ADD CONSTRAINT pk_sample_group_description_id PRIMARY KEY (sample_group_description_id);


--
-- Name: tbl_sample_group_dimensions pk_sample_group_dimensions; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_dimensions
    ADD CONSTRAINT pk_sample_group_dimensions PRIMARY KEY (sample_group_dimension_id);


--
-- Name: tbl_sample_group_images pk_sample_group_images; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_images
    ADD CONSTRAINT pk_sample_group_images PRIMARY KEY (sample_group_image_id);


--
-- Name: tbl_sample_group_notes pk_sample_group_note_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_notes
    ADD CONSTRAINT pk_sample_group_note_id PRIMARY KEY (sample_group_note_id);


--
-- Name: tbl_sample_group_references pk_sample_group_references; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_references
    ADD CONSTRAINT pk_sample_group_references PRIMARY KEY (sample_group_reference_id);


--
-- Name: tbl_sample_group_sampling_contexts pk_sample_group_sampling_contexts; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_sampling_contexts
    ADD CONSTRAINT pk_sample_group_sampling_contexts PRIMARY KEY (sampling_context_id);


--
-- Name: tbl_sample_groups pk_sample_groups; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_groups
    ADD CONSTRAINT pk_sample_groups PRIMARY KEY (sample_group_id);


--
-- Name: tbl_sample_horizons pk_sample_horizons; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_horizons
    ADD CONSTRAINT pk_sample_horizons PRIMARY KEY (sample_horizon_id);


--
-- Name: tbl_sample_images pk_sample_images; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_images
    ADD CONSTRAINT pk_sample_images PRIMARY KEY (sample_image_id);


--
-- Name: tbl_sample_notes pk_sample_notes; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_notes
    ADD CONSTRAINT pk_sample_notes PRIMARY KEY (sample_note_id);


--
-- Name: tbl_sample_types pk_sample_types; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_types
    ADD CONSTRAINT pk_sample_types PRIMARY KEY (sample_type_id);


--
-- Name: tbl_data_types pk_samplegroup_data_types; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_data_types
    ADD CONSTRAINT pk_samplegroup_data_types PRIMARY KEY (data_type_id);


--
-- Name: tbl_season_types pk_season_types; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_season_types
    ADD CONSTRAINT pk_season_types PRIMARY KEY (season_type_id);


--
-- Name: tbl_seasons pk_seasons; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_seasons
    ADD CONSTRAINT pk_seasons PRIMARY KEY (season_id);


--
-- Name: tbl_site_images pk_site_images; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_images
    ADD CONSTRAINT pk_site_images PRIMARY KEY (site_image_id);


--
-- Name: tbl_site_locations pk_site_location; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_locations
    ADD CONSTRAINT pk_site_location PRIMARY KEY (site_location_id);


--
-- Name: tbl_site_other_records pk_site_other_records; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_other_records
    ADD CONSTRAINT pk_site_other_records PRIMARY KEY (site_other_records_id);


--
-- Name: tbl_site_preservation_status pk_site_preservation_status; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_preservation_status
    ADD CONSTRAINT pk_site_preservation_status PRIMARY KEY (site_preservation_status_id);


--
-- Name: tbl_site_references pk_site_references; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_references
    ADD CONSTRAINT pk_site_references PRIMARY KEY (site_reference_id);


--
-- Name: tbl_site_natgridrefs pk_sitenatgridrefs; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_natgridrefs
    ADD CONSTRAINT pk_sitenatgridrefs PRIMARY KEY (site_natgridref_id);


--
-- Name: tbl_sites pk_sites; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sites
    ADD CONSTRAINT pk_sites PRIMARY KEY (site_id);


--
-- Name: tbl_species_associations pk_species_associations; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_species_associations
    ADD CONSTRAINT pk_species_associations PRIMARY KEY (species_association_id);


--
-- Name: tbl_taxa_common_names pk_taxa_common_names; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_common_names
    ADD CONSTRAINT pk_taxa_common_names PRIMARY KEY (taxon_common_name_id);


--
-- Name: tbl_taxa_measured_attributes pk_taxa_measured_attributes; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_measured_attributes
    ADD CONSTRAINT pk_taxa_measured_attributes PRIMARY KEY (measured_attribute_id);


--
-- Name: tbl_taxa_seasonality pk_taxa_seasonality; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_seasonality
    ADD CONSTRAINT pk_taxa_seasonality PRIMARY KEY (seasonality_id);


--
-- Name: tbl_taxa_synonyms pk_taxa_synonyms; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_synonyms
    ADD CONSTRAINT pk_taxa_synonyms PRIMARY KEY (synonym_id);


--
-- Name: tbl_taxa_tree_authors pk_taxa_tree_authors; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_tree_authors
    ADD CONSTRAINT pk_taxa_tree_authors PRIMARY KEY (author_id);


--
-- Name: tbl_taxa_tree_families pk_taxa_tree_families; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_tree_families
    ADD CONSTRAINT pk_taxa_tree_families PRIMARY KEY (family_id);


--
-- Name: tbl_taxa_tree_genera pk_taxa_tree_genera; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_tree_genera
    ADD CONSTRAINT pk_taxa_tree_genera PRIMARY KEY (genus_id);


--
-- Name: tbl_taxa_tree_master pk_taxa_tree_master; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_tree_master
    ADD CONSTRAINT pk_taxa_tree_master PRIMARY KEY (taxon_id);


--
-- Name: tbl_taxa_tree_orders pk_taxa_tree_orders; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_tree_orders
    ADD CONSTRAINT pk_taxa_tree_orders PRIMARY KEY (order_id);


--
-- Name: tbl_taxonomic_order pk_taxonomic_order; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxonomic_order
    ADD CONSTRAINT pk_taxonomic_order PRIMARY KEY (taxonomic_order_id);


--
-- Name: tbl_taxonomic_order_biblio pk_taxonomic_order_biblio; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxonomic_order_biblio
    ADD CONSTRAINT pk_taxonomic_order_biblio PRIMARY KEY (taxonomic_order_biblio_id);


--
-- Name: tbl_taxonomic_order_systems pk_taxonomic_order_systems; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxonomic_order_systems
    ADD CONSTRAINT pk_taxonomic_order_systems PRIMARY KEY (taxonomic_order_system_id);


--
-- Name: tbl_taxonomy_notes pk_taxonomy_notes; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxonomy_notes
    ADD CONSTRAINT pk_taxonomy_notes PRIMARY KEY (taxonomy_notes_id);


--
-- Name: tbl_tephra_dates pk_tephra_dates; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_tephra_dates
    ADD CONSTRAINT pk_tephra_dates PRIMARY KEY (tephra_date_id);


--
-- Name: tbl_tephra_refs pk_tephra_refs; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_tephra_refs
    ADD CONSTRAINT pk_tephra_refs PRIMARY KEY (tephra_ref_id);


--
-- Name: tbl_tephras pk_tephras; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_tephras
    ADD CONSTRAINT pk_tephras PRIMARY KEY (tephra_id);


--
-- Name: tbl_text_biology pk_text_biology; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_text_biology
    ADD CONSTRAINT pk_text_biology PRIMARY KEY (biology_id);


--
-- Name: tbl_text_distribution pk_text_distribution; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_text_distribution
    ADD CONSTRAINT pk_text_distribution PRIMARY KEY (distribution_id);


--
-- Name: tbl_text_identification_keys pk_text_identification_keys; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_text_identification_keys
    ADD CONSTRAINT pk_text_identification_keys PRIMARY KEY (key_id);


--
-- Name: tbl_units pk_units; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_units
    ADD CONSTRAINT pk_units PRIMARY KEY (unit_id);


--
-- Name: tbl_updates_log pk_updates_log; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_updates_log
    ADD CONSTRAINT pk_updates_log PRIMARY KEY (updates_log_id);


--
-- Name: tbl_analysis_entity_dimensions tbl_analysis_entity_dimensions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_analysis_entity_dimensions
    ADD CONSTRAINT tbl_analysis_entity_dimensions_pkey PRIMARY KEY (analysis_entity_dimension_id);


--
-- Name: tbl_analysis_entity_prep_methods tbl_analysis_entity_prep_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_analysis_entity_prep_methods
    ADD CONSTRAINT tbl_analysis_entity_prep_methods_pkey PRIMARY KEY (analysis_entity_prep_method_id);


--
-- Name: tbl_species_association_types tbl_association_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_species_association_types
    ADD CONSTRAINT tbl_association_types_pkey PRIMARY KEY (association_type_id);


--
-- Name: tbl_biblio_keywords tbl_biblio_keywords_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_biblio_keywords
    ADD CONSTRAINT tbl_biblio_keywords_pkey PRIMARY KEY (biblio_keyword_id);


--
-- Name: tbl_ceramics_measurement_lookup tbl_ceramics_measurement_lookup_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ceramics_measurement_lookup
    ADD CONSTRAINT tbl_ceramics_measurement_lookup_pkey PRIMARY KEY (ceramics_measurement_lookup_id);


--
-- Name: tbl_ceramics_measurements tbl_ceramics_measurements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ceramics_measurements
    ADD CONSTRAINT tbl_ceramics_measurements_pkey PRIMARY KEY (ceramics_measurement_id);


--
-- Name: tbl_ceramics tbl_ceramics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ceramics
    ADD CONSTRAINT tbl_ceramics_pkey PRIMARY KEY (ceramics_id);


--
-- Name: tbl_coordinate_method_dimensions tbl_coordinate_method_dimensions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_coordinate_method_dimensions
    ADD CONSTRAINT tbl_coordinate_method_dimensions_pkey PRIMARY KEY (coordinate_method_dimension_id);


--
-- Name: tbl_dating_material tbl_dating_material_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dating_material
    ADD CONSTRAINT tbl_dating_material_pkey PRIMARY KEY (dating_material_id);


--
-- Name: tbl_dating_uncertainty tbl_dating_uncertainty_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dating_uncertainty
    ADD CONSTRAINT tbl_dating_uncertainty_pkey PRIMARY KEY (dating_uncertainty_id);


--
-- Name: tbl_dendro_date_notes tbl_dendro_date_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dendro_date_notes
    ADD CONSTRAINT tbl_dendro_date_notes_pkey PRIMARY KEY (dendro_date_note_id);


--
-- Name: tbl_dendro_dates tbl_dendro_dates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dendro_dates
    ADD CONSTRAINT tbl_dendro_dates_pkey PRIMARY KEY (dendro_date_id);


--
-- Name: tbl_dendro_measurement_lookup tbl_dendro_measurement_lookup_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dendro_measurement_lookup
    ADD CONSTRAINT tbl_dendro_measurement_lookup_pkey PRIMARY KEY (dendro_measurement_lookup_id);


--
-- Name: tbl_dendro_measurements tbl_dendro_measurements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dendro_measurements
    ADD CONSTRAINT tbl_dendro_measurements_pkey PRIMARY KEY (dendro_measurement_id);


--
-- Name: tbl_dendro tbl_dendro_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dendro
    ADD CONSTRAINT tbl_dendro_pkey PRIMARY KEY (dendro_id);


--
-- Name: tbl_keywords tbl_keywords_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_keywords
    ADD CONSTRAINT tbl_keywords_pkey PRIMARY KEY (keyword_id);


--
-- Name: tbl_physical_sample_features tbl_physical_sample_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_physical_sample_features
    ADD CONSTRAINT tbl_physical_sample_features_pkey PRIMARY KEY (physical_sample_feature_id);


--
-- Name: tbl_relative_age_types tbl_relative_age_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_relative_age_types
    ADD CONSTRAINT tbl_relative_age_types_pkey PRIMARY KEY (relative_age_type_id);


--
-- Name: tbl_sample_coordinates tbl_sample_coordinates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_coordinates
    ADD CONSTRAINT tbl_sample_coordinates_pkey PRIMARY KEY (sample_coordinate_id);


--
-- Name: tbl_sample_description_sample_group_contexts tbl_sample_description_sample_group_contexts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_description_sample_group_contexts
    ADD CONSTRAINT tbl_sample_description_sample_group_contexts_pkey PRIMARY KEY (sample_description_sample_group_context_id);


--
-- Name: tbl_sample_description_types tbl_sample_description_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_description_types
    ADD CONSTRAINT tbl_sample_description_types_pkey PRIMARY KEY (sample_description_type_id);


--
-- Name: tbl_sample_descriptions tbl_sample_descriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_descriptions
    ADD CONSTRAINT tbl_sample_descriptions_pkey PRIMARY KEY (sample_description_id);


--
-- Name: tbl_sample_group_coordinates tbl_sample_group_coordinates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_coordinates
    ADD CONSTRAINT tbl_sample_group_coordinates_pkey PRIMARY KEY (sample_group_position_id);


--
-- Name: tbl_sample_group_description_type_sampling_contexts tbl_sample_group_description_type_sample_contexts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_description_type_sampling_contexts
    ADD CONSTRAINT tbl_sample_group_description_type_sample_contexts_pkey PRIMARY KEY (sample_group_description_type_sampling_context_id);


--
-- Name: tbl_sample_group_description_types tbl_sample_group_description_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_description_types
    ADD CONSTRAINT tbl_sample_group_description_types_pkey PRIMARY KEY (sample_group_description_type_id);


--
-- Name: tbl_sample_location_type_sampling_contexts tbl_sample_location_sampling_contexts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_location_type_sampling_contexts
    ADD CONSTRAINT tbl_sample_location_sampling_contexts_pkey PRIMARY KEY (sample_location_type_sampling_context_id);


--
-- Name: tbl_sample_location_types tbl_sample_location_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_location_types
    ADD CONSTRAINT tbl_sample_location_types_pkey PRIMARY KEY (sample_location_type_id);


--
-- Name: tbl_sample_locations tbl_sample_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_locations
    ADD CONSTRAINT tbl_sample_locations_pkey PRIMARY KEY (sample_location_id);


--
-- Name: tbl_taxa_images tbl_taxa_images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_images
    ADD CONSTRAINT tbl_taxa_images_pkey PRIMARY KEY (taxa_images_id);


--
-- Name: tbl_taxa_reference_specimens tbl_taxa_reference_specimens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_reference_specimens
    ADD CONSTRAINT tbl_taxa_reference_specimens_pkey PRIMARY KEY (taxa_reference_specimen_id);


--
-- Name: tbl_years_types tbl_years_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_years_types
    ADD CONSTRAINT tbl_years_types_pkey PRIMARY KEY (years_type_id);


SET search_path = clearing_house, pg_catalog;

--
-- Name: fk_clearinghouse_reject_entity_types; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX fk_clearinghouse_reject_entity_types ON tbl_clearinghouse_reject_entity_types USING btree (table_id);


--
-- Name: fk_clearinghouse_submission_reject_entities_local_db_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX fk_clearinghouse_submission_reject_entities_local_db_id ON tbl_clearinghouse_submission_reject_entities USING btree (local_db_id);


--
-- Name: fk_clearinghouse_submission_reject_entities_submission; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX fk_clearinghouse_submission_reject_entities_submission ON tbl_clearinghouse_submission_reject_entities USING btree (submission_reject_id);


--
-- Name: fk_clearinghouse_submission_rejects; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX fk_clearinghouse_submission_rejects ON tbl_clearinghouse_submission_rejects USING btree (submission_id);


--
-- Name: fk_idx_tbl_submission_xml_content_tables_table_name; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE UNIQUE INDEX fk_idx_tbl_submission_xml_content_tables_table_name ON tbl_clearinghouse_submission_xml_content_tables USING btree (submission_id, table_id);


--
-- Name: idx_clearinghouse_activity_entity_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_clearinghouse_activity_entity_id ON tbl_clearinghouse_activity_log USING btree (entity_type_id, entity_id);


--
-- Name: idx_fk_abundance_elements_record_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_abundance_elements_record_type_id ON tbl_abundance_elements USING btree (record_type_id);


--
-- Name: idx_fk_abundance_ident_levels_abundance_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_abundance_ident_levels_abundance_id ON tbl_abundance_ident_levels USING btree (abundance_id);


--
-- Name: idx_fk_abundance_ident_levels_identification_level_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_abundance_ident_levels_identification_level_id ON tbl_abundance_ident_levels USING btree (identification_level_id);


--
-- Name: idx_fk_abundance_modifications_abundance_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_abundance_modifications_abundance_id ON tbl_abundance_modifications USING btree (abundance_id);


--
-- Name: idx_fk_abundance_modifications_modification_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_abundance_modifications_modification_type_id ON tbl_abundance_modifications USING btree (modification_type_id);


--
-- Name: idx_fk_abundances_abundance_elements_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_abundances_abundance_elements_id ON tbl_abundances USING btree (abundance_element_id);


--
-- Name: idx_fk_abundances_analysis_entity_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_abundances_analysis_entity_id ON tbl_abundances USING btree (analysis_entity_id);


--
-- Name: idx_fk_abundances_taxon_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_abundances_taxon_id ON tbl_abundances USING btree (taxon_id);


--
-- Name: idx_fk_aggragate_samples_analysis_entity_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_aggragate_samples_analysis_entity_id ON tbl_aggregate_samples USING btree (analysis_entity_id);


--
-- Name: idx_fk_aggregate_datasets_aggregate_order_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_aggregate_datasets_aggregate_order_type_id ON tbl_aggregate_datasets USING btree (aggregate_order_type_id);


--
-- Name: idx_fk_aggregate_datasets_biblio_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_aggregate_datasets_biblio_id ON tbl_aggregate_datasets USING btree (biblio_id);


--
-- Name: idx_fk_aggregate_sample_ages_aggregate_dataset_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_aggregate_sample_ages_aggregate_dataset_id ON tbl_aggregate_sample_ages USING btree (aggregate_dataset_id);


--
-- Name: idx_fk_aggregate_sample_ages_analysis_entity_age_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_aggregate_sample_ages_analysis_entity_age_id ON tbl_aggregate_sample_ages USING btree (analysis_entity_age_id);


--
-- Name: idx_fk_aggregate_samples_aggregate_dataset_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_aggregate_samples_aggregate_dataset_id ON tbl_aggregate_samples USING btree (aggregate_dataset_id);


--
-- Name: idx_fk_analysis_entities_dataset_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_analysis_entities_dataset_id ON tbl_analysis_entities USING btree (dataset_id);


--
-- Name: idx_fk_analysis_entities_physical_sample_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_analysis_entities_physical_sample_id ON tbl_analysis_entities USING btree (physical_sample_id);


--
-- Name: idx_fk_analysis_entity_ages_analysis_entity_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_analysis_entity_ages_analysis_entity_id ON tbl_analysis_entity_ages USING btree (analysis_entity_id);


--
-- Name: idx_fk_analysis_entity_ages_chronology_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_analysis_entity_ages_chronology_id ON tbl_analysis_entity_ages USING btree (chronology_id);


--
-- Name: idx_fk_analysis_entity_dimensions_analysis_entity_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_analysis_entity_dimensions_analysis_entity_id ON tbl_analysis_entity_dimensions USING btree (analysis_entity_id);


--
-- Name: idx_fk_analysis_entity_dimensions_dimension_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_analysis_entity_dimensions_dimension_id ON tbl_analysis_entity_dimensions USING btree (dimension_id);


--
-- Name: idx_fk_analysis_entity_prep_methods_analysis_entity_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_analysis_entity_prep_methods_analysis_entity_id ON tbl_analysis_entity_prep_methods USING btree (analysis_entity_id);


--
-- Name: idx_fk_analysis_entity_prep_methods_method_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_analysis_entity_prep_methods_method_id ON tbl_analysis_entity_prep_methods USING btree (method_id);


--
-- Name: idx_fk_biblio_collections_or_journals_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_biblio_collections_or_journals_id ON tbl_biblio USING btree (collection_or_journal_id);


--
-- Name: idx_fk_biblio_keywords_biblio_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_biblio_keywords_biblio_id ON tbl_biblio_keywords USING btree (biblio_id);


--
-- Name: idx_fk_biblio_keywords_keyword_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_biblio_keywords_keyword_id ON tbl_biblio_keywords USING btree (keyword_id);


--
-- Name: idx_fk_biblio_publication_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_biblio_publication_type_id ON tbl_biblio USING btree (publication_type_id);


--
-- Name: idx_fk_biblio_publisher_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_biblio_publisher_id ON tbl_biblio USING btree (publisher_id);


--
-- Name: idx_fk_bugs_abundance_codes_abundance_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_bugs_abundance_codes_abundance_id ON tbl_bugs_abundance_codes USING btree (abundance_id);


--
-- Name: idx_fk_bugs_biblio_biblio_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_bugs_biblio_biblio_id ON tbl_bugs_biblio USING btree (biblio_id);


--
-- Name: idx_fk_bugs_dates_calendar_relative_dates_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_bugs_dates_calendar_relative_dates_id ON tbl_bugs_dates_calendar USING btree (relative_date_id);


--
-- Name: idx_fk_bugs_dates_period_relative_date_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_bugs_dates_period_relative_date_id ON tbl_bugs_dates_period USING btree (relative_date_id);


--
-- Name: idx_fk_bugs_dates_radio_geochron_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_bugs_dates_radio_geochron_id ON tbl_bugs_dates_radio USING btree (geochron_id);


--
-- Name: idx_fk_bugs_datesmethods_method_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_bugs_datesmethods_method_id ON tbl_bugs_datesmethods USING btree (method_id);


--
-- Name: idx_fk_bugs_periods_relative_ages_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_bugs_periods_relative_ages_id ON tbl_bugs_periods USING btree (relative_age_id);


--
-- Name: idx_fk_bugs_physical_samples_physical_sample_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_bugs_physical_samples_physical_sample_id ON tbl_bugs_physical_samples USING btree (physical_sample_id);


--
-- Name: idx_fk_bugs_sample_groups_sample_group_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_bugs_sample_groups_sample_group_id ON tbl_bugs_sample_groups USING btree (sample_group_id);


--
-- Name: idx_fk_bugs_sites_site_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_bugs_sites_site_id ON tbl_bugs_sites USING btree (site_id);


--
-- Name: idx_fk_ceramics_analysis_entity_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_ceramics_analysis_entity_id ON tbl_ceramics USING btree (analysis_entity_id);


--
-- Name: idx_fk_ceramics_ceramics_measurement_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_ceramics_ceramics_measurement_id ON tbl_ceramics USING btree (ceramics_measurement_id);


--
-- Name: idx_fk_ceramics_measurement_lookup_ceramics_measurements_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_ceramics_measurement_lookup_ceramics_measurements_id ON tbl_ceramics_measurement_lookup USING btree (ceramics_measurement_id);


--
-- Name: idx_fk_ceramics_measurements_method_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_ceramics_measurements_method_id ON tbl_ceramics_measurements USING btree (method_id);


--
-- Name: idx_fk_chron_controls_chron_control_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_chron_controls_chron_control_type_id ON tbl_chron_controls USING btree (chron_control_type_id);


--
-- Name: idx_fk_chron_controls_chronology_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_chron_controls_chronology_id ON tbl_chron_controls USING btree (chronology_id);


--
-- Name: idx_fk_chronologies_contact_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_chronologies_contact_id ON tbl_chronologies USING btree (contact_id);


--
-- Name: idx_fk_chronologies_sample_group_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_chronologies_sample_group_id ON tbl_chronologies USING btree (sample_group_id);


--
-- Name: idx_fk_collections_or_journals_publisher_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_collections_or_journals_publisher_id ON tbl_collections_or_journals USING btree (publisher_id);


--
-- Name: idx_fk_colours_method_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_colours_method_id ON tbl_colours USING btree (method_id);


--
-- Name: idx_fk_coordinate_method_dimensions_dimensions_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_coordinate_method_dimensions_dimensions_id ON tbl_coordinate_method_dimensions USING btree (dimension_id);


--
-- Name: idx_fk_coordinate_method_dimensions_method_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_coordinate_method_dimensions_method_id ON tbl_coordinate_method_dimensions USING btree (method_id);


--
-- Name: idx_fk_data_types_data_type_group_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_data_types_data_type_group_id ON tbl_data_types USING btree (data_type_group_id);


--
-- Name: idx_fk_dataset_contacts_contact_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dataset_contacts_contact_id ON tbl_dataset_contacts USING btree (contact_id);


--
-- Name: idx_fk_dataset_contacts_contact_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dataset_contacts_contact_type_id ON tbl_dataset_contacts USING btree (contact_type_id);


--
-- Name: idx_fk_dataset_contacts_dataset_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dataset_contacts_dataset_id ON tbl_dataset_contacts USING btree (dataset_id);


--
-- Name: idx_fk_dataset_masters_biblio_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dataset_masters_biblio_id ON tbl_dataset_masters USING btree (biblio_id);


--
-- Name: idx_fk_dataset_masters_contact_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dataset_masters_contact_id ON tbl_dataset_masters USING btree (contact_id);


--
-- Name: idx_fk_dataset_submission_submission_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dataset_submission_submission_type_id ON tbl_dataset_submissions USING btree (submission_type_id);


--
-- Name: idx_fk_dataset_submissions_contact_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dataset_submissions_contact_id ON tbl_dataset_submissions USING btree (contact_id);


--
-- Name: idx_fk_dataset_submissions_dataset_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dataset_submissions_dataset_id ON tbl_dataset_submissions USING btree (dataset_id);


--
-- Name: idx_fk_datasets_biblio_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_datasets_biblio_id ON tbl_datasets USING btree (biblio_id);


--
-- Name: idx_fk_datasets_data_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_datasets_data_type_id ON tbl_datasets USING btree (data_type_id);


--
-- Name: idx_fk_datasets_master_set_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_datasets_master_set_id ON tbl_datasets USING btree (master_set_id);


--
-- Name: idx_fk_datasets_method_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_datasets_method_id ON tbl_datasets USING btree (method_id);


--
-- Name: idx_fk_datasets_project_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_datasets_project_id ON tbl_datasets USING btree (project_id);


--
-- Name: idx_fk_datasets_updated_dataset_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_datasets_updated_dataset_id ON tbl_datasets USING btree (updated_dataset_id);


--
-- Name: idx_fk_dating_labs_contact_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dating_labs_contact_id ON tbl_dating_labs USING btree (contact_id);


--
-- Name: idx_fk_dating_material_abundance_elements_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dating_material_abundance_elements_id ON tbl_dating_material USING btree (abundance_element_id);


--
-- Name: idx_fk_dating_material_geochronology_geochron_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dating_material_geochronology_geochron_id ON tbl_dating_material USING btree (geochron_id);


--
-- Name: idx_fk_dating_material_taxa_tree_master_taxon_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dating_material_taxa_tree_master_taxon_id ON tbl_dating_material USING btree (taxon_id);


--
-- Name: idx_fk_dendro_analysis_entity_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dendro_analysis_entity_id ON tbl_dendro USING btree (analysis_entity_id);


--
-- Name: idx_fk_dendro_date_notes_dendro_date_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dendro_date_notes_dendro_date_id ON tbl_dendro_date_notes USING btree (dendro_date_id);


--
-- Name: idx_fk_dendro_dates_analysis_entity_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dendro_dates_analysis_entity_id ON tbl_dendro_dates USING btree (analysis_entity_id);


--
-- Name: idx_fk_dendro_dates_dating_uncertainty_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dendro_dates_dating_uncertainty_id ON tbl_dendro_dates USING btree (dating_uncertainty_id);


--
-- Name: idx_fk_dendro_dates_years_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dendro_dates_years_type_id ON tbl_dendro_dates USING btree (years_type_id);


--
-- Name: idx_fk_dendro_dendro_measurement_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dendro_dendro_measurement_id ON tbl_dendro USING btree (dendro_measurement_id);


--
-- Name: idx_fk_dendro_measurement_lookup_dendro_measurement_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dendro_measurement_lookup_dendro_measurement_id ON tbl_dendro_measurement_lookup USING btree (dendro_measurement_id);


--
-- Name: idx_fk_dendro_measurements_method_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dendro_measurements_method_id ON tbl_dendro_measurements USING btree (method_id);


--
-- Name: idx_fk_dimensions_method_group_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dimensions_method_group_id ON tbl_dimensions USING btree (method_group_id);


--
-- Name: idx_fk_dimensions_unit_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_dimensions_unit_id ON tbl_dimensions USING btree (unit_id);


--
-- Name: idx_fk_ecocode_definitions_ecocode_group_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_ecocode_definitions_ecocode_group_id ON tbl_ecocode_definitions USING btree (ecocode_group_id);


--
-- Name: idx_fk_ecocode_groups_ecocode_system_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_ecocode_groups_ecocode_system_id ON tbl_ecocode_groups USING btree (ecocode_system_id);


--
-- Name: idx_fk_ecocode_systems_biblio_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_ecocode_systems_biblio_id ON tbl_ecocode_systems USING btree (biblio_id);


--
-- Name: idx_fk_ecocodes_ecocodedef_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_ecocodes_ecocodedef_id ON tbl_ecocodes USING btree (ecocode_definition_id);


--
-- Name: idx_fk_ecocodes_taxon_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_ecocodes_taxon_id ON tbl_ecocodes USING btree (taxon_id);


--
-- Name: idx_fk_feature_type_id_feature_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_feature_type_id_feature_type_id ON tbl_features USING btree (feature_type_id);


--
-- Name: idx_fk_geochron_refs_biblio_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_geochron_refs_biblio_id ON tbl_geochron_refs USING btree (biblio_id);


--
-- Name: idx_fk_geochron_refs_geochron_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_geochron_refs_geochron_id ON tbl_geochron_refs USING btree (geochron_id);


--
-- Name: idx_fk_geochronology_analysis_entity_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_geochronology_analysis_entity_id ON tbl_geochronology USING btree (analysis_entity_id);


--
-- Name: idx_fk_geochronology_dating_labs_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_geochronology_dating_labs_id ON tbl_geochronology USING btree (dating_lab_id);


--
-- Name: idx_fk_geochronology_dating_uncertainty_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_geochronology_dating_uncertainty_id ON tbl_geochronology USING btree (dating_uncertainty_id);


--
-- Name: idx_fk_horizons_method_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_horizons_method_id ON tbl_horizons USING btree (method_id);


--
-- Name: idx_fk_imported_taxa_replacements_taxon_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_imported_taxa_replacements_taxon_id ON tbl_imported_taxa_replacements USING btree (taxon_id);


--
-- Name: idx_fk_lithology_sample_group_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_lithology_sample_group_id ON tbl_lithology USING btree (sample_group_id);


--
-- Name: idx_fk_locations_location_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_locations_location_id ON tbl_site_locations USING btree (location_id);


--
-- Name: idx_fk_locations_location_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_locations_location_type_id ON tbl_locations USING btree (location_type_id);


--
-- Name: idx_fk_locations_site_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_locations_site_id ON tbl_site_locations USING btree (site_id);


--
-- Name: idx_fk_mcr_names_taxon_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_mcr_names_taxon_id ON tbl_mcr_names USING btree (taxon_id);


--
-- Name: idx_fk_mcr_summary_data_taxon_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_mcr_summary_data_taxon_id ON tbl_mcr_summary_data USING btree (taxon_id);


--
-- Name: idx_fk_mcrdata_birmbeetledat_taxon_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_mcrdata_birmbeetledat_taxon_id ON tbl_mcrdata_birmbeetledat USING btree (taxon_id);


--
-- Name: idx_fk_measured_value_dimensions_dimension_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_measured_value_dimensions_dimension_id ON tbl_measured_value_dimensions USING btree (dimension_id);


--
-- Name: idx_fk_measured_values_analysis_entity_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_measured_values_analysis_entity_id ON tbl_measured_values USING btree (analysis_entity_id);


--
-- Name: idx_fk_measured_weights_value_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_measured_weights_value_id ON tbl_measured_value_dimensions USING btree (measured_value_id);


--
-- Name: idx_fk_methods_biblio_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_methods_biblio_id ON tbl_methods USING btree (biblio_id);


--
-- Name: idx_fk_methods_method_group_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_methods_method_group_id ON tbl_methods USING btree (method_group_id);


--
-- Name: idx_fk_methods_record_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_methods_record_type_id ON tbl_methods USING btree (record_type_id);


--
-- Name: idx_fk_methods_unit_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_methods_unit_id ON tbl_methods USING btree (unit_id);


--
-- Name: idx_fk_physical_sample_features_feature_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_physical_sample_features_feature_id ON tbl_physical_sample_features USING btree (feature_id);


--
-- Name: idx_fk_physical_sample_features_physical_sample_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_physical_sample_features_physical_sample_id ON tbl_physical_sample_features USING btree (physical_sample_id);


--
-- Name: idx_fk_physical_samples_sample_name_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_physical_samples_sample_name_type_id ON tbl_physical_samples USING btree (alt_ref_type_id);


--
-- Name: idx_fk_physical_samples_sample_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_physical_samples_sample_type_id ON tbl_physical_samples USING btree (sample_type_id);


--
-- Name: idx_fk_projects_project_stage_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_projects_project_stage_id ON tbl_projects USING btree (project_stage_id);


--
-- Name: idx_fk_projects_project_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_projects_project_type_id ON tbl_projects USING btree (project_type_id);


--
-- Name: idx_fk_rdb_codes_rdb_system_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_rdb_codes_rdb_system_id ON tbl_rdb_codes USING btree (rdb_system_id);


--
-- Name: idx_fk_rdb_rdb_code_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_rdb_rdb_code_id ON tbl_rdb USING btree (rdb_code_id);


--
-- Name: idx_fk_rdb_systems_biblio_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_rdb_systems_biblio_id ON tbl_rdb_systems USING btree (biblio_id);


--
-- Name: idx_fk_rdb_systems_location_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_rdb_systems_location_id ON tbl_rdb_systems USING btree (location_id);


--
-- Name: idx_fk_rdb_taxon_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_rdb_taxon_id ON tbl_rdb USING btree (taxon_id);


--
-- Name: idx_fk_relative_age_refs_biblio_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_relative_age_refs_biblio_id ON tbl_relative_age_refs USING btree (biblio_id);


--
-- Name: idx_fk_relative_age_refs_relative_age_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_relative_age_refs_relative_age_id ON tbl_relative_age_refs USING btree (relative_age_id);


--
-- Name: idx_fk_relative_ages_location_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_relative_ages_location_id ON tbl_relative_ages USING btree (location_id);


--
-- Name: idx_fk_relative_ages_relative_age_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_relative_ages_relative_age_type_id ON tbl_relative_ages USING btree (relative_age_type_id);


--
-- Name: idx_fk_relative_dates_dating_uncertainty_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_relative_dates_dating_uncertainty_id ON tbl_relative_dates USING btree (dating_uncertainty_id);


--
-- Name: idx_fk_relative_dates_method_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_relative_dates_method_id ON tbl_relative_dates USING btree (method_id);


--
-- Name: idx_fk_relative_dates_physical_sample_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_relative_dates_physical_sample_id ON tbl_relative_dates USING btree (physical_sample_id);


--
-- Name: idx_fk_relative_dates_relative_age_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_relative_dates_relative_age_id ON tbl_relative_dates USING btree (relative_age_id);


--
-- Name: idx_fk_sample_alt_refs_alt_ref_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_alt_refs_alt_ref_type_id ON tbl_sample_alt_refs USING btree (alt_ref_type_id);


--
-- Name: idx_fk_sample_alt_refs_physical_sample_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_alt_refs_physical_sample_id ON tbl_sample_alt_refs USING btree (physical_sample_id);


--
-- Name: idx_fk_sample_colours_colour_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_colours_colour_id ON tbl_sample_colours USING btree (colour_id);


--
-- Name: idx_fk_sample_colours_physical_sample_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_colours_physical_sample_id ON tbl_sample_colours USING btree (physical_sample_id);


--
-- Name: idx_fk_sample_coordinates_coordinate_method_dimension_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_coordinates_coordinate_method_dimension_id ON tbl_sample_coordinates USING btree (coordinate_method_dimension_id);


--
-- Name: idx_fk_sample_coordinates_physical_sample_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_coordinates_physical_sample_id ON tbl_sample_coordinates USING btree (physical_sample_id);


--
-- Name: idx_fk_sample_description_sample_group_contexts_sampling_contex; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_description_sample_group_contexts_sampling_contex ON tbl_sample_description_sample_group_contexts USING btree (sampling_context_id);


--
-- Name: idx_fk_sample_description_types_sample_group_context_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_description_types_sample_group_context_id ON tbl_sample_description_sample_group_contexts USING btree (sample_description_type_id);


--
-- Name: idx_fk_sample_descriptions_physical_sample_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_descriptions_physical_sample_id ON tbl_sample_descriptions USING btree (physical_sample_id);


--
-- Name: idx_fk_sample_descriptions_sample_description_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_descriptions_sample_description_type_id ON tbl_sample_descriptions USING btree (sample_description_type_id);


--
-- Name: idx_fk_sample_dimensions_dimension_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_dimensions_dimension_id ON tbl_sample_dimensions USING btree (dimension_id);


--
-- Name: idx_fk_sample_dimensions_measurement_method_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_dimensions_measurement_method_id ON tbl_sample_dimensions USING btree (method_id);


--
-- Name: idx_fk_sample_dimensions_physical_sample_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_dimensions_physical_sample_id ON tbl_sample_dimensions USING btree (physical_sample_id);


--
-- Name: idx_fk_sample_group_description_type_sampling_context_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_group_description_type_sampling_context_id ON tbl_sample_group_description_type_sampling_contexts USING btree (sample_group_description_type_id);


--
-- Name: idx_fk_sample_group_descriptions_sample_group_description_type_; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_group_descriptions_sample_group_description_type_ ON tbl_sample_group_descriptions USING btree (sample_group_description_type_id);


--
-- Name: idx_fk_sample_group_dimensions_dimension_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_group_dimensions_dimension_id ON tbl_sample_group_dimensions USING btree (dimension_id);


--
-- Name: idx_fk_sample_group_dimensions_sample_group_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_group_dimensions_sample_group_id ON tbl_sample_group_dimensions USING btree (sample_group_id);


--
-- Name: idx_fk_sample_group_images_image_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_group_images_image_type_id ON tbl_sample_group_images USING btree (image_type_id);


--
-- Name: idx_fk_sample_group_images_sample_group_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_group_images_sample_group_id ON tbl_sample_group_images USING btree (sample_group_id);


--
-- Name: idx_fk_sample_group_positions_coordinate_method_dimension_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_group_positions_coordinate_method_dimension_id ON tbl_sample_group_coordinates USING btree (coordinate_method_dimension_id);


--
-- Name: idx_fk_sample_group_positions_sample_group_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_group_positions_sample_group_id ON tbl_sample_group_coordinates USING btree (sample_group_id);


--
-- Name: idx_fk_sample_group_references_biblio_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_group_references_biblio_id ON tbl_sample_group_references USING btree (biblio_id);


--
-- Name: idx_fk_sample_group_references_sample_group_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_group_references_sample_group_id ON tbl_sample_group_references USING btree (sample_group_id);


--
-- Name: idx_fk_sample_group_sampling_context_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_group_sampling_context_id ON tbl_sample_groups USING btree (sampling_context_id);


--
-- Name: idx_fk_sample_group_sampling_context_id0; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_group_sampling_context_id0 ON tbl_sample_group_description_type_sampling_contexts USING btree (sampling_context_id);


--
-- Name: idx_fk_sample_groups_method_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_groups_method_id ON tbl_sample_groups USING btree (method_id);


--
-- Name: idx_fk_sample_groups_sample_group_descriptions_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_groups_sample_group_descriptions_id ON tbl_sample_group_descriptions USING btree (sample_group_id);


--
-- Name: idx_fk_sample_groups_site_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_groups_site_id ON tbl_sample_groups USING btree (site_id);


--
-- Name: idx_fk_sample_horizons_horizon_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_horizons_horizon_id ON tbl_sample_horizons USING btree (horizon_id);


--
-- Name: idx_fk_sample_horizons_physical_sample_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_horizons_physical_sample_id ON tbl_sample_horizons USING btree (physical_sample_id);


--
-- Name: idx_fk_sample_images_image_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_images_image_type_id ON tbl_sample_images USING btree (image_type_id);


--
-- Name: idx_fk_sample_images_physical_sample_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_images_physical_sample_id ON tbl_sample_images USING btree (physical_sample_id);


--
-- Name: idx_fk_sample_location_sampling_contexts_sampling_context_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_location_sampling_contexts_sampling_context_id ON tbl_sample_location_type_sampling_contexts USING btree (sample_location_type_id);


--
-- Name: idx_fk_sample_location_type_sampling_context_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_location_type_sampling_context_id ON tbl_sample_location_type_sampling_contexts USING btree (sampling_context_id);


--
-- Name: idx_fk_sample_locations_physical_sample_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_locations_physical_sample_id ON tbl_sample_locations USING btree (physical_sample_id);


--
-- Name: idx_fk_sample_locations_sample_location_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_locations_sample_location_type_id ON tbl_sample_locations USING btree (sample_location_type_id);


--
-- Name: idx_fk_sample_notes_physical_sample_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_sample_notes_physical_sample_id ON tbl_sample_notes USING btree (physical_sample_id);


--
-- Name: idx_fk_samples_sample_group_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_samples_sample_group_id ON tbl_physical_samples USING btree (sample_group_id);


--
-- Name: idx_fk_seasons_season_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_seasons_season_type_id ON tbl_seasons USING btree (season_type_id);


--
-- Name: idx_fk_site_images_contact_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_site_images_contact_id ON tbl_site_images USING btree (contact_id);


--
-- Name: idx_fk_site_images_image_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_site_images_image_type_id ON tbl_site_images USING btree (image_type_id);


--
-- Name: idx_fk_site_images_site_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_site_images_site_id ON tbl_site_images USING btree (site_id);


--
-- Name: idx_fk_site_natgridrefs_method_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_site_natgridrefs_method_id ON tbl_site_natgridrefs USING btree (method_id);


--
-- Name: idx_fk_site_natgridrefs_sites_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_site_natgridrefs_sites_id ON tbl_site_natgridrefs USING btree (site_id);


--
-- Name: idx_fk_site_other_records_biblio_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_site_other_records_biblio_id ON tbl_site_other_records USING btree (biblio_id);


--
-- Name: idx_fk_site_other_records_record_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_site_other_records_record_type_id ON tbl_site_other_records USING btree (record_type_id);


--
-- Name: idx_fk_site_other_records_site_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_site_other_records_site_id ON tbl_site_other_records USING btree (site_id);


--
-- Name: idx_fk_site_preservation_status_site_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_site_preservation_status_site_id ON tbl_site_preservation_status USING btree (site_id);


--
-- Name: idx_fk_site_references_biblio_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_site_references_biblio_id ON tbl_site_references USING btree (biblio_id);


--
-- Name: idx_fk_site_references_site_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_site_references_site_id ON tbl_site_references USING btree (site_id);


--
-- Name: idx_fk_species_associations_associated_taxon_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_species_associations_associated_taxon_id ON tbl_species_associations USING btree (taxon_id);


--
-- Name: idx_fk_species_associations_association_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_species_associations_association_type_id ON tbl_species_associations USING btree (association_type_id);


--
-- Name: idx_fk_species_associations_biblio_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_species_associations_biblio_id ON tbl_species_associations USING btree (biblio_id);


--
-- Name: idx_fk_species_associations_taxon_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_species_associations_taxon_id ON tbl_species_associations USING btree (taxon_id);


--
-- Name: idx_fk_taxa_common_names_language_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxa_common_names_language_id ON tbl_taxa_common_names USING btree (language_id);


--
-- Name: idx_fk_taxa_common_names_taxon_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxa_common_names_taxon_id ON tbl_taxa_common_names USING btree (taxon_id);


--
-- Name: idx_fk_taxa_images_image_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxa_images_image_type_id ON tbl_taxa_images USING btree (image_type_id);


--
-- Name: idx_fk_taxa_images_taxa_tree_master_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxa_images_taxa_tree_master_id ON tbl_taxa_images USING btree (taxon_id);


--
-- Name: idx_fk_taxa_measured_attributes_taxon_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxa_measured_attributes_taxon_id ON tbl_taxa_measured_attributes USING btree (taxon_id);


--
-- Name: idx_fk_taxa_reference_specimens_contact_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxa_reference_specimens_contact_id ON tbl_taxa_reference_specimens USING btree (contact_id);


--
-- Name: idx_fk_taxa_reference_specimens_taxon_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxa_reference_specimens_taxon_id ON tbl_taxa_reference_specimens USING btree (taxon_id);


--
-- Name: idx_fk_taxa_seasonality_activity_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxa_seasonality_activity_type_id ON tbl_taxa_seasonality USING btree (activity_type_id);


--
-- Name: idx_fk_taxa_seasonality_location_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxa_seasonality_location_id ON tbl_taxa_seasonality USING btree (location_id);


--
-- Name: idx_fk_taxa_seasonality_season_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxa_seasonality_season_id ON tbl_taxa_seasonality USING btree (season_id);


--
-- Name: idx_fk_taxa_seasonality_taxon_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxa_seasonality_taxon_id ON tbl_taxa_seasonality USING btree (taxon_id);


--
-- Name: idx_fk_taxa_synonyms_biblio_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxa_synonyms_biblio_id ON tbl_taxa_synonyms USING btree (biblio_id);


--
-- Name: idx_fk_taxa_synonyms_family_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxa_synonyms_family_id ON tbl_taxa_synonyms USING btree (family_id);


--
-- Name: idx_fk_taxa_synonyms_genus_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxa_synonyms_genus_id ON tbl_taxa_synonyms USING btree (genus_id);


--
-- Name: idx_fk_taxa_synonyms_taxa_tree_author_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxa_synonyms_taxa_tree_author_id ON tbl_taxa_synonyms USING btree (author_id);


--
-- Name: idx_fk_taxa_synonyms_taxon_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxa_synonyms_taxon_id ON tbl_taxa_synonyms USING btree (taxon_id);


--
-- Name: idx_fk_taxa_tree_families_order_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxa_tree_families_order_id ON tbl_taxa_tree_families USING btree (order_id);


--
-- Name: idx_fk_taxa_tree_genera_family_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxa_tree_genera_family_id ON tbl_taxa_tree_genera USING btree (family_id);


--
-- Name: idx_fk_taxa_tree_master_author_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxa_tree_master_author_id ON tbl_taxa_tree_master USING btree (author_id);


--
-- Name: idx_fk_taxa_tree_master_genus_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxa_tree_master_genus_id ON tbl_taxa_tree_master USING btree (genus_id);


--
-- Name: idx_fk_taxa_tree_orders_record_type_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxa_tree_orders_record_type_id ON tbl_taxa_tree_orders USING btree (record_type_id);


--
-- Name: idx_fk_taxonomic_order_biblio_biblio_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxonomic_order_biblio_biblio_id ON tbl_taxonomic_order_biblio USING btree (biblio_id);


--
-- Name: idx_fk_taxonomic_order_biblio_taxonomic_order_system_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxonomic_order_biblio_taxonomic_order_system_id ON tbl_taxonomic_order_biblio USING btree (taxonomic_order_system_id);


--
-- Name: idx_fk_taxonomic_order_taxon_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxonomic_order_taxon_id ON tbl_taxonomic_order USING btree (taxon_id);


--
-- Name: idx_fk_taxonomic_order_taxonomic_order_system_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxonomic_order_taxonomic_order_system_id ON tbl_taxonomic_order USING btree (taxonomic_order_system_id);


--
-- Name: idx_fk_taxonomy_notes_biblio_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxonomy_notes_biblio_id ON tbl_taxonomy_notes USING btree (biblio_id);


--
-- Name: idx_fk_taxonomy_notes_taxon_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_taxonomy_notes_taxon_id ON tbl_taxonomy_notes USING btree (taxon_id);


--
-- Name: idx_fk_tbl_rdb_tbl_location_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_tbl_rdb_tbl_location_id ON tbl_rdb USING btree (location_id);


--
-- Name: idx_fk_tbl_sample_group_notes_sample_groups; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_tbl_sample_group_notes_sample_groups ON tbl_sample_group_notes USING btree (sample_group_id);


--
-- Name: idx_fk_tephra_dates_analysis_entity_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_tephra_dates_analysis_entity_id ON tbl_tephra_dates USING btree (analysis_entity_id);


--
-- Name: idx_fk_tephra_dates_dating_uncertainty_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_tephra_dates_dating_uncertainty_id ON tbl_tephra_dates USING btree (dating_uncertainty_id);


--
-- Name: idx_fk_tephra_dates_tephra_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_tephra_dates_tephra_id ON tbl_tephra_dates USING btree (tephra_id);


--
-- Name: idx_fk_tephra_refs_biblio_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_tephra_refs_biblio_id ON tbl_tephra_refs USING btree (biblio_id);


--
-- Name: idx_fk_tephra_refs_tephra_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_tephra_refs_tephra_id ON tbl_tephra_refs USING btree (tephra_id);


--
-- Name: idx_fk_text_biology_biblio_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_text_biology_biblio_id ON tbl_text_biology USING btree (biblio_id);


--
-- Name: idx_fk_text_biology_taxon_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_text_biology_taxon_id ON tbl_text_biology USING btree (taxon_id);


--
-- Name: idx_fk_text_distribution_biblio_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_text_distribution_biblio_id ON tbl_text_distribution USING btree (biblio_id);


--
-- Name: idx_fk_text_distribution_taxon_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_text_distribution_taxon_id ON tbl_text_distribution USING btree (taxon_id);


--
-- Name: idx_fk_text_identification_keys_biblio_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_text_identification_keys_biblio_id ON tbl_text_identification_keys USING btree (biblio_id);


--
-- Name: idx_fk_text_identification_keys_taxon_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_fk_text_identification_keys_taxon_id ON tbl_text_identification_keys USING btree (taxon_id);


--
-- Name: idx_sead_rdb_schema; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_sead_rdb_schema ON tbl_clearinghouse_sead_rdb_schema USING btree (table_name, column_name);


--
-- Name: idx_tbl_clearinghouse_settings_group; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE INDEX idx_tbl_clearinghouse_settings_group ON tbl_clearinghouse_settings USING btree (setting_group);


--
-- Name: idx_tbl_clearinghouse_settings_key; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE UNIQUE INDEX idx_tbl_clearinghouse_settings_key ON tbl_clearinghouse_settings USING btree (setting_key);


--
-- Name: idx_tbl_clearinghouse_submission_tables_name1; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE UNIQUE INDEX idx_tbl_clearinghouse_submission_tables_name1 ON tbl_clearinghouse_submission_tables USING btree (table_name);


--
-- Name: idx_tbl_clearinghouse_submission_tables_name2; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE UNIQUE INDEX idx_tbl_clearinghouse_submission_tables_name2 ON tbl_clearinghouse_submission_tables USING btree (table_name_underscored);


--
-- Name: idx_tbl_submission_xml_content_columns_submission_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE UNIQUE INDEX idx_tbl_submission_xml_content_columns_submission_id ON tbl_clearinghouse_submission_xml_content_columns USING btree (submission_id, table_id, column_name);


--
-- Name: idx_tbl_submission_xml_content_record_values_column_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE UNIQUE INDEX idx_tbl_submission_xml_content_record_values_column_id ON tbl_clearinghouse_submission_xml_content_values USING btree (submission_id, table_id, local_db_id, column_id);


--
-- Name: idx_tbl_submission_xml_content_records_submission_id; Type: INDEX; Schema: clearing_house; Owner: -
--

CREATE UNIQUE INDEX idx_tbl_submission_xml_content_records_submission_id ON tbl_clearinghouse_submission_xml_content_records USING btree (submission_id, table_id, local_db_id);


SET search_path = metainformation, pg_catalog;

--
-- Name: physiscal_sample_id_index; Type: INDEX; Schema: metainformation; Owner: -
--

CREATE INDEX physiscal_sample_id_index ON tbl_denormalized_measured_values USING btree (physical_sample_id);


SET search_path = public, pg_catalog;

--
-- Name: idx_biblio_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_biblio_id ON tbl_sample_group_references USING btree (biblio_id);


--
-- Name: idx_sample_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sample_group_id ON tbl_sample_group_references USING btree (sample_group_id);


--
-- Name: tbl_ecocode_groups_idx_ecocodesystemid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tbl_ecocode_groups_idx_ecocodesystemid ON tbl_ecocode_groups USING btree (ecocode_system_id);


--
-- Name: tbl_ecocode_groups_idx_label; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tbl_ecocode_groups_idx_label ON tbl_ecocode_groups USING btree (name);


--
-- Name: tbl_ecocode_systems_biblioid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tbl_ecocode_systems_biblioid ON tbl_ecocode_systems USING btree (biblio_id);


--
-- Name: tbl_ecocode_systems_ecocodegroupid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tbl_ecocode_systems_ecocodegroupid ON tbl_ecocode_systems USING btree (name);


--
-- Name: tbl_languages_language_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tbl_languages_language_id ON tbl_languages USING btree (language_id);


--
-- Name: tbl_taxa_tree_authors_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tbl_taxa_tree_authors_name ON tbl_taxa_tree_authors USING btree (author_name);


--
-- Name: tbl_taxa_tree_families_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tbl_taxa_tree_families_name ON tbl_taxa_tree_families USING btree (family_name);


--
-- Name: tbl_taxa_tree_families_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tbl_taxa_tree_families_order_id ON tbl_taxa_tree_families USING btree (order_id);


--
-- Name: tbl_taxa_tree_genera_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tbl_taxa_tree_genera_family_id ON tbl_taxa_tree_genera USING btree (family_id);


--
-- Name: tbl_taxa_tree_genera_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tbl_taxa_tree_genera_name ON tbl_taxa_tree_genera USING btree (genus_name);


--
-- Name: tbl_taxa_tree_orders_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tbl_taxa_tree_orders_order_id ON tbl_taxa_tree_orders USING btree (order_id);


--
-- Name: tbl_taxonomic_order_biblio_biblio_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tbl_taxonomic_order_biblio_biblio_id ON tbl_taxonomic_order_biblio USING btree (biblio_id);


--
-- Name: tbl_taxonomic_order_biblio_taxonomic_order_biblio_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tbl_taxonomic_order_biblio_taxonomic_order_biblio_id ON tbl_taxonomic_order_biblio USING btree (taxonomic_order_biblio_id);


--
-- Name: tbl_taxonomic_order_biblio_taxonomic_order_system_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tbl_taxonomic_order_biblio_taxonomic_order_system_id ON tbl_taxonomic_order_biblio USING btree (taxonomic_order_system_id);


--
-- Name: tbl_taxonomic_order_systems_taxonomic_system_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tbl_taxonomic_order_systems_taxonomic_system_id ON tbl_taxonomic_order_systems USING btree (taxonomic_order_system_id);


--
-- Name: tbl_taxonomic_order_taxon_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tbl_taxonomic_order_taxon_id ON tbl_taxonomic_order USING btree (taxon_id);


--
-- Name: tbl_taxonomic_order_taxonomic_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tbl_taxonomic_order_taxonomic_code ON tbl_taxonomic_order USING btree (taxonomic_code);


--
-- Name: tbl_taxonomic_order_taxonomic_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tbl_taxonomic_order_taxonomic_order_id ON tbl_taxonomic_order USING btree (taxonomic_order_id);


--
-- Name: tbl_taxonomic_order_taxonomic_system_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tbl_taxonomic_order_taxonomic_system_id ON tbl_taxonomic_order USING btree (taxonomic_order_system_id);


SET search_path = clearing_house, pg_catalog;

--
-- Name: tbl_clearinghouse_submission_reject_entities fk_tbl_clearinghouse_submission_reject_entities; Type: FK CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submission_reject_entities
    ADD CONSTRAINT fk_tbl_clearinghouse_submission_reject_entities FOREIGN KEY (submission_reject_id) REFERENCES tbl_clearinghouse_submission_rejects(submission_reject_id) ON DELETE CASCADE;


--
-- Name: tbl_clearinghouse_submission_rejects fk_tbl_clearinghouse_submission_rejects_submission_id; Type: FK CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submission_rejects
    ADD CONSTRAINT fk_tbl_clearinghouse_submission_rejects_submission_id FOREIGN KEY (submission_id) REFERENCES tbl_clearinghouse_submissions(submission_id) ON DELETE CASCADE;


--
-- Name: tbl_clearinghouse_submission_xml_content_tables fk_tbl_clearinghouse_submission_xml_content_tables; Type: FK CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submission_xml_content_tables
    ADD CONSTRAINT fk_tbl_clearinghouse_submission_xml_content_tables FOREIGN KEY (table_id) REFERENCES tbl_clearinghouse_submission_tables(table_id) ON DELETE CASCADE;


--
-- Name: tbl_clearinghouse_users fk_tbl_data_provider_grades_grade_id; Type: FK CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_users
    ADD CONSTRAINT fk_tbl_data_provider_grades_grade_id FOREIGN KEY (data_provider_grade_id) REFERENCES tbl_clearinghouse_data_provider_grades(grade_id);


--
-- Name: tbl_clearinghouse_submission_xml_content_columns fk_tbl_submission_xml_content_columns_table_id; Type: FK CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submission_xml_content_columns
    ADD CONSTRAINT fk_tbl_submission_xml_content_columns_table_id FOREIGN KEY (table_id) REFERENCES tbl_clearinghouse_submission_tables(table_id) ON DELETE CASCADE;


--
-- Name: tbl_clearinghouse_submission_xml_content_values fk_tbl_submission_xml_content_meta_record_values_table_id; Type: FK CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submission_xml_content_values
    ADD CONSTRAINT fk_tbl_submission_xml_content_meta_record_values_table_id FOREIGN KEY (table_id) REFERENCES tbl_clearinghouse_submission_tables(table_id) ON DELETE CASCADE;


--
-- Name: tbl_clearinghouse_submission_xml_content_records fk_tbl_submission_xml_content_records_table_id; Type: FK CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submission_xml_content_records
    ADD CONSTRAINT fk_tbl_submission_xml_content_records_table_id FOREIGN KEY (table_id) REFERENCES tbl_clearinghouse_submission_tables(table_id) ON DELETE CASCADE;


--
-- Name: tbl_clearinghouse_submissions fk_tbl_submissions_state_id_state_id; Type: FK CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submissions
    ADD CONSTRAINT fk_tbl_submissions_state_id_state_id FOREIGN KEY (submission_state_id) REFERENCES tbl_clearinghouse_submission_states(submission_state_id);


--
-- Name: tbl_clearinghouse_submissions fk_tbl_submissions_user_id_user_id; Type: FK CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_submissions
    ADD CONSTRAINT fk_tbl_submissions_user_id_user_id FOREIGN KEY (claim_user_id) REFERENCES tbl_clearinghouse_users(user_id);


--
-- Name: tbl_clearinghouse_users fk_tbl_user_roles_role_id; Type: FK CONSTRAINT; Schema: clearing_house; Owner: -
--

ALTER TABLE ONLY tbl_clearinghouse_users
    ADD CONSTRAINT fk_tbl_user_roles_role_id FOREIGN KEY (role_id) REFERENCES tbl_clearinghouse_user_roles(role_id);


SET search_path = public, pg_catalog;

--
-- Name: tbl_abundance_elements fk_abundance_elements_record_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_abundance_elements
    ADD CONSTRAINT fk_abundance_elements_record_type_id FOREIGN KEY (record_type_id) REFERENCES tbl_record_types(record_type_id) ON UPDATE CASCADE;


--
-- Name: tbl_abundance_ident_levels fk_abundance_ident_levels_abundance_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_abundance_ident_levels
    ADD CONSTRAINT fk_abundance_ident_levels_abundance_id FOREIGN KEY (abundance_id) REFERENCES tbl_abundances(abundance_id);


--
-- Name: tbl_abundance_ident_levels fk_abundance_ident_levels_identification_level_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_abundance_ident_levels
    ADD CONSTRAINT fk_abundance_ident_levels_identification_level_id FOREIGN KEY (identification_level_id) REFERENCES tbl_identification_levels(identification_level_id) ON UPDATE CASCADE;


--
-- Name: tbl_abundance_modifications fk_abundance_modifications_abundance_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_abundance_modifications
    ADD CONSTRAINT fk_abundance_modifications_abundance_id FOREIGN KEY (abundance_id) REFERENCES tbl_abundances(abundance_id) ON UPDATE CASCADE;


--
-- Name: tbl_abundance_modifications fk_abundance_modifications_modification_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_abundance_modifications
    ADD CONSTRAINT fk_abundance_modifications_modification_type_id FOREIGN KEY (modification_type_id) REFERENCES tbl_modification_types(modification_type_id) ON UPDATE CASCADE;


--
-- Name: tbl_abundances fk_abundances_abundance_elements_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_abundances
    ADD CONSTRAINT fk_abundances_abundance_elements_id FOREIGN KEY (abundance_element_id) REFERENCES tbl_abundance_elements(abundance_element_id) ON UPDATE CASCADE;


--
-- Name: tbl_abundances fk_abundances_analysis_entity_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_abundances
    ADD CONSTRAINT fk_abundances_analysis_entity_id FOREIGN KEY (analysis_entity_id) REFERENCES tbl_analysis_entities(analysis_entity_id) ON UPDATE CASCADE;


--
-- Name: tbl_abundances fk_abundances_taxon_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_abundances
    ADD CONSTRAINT fk_abundances_taxon_id FOREIGN KEY (taxon_id) REFERENCES tbl_taxa_tree_master(taxon_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tbl_aggregate_samples fk_aggragate_samples_analysis_entity_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_aggregate_samples
    ADD CONSTRAINT fk_aggragate_samples_analysis_entity_id FOREIGN KEY (analysis_entity_id) REFERENCES tbl_analysis_entities(analysis_entity_id) ON UPDATE CASCADE;


--
-- Name: tbl_aggregate_datasets fk_aggregate_datasets_aggregate_order_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_aggregate_datasets
    ADD CONSTRAINT fk_aggregate_datasets_aggregate_order_type_id FOREIGN KEY (aggregate_order_type_id) REFERENCES tbl_aggregate_order_types(aggregate_order_type_id) ON UPDATE CASCADE;


--
-- Name: tbl_aggregate_datasets fk_aggregate_datasets_biblio_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_aggregate_datasets
    ADD CONSTRAINT fk_aggregate_datasets_biblio_id FOREIGN KEY (biblio_id) REFERENCES tbl_biblio(biblio_id) ON UPDATE CASCADE;


--
-- Name: tbl_aggregate_sample_ages fk_aggregate_sample_ages_aggregate_dataset_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_aggregate_sample_ages
    ADD CONSTRAINT fk_aggregate_sample_ages_aggregate_dataset_id FOREIGN KEY (aggregate_dataset_id) REFERENCES tbl_aggregate_datasets(aggregate_dataset_id) ON UPDATE CASCADE;


--
-- Name: tbl_aggregate_sample_ages fk_aggregate_sample_ages_analysis_entity_age_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_aggregate_sample_ages
    ADD CONSTRAINT fk_aggregate_sample_ages_analysis_entity_age_id FOREIGN KEY (analysis_entity_age_id) REFERENCES tbl_analysis_entity_ages(analysis_entity_age_id) ON UPDATE CASCADE;


--
-- Name: tbl_aggregate_samples fk_aggregate_samples_aggregate_dataset_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_aggregate_samples
    ADD CONSTRAINT fk_aggregate_samples_aggregate_dataset_id FOREIGN KEY (aggregate_dataset_id) REFERENCES tbl_aggregate_datasets(aggregate_dataset_id) ON UPDATE CASCADE;


--
-- Name: tbl_analysis_entities fk_analysis_entities_dataset_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_analysis_entities
    ADD CONSTRAINT fk_analysis_entities_dataset_id FOREIGN KEY (dataset_id) REFERENCES tbl_datasets(dataset_id) ON UPDATE CASCADE;


--
-- Name: tbl_analysis_entities fk_analysis_entities_physical_sample_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_analysis_entities
    ADD CONSTRAINT fk_analysis_entities_physical_sample_id FOREIGN KEY (physical_sample_id) REFERENCES tbl_physical_samples(physical_sample_id);


--
-- Name: tbl_analysis_entity_ages fk_analysis_entity_ages_analysis_entity_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_analysis_entity_ages
    ADD CONSTRAINT fk_analysis_entity_ages_analysis_entity_id FOREIGN KEY (analysis_entity_id) REFERENCES tbl_analysis_entities(analysis_entity_id) ON UPDATE CASCADE;


--
-- Name: tbl_analysis_entity_ages fk_analysis_entity_ages_chronology_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_analysis_entity_ages
    ADD CONSTRAINT fk_analysis_entity_ages_chronology_id FOREIGN KEY (chronology_id) REFERENCES tbl_chronologies(chronology_id) ON UPDATE CASCADE;


--
-- Name: tbl_analysis_entity_dimensions fk_analysis_entity_dimensions_analysis_entity_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_analysis_entity_dimensions
    ADD CONSTRAINT fk_analysis_entity_dimensions_analysis_entity_id FOREIGN KEY (analysis_entity_id) REFERENCES tbl_analysis_entities(analysis_entity_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tbl_analysis_entity_dimensions fk_analysis_entity_dimensions_dimension_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_analysis_entity_dimensions
    ADD CONSTRAINT fk_analysis_entity_dimensions_dimension_id FOREIGN KEY (dimension_id) REFERENCES tbl_dimensions(dimension_id) ON UPDATE CASCADE;


--
-- Name: tbl_analysis_entity_prep_methods fk_analysis_entity_prep_methods_analysis_entity_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_analysis_entity_prep_methods
    ADD CONSTRAINT fk_analysis_entity_prep_methods_analysis_entity_id FOREIGN KEY (analysis_entity_id) REFERENCES tbl_analysis_entities(analysis_entity_id);


--
-- Name: tbl_analysis_entity_prep_methods fk_analysis_entity_prep_methods_method_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_analysis_entity_prep_methods
    ADD CONSTRAINT fk_analysis_entity_prep_methods_method_id FOREIGN KEY (method_id) REFERENCES tbl_methods(method_id);


--
-- Name: tbl_biblio fk_biblio_collections_or_journals_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_biblio
    ADD CONSTRAINT fk_biblio_collections_or_journals_id FOREIGN KEY (collection_or_journal_id) REFERENCES tbl_collections_or_journals(collection_or_journal_id) ON UPDATE CASCADE;


--
-- Name: tbl_biblio_keywords fk_biblio_keywords_biblio_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_biblio_keywords
    ADD CONSTRAINT fk_biblio_keywords_biblio_id FOREIGN KEY (biblio_id) REFERENCES tbl_biblio(biblio_id) ON UPDATE CASCADE;


--
-- Name: tbl_biblio_keywords fk_biblio_keywords_keyword_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_biblio_keywords
    ADD CONSTRAINT fk_biblio_keywords_keyword_id FOREIGN KEY (keyword_id) REFERENCES tbl_keywords(keyword_id) ON UPDATE CASCADE;


--
-- Name: tbl_biblio fk_biblio_publication_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_biblio
    ADD CONSTRAINT fk_biblio_publication_type_id FOREIGN KEY (publication_type_id) REFERENCES tbl_publication_types(publication_type_id) ON UPDATE CASCADE;


--
-- Name: tbl_biblio fk_biblio_publisher_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_biblio
    ADD CONSTRAINT fk_biblio_publisher_id FOREIGN KEY (publisher_id) REFERENCES tbl_publishers(publisher_id) ON UPDATE CASCADE;


--
-- Name: tbl_ceramics fk_ceramics_analysis_entity_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ceramics
    ADD CONSTRAINT fk_ceramics_analysis_entity_id FOREIGN KEY (analysis_entity_id) REFERENCES tbl_analysis_entities(analysis_entity_id);


--
-- Name: tbl_ceramics fk_ceramics_ceramics_measurement_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ceramics
    ADD CONSTRAINT fk_ceramics_ceramics_measurement_id FOREIGN KEY (ceramics_measurement_id) REFERENCES tbl_ceramics_measurements(ceramics_measurement_id);


--
-- Name: tbl_ceramics_measurement_lookup fk_ceramics_measurement_lookup_ceramics_measurements_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ceramics_measurement_lookup
    ADD CONSTRAINT fk_ceramics_measurement_lookup_ceramics_measurements_id FOREIGN KEY (ceramics_measurement_id) REFERENCES tbl_ceramics_measurements(ceramics_measurement_id);


--
-- Name: tbl_ceramics_measurements fk_ceramics_measurements_method_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ceramics_measurements
    ADD CONSTRAINT fk_ceramics_measurements_method_id FOREIGN KEY (method_id) REFERENCES tbl_methods(method_id);


--
-- Name: tbl_chron_controls fk_chron_controls_chron_control_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_chron_controls
    ADD CONSTRAINT fk_chron_controls_chron_control_type_id FOREIGN KEY (chron_control_type_id) REFERENCES tbl_chron_control_types(chron_control_type_id) ON UPDATE CASCADE;


--
-- Name: tbl_chron_controls fk_chron_controls_chronology_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_chron_controls
    ADD CONSTRAINT fk_chron_controls_chronology_id FOREIGN KEY (chronology_id) REFERENCES tbl_chronologies(chronology_id) ON UPDATE CASCADE;


--
-- Name: tbl_chronologies fk_chronologies_contact_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_chronologies
    ADD CONSTRAINT fk_chronologies_contact_id FOREIGN KEY (contact_id) REFERENCES tbl_contacts(contact_id) ON UPDATE CASCADE;


--
-- Name: tbl_chronologies fk_chronologies_sample_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_chronologies
    ADD CONSTRAINT fk_chronologies_sample_group_id FOREIGN KEY (sample_group_id) REFERENCES tbl_sample_groups(sample_group_id) ON UPDATE CASCADE;


--
-- Name: tbl_collections_or_journals fk_collections_or_journals_publisher_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_collections_or_journals
    ADD CONSTRAINT fk_collections_or_journals_publisher_id FOREIGN KEY (publisher_id) REFERENCES tbl_publishers(publisher_id) ON UPDATE CASCADE;


--
-- Name: tbl_colours fk_colours_method_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_colours
    ADD CONSTRAINT fk_colours_method_id FOREIGN KEY (method_id) REFERENCES tbl_methods(method_id) ON UPDATE CASCADE;


--
-- Name: tbl_coordinate_method_dimensions fk_coordinate_method_dimensions_dimensions_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_coordinate_method_dimensions
    ADD CONSTRAINT fk_coordinate_method_dimensions_dimensions_id FOREIGN KEY (dimension_id) REFERENCES tbl_dimensions(dimension_id) ON UPDATE CASCADE;


--
-- Name: tbl_coordinate_method_dimensions fk_coordinate_method_dimensions_method_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_coordinate_method_dimensions
    ADD CONSTRAINT fk_coordinate_method_dimensions_method_id FOREIGN KEY (method_id) REFERENCES tbl_methods(method_id) ON UPDATE CASCADE;


--
-- Name: tbl_data_types fk_data_types_data_type_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_data_types
    ADD CONSTRAINT fk_data_types_data_type_group_id FOREIGN KEY (data_type_group_id) REFERENCES tbl_data_type_groups(data_type_group_id) ON UPDATE CASCADE;


--
-- Name: tbl_dataset_contacts fk_dataset_contacts_contact_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dataset_contacts
    ADD CONSTRAINT fk_dataset_contacts_contact_id FOREIGN KEY (contact_id) REFERENCES tbl_contacts(contact_id) ON UPDATE CASCADE;


--
-- Name: tbl_dataset_contacts fk_dataset_contacts_contact_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dataset_contacts
    ADD CONSTRAINT fk_dataset_contacts_contact_type_id FOREIGN KEY (contact_type_id) REFERENCES tbl_contact_types(contact_type_id) ON UPDATE CASCADE;


--
-- Name: tbl_dataset_contacts fk_dataset_contacts_dataset_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dataset_contacts
    ADD CONSTRAINT fk_dataset_contacts_dataset_id FOREIGN KEY (dataset_id) REFERENCES tbl_datasets(dataset_id) ON UPDATE CASCADE;


--
-- Name: tbl_dataset_masters fk_dataset_masters_biblio_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dataset_masters
    ADD CONSTRAINT fk_dataset_masters_biblio_id FOREIGN KEY (biblio_id) REFERENCES tbl_biblio(biblio_id);


--
-- Name: tbl_dataset_masters fk_dataset_masters_contact_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dataset_masters
    ADD CONSTRAINT fk_dataset_masters_contact_id FOREIGN KEY (contact_id) REFERENCES tbl_contacts(contact_id) ON UPDATE CASCADE;


--
-- Name: tbl_dataset_submissions fk_dataset_submission_submission_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dataset_submissions
    ADD CONSTRAINT fk_dataset_submission_submission_type_id FOREIGN KEY (submission_type_id) REFERENCES tbl_dataset_submission_types(submission_type_id) ON UPDATE CASCADE;


--
-- Name: tbl_dataset_submissions fk_dataset_submissions_contact_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dataset_submissions
    ADD CONSTRAINT fk_dataset_submissions_contact_id FOREIGN KEY (contact_id) REFERENCES tbl_contacts(contact_id) ON UPDATE CASCADE;


--
-- Name: tbl_dataset_submissions fk_dataset_submissions_dataset_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dataset_submissions
    ADD CONSTRAINT fk_dataset_submissions_dataset_id FOREIGN KEY (dataset_id) REFERENCES tbl_datasets(dataset_id) ON UPDATE CASCADE;


--
-- Name: tbl_datasets fk_datasets_biblio_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_datasets
    ADD CONSTRAINT fk_datasets_biblio_id FOREIGN KEY (biblio_id) REFERENCES tbl_biblio(biblio_id) ON UPDATE CASCADE;


--
-- Name: tbl_datasets fk_datasets_data_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_datasets
    ADD CONSTRAINT fk_datasets_data_type_id FOREIGN KEY (data_type_id) REFERENCES tbl_data_types(data_type_id) ON UPDATE CASCADE;


--
-- Name: tbl_datasets fk_datasets_master_set_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_datasets
    ADD CONSTRAINT fk_datasets_master_set_id FOREIGN KEY (master_set_id) REFERENCES tbl_dataset_masters(master_set_id) ON UPDATE CASCADE;


--
-- Name: tbl_datasets fk_datasets_method_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_datasets
    ADD CONSTRAINT fk_datasets_method_id FOREIGN KEY (method_id) REFERENCES tbl_methods(method_id) ON UPDATE CASCADE;


--
-- Name: tbl_datasets fk_datasets_project_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_datasets
    ADD CONSTRAINT fk_datasets_project_id FOREIGN KEY (project_id) REFERENCES tbl_projects(project_id);


--
-- Name: tbl_datasets fk_datasets_updated_dataset_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_datasets
    ADD CONSTRAINT fk_datasets_updated_dataset_id FOREIGN KEY (updated_dataset_id) REFERENCES tbl_datasets(dataset_id) ON UPDATE CASCADE;


--
-- Name: tbl_dating_labs fk_dating_labs_contact_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dating_labs
    ADD CONSTRAINT fk_dating_labs_contact_id FOREIGN KEY (contact_id) REFERENCES tbl_contacts(contact_id);


--
-- Name: tbl_dating_material fk_dating_material_abundance_elements_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dating_material
    ADD CONSTRAINT fk_dating_material_abundance_elements_id FOREIGN KEY (abundance_element_id) REFERENCES tbl_abundance_elements(abundance_element_id);


--
-- Name: tbl_dating_material fk_dating_material_geochronology_geochron_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dating_material
    ADD CONSTRAINT fk_dating_material_geochronology_geochron_id FOREIGN KEY (geochron_id) REFERENCES tbl_geochronology(geochron_id);


--
-- Name: tbl_dating_material fk_dating_material_taxa_tree_master_taxon_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dating_material
    ADD CONSTRAINT fk_dating_material_taxa_tree_master_taxon_id FOREIGN KEY (taxon_id) REFERENCES tbl_taxa_tree_master(taxon_id);


--
-- Name: tbl_dendro fk_dendro_analysis_entity_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dendro
    ADD CONSTRAINT fk_dendro_analysis_entity_id FOREIGN KEY (analysis_entity_id) REFERENCES tbl_analysis_entities(analysis_entity_id);


--
-- Name: tbl_dendro_date_notes fk_dendro_date_notes_dendro_date_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dendro_date_notes
    ADD CONSTRAINT fk_dendro_date_notes_dendro_date_id FOREIGN KEY (dendro_date_id) REFERENCES tbl_dendro_dates(dendro_date_id);


--
-- Name: tbl_dendro_dates fk_dendro_dates_analysis_entity_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dendro_dates
    ADD CONSTRAINT fk_dendro_dates_analysis_entity_id FOREIGN KEY (analysis_entity_id) REFERENCES tbl_analysis_entities(analysis_entity_id);


--
-- Name: tbl_dendro_dates fk_dendro_dates_dating_uncertainty_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dendro_dates
    ADD CONSTRAINT fk_dendro_dates_dating_uncertainty_id FOREIGN KEY (dating_uncertainty_id) REFERENCES tbl_dating_uncertainty(dating_uncertainty_id);


--
-- Name: tbl_dendro_dates fk_dendro_dates_years_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dendro_dates
    ADD CONSTRAINT fk_dendro_dates_years_type_id FOREIGN KEY (years_type_id) REFERENCES tbl_years_types(years_type_id);


--
-- Name: tbl_dendro fk_dendro_dendro_measurement_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dendro
    ADD CONSTRAINT fk_dendro_dendro_measurement_id FOREIGN KEY (dendro_measurement_id) REFERENCES tbl_dendro_measurements(dendro_measurement_id);


--
-- Name: tbl_dendro_measurement_lookup fk_dendro_measurement_lookup_dendro_measurement_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dendro_measurement_lookup
    ADD CONSTRAINT fk_dendro_measurement_lookup_dendro_measurement_id FOREIGN KEY (dendro_measurement_id) REFERENCES tbl_dendro_measurements(dendro_measurement_id);


--
-- Name: tbl_dendro_measurements fk_dendro_measurements_method_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dendro_measurements
    ADD CONSTRAINT fk_dendro_measurements_method_id FOREIGN KEY (method_id) REFERENCES tbl_methods(method_id);


--
-- Name: tbl_dimensions fk_dimensions_method_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dimensions
    ADD CONSTRAINT fk_dimensions_method_group_id FOREIGN KEY (method_group_id) REFERENCES tbl_method_groups(method_group_id);


--
-- Name: tbl_dimensions fk_dimensions_unit_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_dimensions
    ADD CONSTRAINT fk_dimensions_unit_id FOREIGN KEY (unit_id) REFERENCES tbl_units(unit_id) ON UPDATE CASCADE;


--
-- Name: tbl_ecocode_definitions fk_ecocode_definitions_ecocode_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ecocode_definitions
    ADD CONSTRAINT fk_ecocode_definitions_ecocode_group_id FOREIGN KEY (ecocode_group_id) REFERENCES tbl_ecocode_groups(ecocode_group_id) ON UPDATE CASCADE;


--
-- Name: tbl_ecocode_groups fk_ecocode_groups_ecocode_system_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ecocode_groups
    ADD CONSTRAINT fk_ecocode_groups_ecocode_system_id FOREIGN KEY (ecocode_system_id) REFERENCES tbl_ecocode_systems(ecocode_system_id) ON UPDATE CASCADE;


--
-- Name: tbl_ecocode_systems fk_ecocode_systems_biblio_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ecocode_systems
    ADD CONSTRAINT fk_ecocode_systems_biblio_id FOREIGN KEY (biblio_id) REFERENCES tbl_biblio(biblio_id) ON UPDATE CASCADE;


--
-- Name: tbl_ecocodes fk_ecocodes_ecocodedef_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ecocodes
    ADD CONSTRAINT fk_ecocodes_ecocodedef_id FOREIGN KEY (ecocode_definition_id) REFERENCES tbl_ecocode_definitions(ecocode_definition_id) ON UPDATE CASCADE;


--
-- Name: tbl_ecocodes fk_ecocodes_taxon_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_ecocodes
    ADD CONSTRAINT fk_ecocodes_taxon_id FOREIGN KEY (taxon_id) REFERENCES tbl_taxa_tree_master(taxon_id) ON UPDATE CASCADE;


--
-- Name: tbl_features fk_feature_type_id_feature_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_features
    ADD CONSTRAINT fk_feature_type_id_feature_type_id FOREIGN KEY (feature_type_id) REFERENCES tbl_feature_types(feature_type_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tbl_geochron_refs fk_geochron_refs_biblio_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_geochron_refs
    ADD CONSTRAINT fk_geochron_refs_biblio_id FOREIGN KEY (biblio_id) REFERENCES tbl_biblio(biblio_id) ON UPDATE CASCADE;


--
-- Name: tbl_geochron_refs fk_geochron_refs_geochron_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_geochron_refs
    ADD CONSTRAINT fk_geochron_refs_geochron_id FOREIGN KEY (geochron_id) REFERENCES tbl_geochronology(geochron_id) ON UPDATE CASCADE;


--
-- Name: tbl_geochronology fk_geochronology_analysis_entity_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_geochronology
    ADD CONSTRAINT fk_geochronology_analysis_entity_id FOREIGN KEY (analysis_entity_id) REFERENCES tbl_analysis_entities(analysis_entity_id) ON UPDATE CASCADE;


--
-- Name: tbl_geochronology fk_geochronology_dating_labs_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_geochronology
    ADD CONSTRAINT fk_geochronology_dating_labs_id FOREIGN KEY (dating_lab_id) REFERENCES tbl_dating_labs(dating_lab_id) ON UPDATE CASCADE;


--
-- Name: tbl_geochronology fk_geochronology_dating_uncertainty_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_geochronology
    ADD CONSTRAINT fk_geochronology_dating_uncertainty_id FOREIGN KEY (dating_uncertainty_id) REFERENCES tbl_dating_uncertainty(dating_uncertainty_id);


--
-- Name: tbl_horizons fk_horizons_method_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_horizons
    ADD CONSTRAINT fk_horizons_method_id FOREIGN KEY (method_id) REFERENCES tbl_methods(method_id) ON UPDATE CASCADE;


--
-- Name: tbl_imported_taxa_replacements fk_imported_taxa_replacements_taxon_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_imported_taxa_replacements
    ADD CONSTRAINT fk_imported_taxa_replacements_taxon_id FOREIGN KEY (taxon_id) REFERENCES tbl_taxa_tree_master(taxon_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tbl_lithology fk_lithology_sample_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_lithology
    ADD CONSTRAINT fk_lithology_sample_group_id FOREIGN KEY (sample_group_id) REFERENCES tbl_sample_groups(sample_group_id) ON UPDATE CASCADE;


--
-- Name: tbl_site_locations fk_locations_location_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_locations
    ADD CONSTRAINT fk_locations_location_id FOREIGN KEY (location_id) REFERENCES tbl_locations(location_id);


--
-- Name: tbl_locations fk_locations_location_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_locations
    ADD CONSTRAINT fk_locations_location_type_id FOREIGN KEY (location_type_id) REFERENCES tbl_location_types(location_type_id) ON UPDATE CASCADE;


--
-- Name: tbl_site_locations fk_locations_site_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_locations
    ADD CONSTRAINT fk_locations_site_id FOREIGN KEY (site_id) REFERENCES tbl_sites(site_id);


--
-- Name: tbl_mcr_names fk_mcr_names_taxon_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_mcr_names
    ADD CONSTRAINT fk_mcr_names_taxon_id FOREIGN KEY (taxon_id) REFERENCES tbl_taxa_tree_master(taxon_id) ON UPDATE CASCADE;


--
-- Name: tbl_mcr_summary_data fk_mcr_summary_data_taxon_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_mcr_summary_data
    ADD CONSTRAINT fk_mcr_summary_data_taxon_id FOREIGN KEY (taxon_id) REFERENCES tbl_taxa_tree_master(taxon_id) ON UPDATE CASCADE;


--
-- Name: tbl_mcrdata_birmbeetledat fk_mcrdata_birmbeetledat_taxon_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_mcrdata_birmbeetledat
    ADD CONSTRAINT fk_mcrdata_birmbeetledat_taxon_id FOREIGN KEY (taxon_id) REFERENCES tbl_taxa_tree_master(taxon_id) ON UPDATE CASCADE;


--
-- Name: tbl_measured_value_dimensions fk_measured_value_dimensions_dimension_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_measured_value_dimensions
    ADD CONSTRAINT fk_measured_value_dimensions_dimension_id FOREIGN KEY (dimension_id) REFERENCES tbl_dimensions(dimension_id) ON UPDATE CASCADE;


--
-- Name: tbl_measured_values fk_measured_values_analysis_entity_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_measured_values
    ADD CONSTRAINT fk_measured_values_analysis_entity_id FOREIGN KEY (analysis_entity_id) REFERENCES tbl_analysis_entities(analysis_entity_id);


--
-- Name: tbl_measured_value_dimensions fk_measured_weights_value_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_measured_value_dimensions
    ADD CONSTRAINT fk_measured_weights_value_id FOREIGN KEY (measured_value_id) REFERENCES tbl_measured_values(measured_value_id) ON UPDATE CASCADE;


--
-- Name: tbl_methods fk_methods_biblio_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_methods
    ADD CONSTRAINT fk_methods_biblio_id FOREIGN KEY (biblio_id) REFERENCES tbl_biblio(biblio_id) ON UPDATE CASCADE;


--
-- Name: tbl_methods fk_methods_method_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_methods
    ADD CONSTRAINT fk_methods_method_group_id FOREIGN KEY (method_group_id) REFERENCES tbl_method_groups(method_group_id) ON UPDATE CASCADE;


--
-- Name: tbl_methods fk_methods_record_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_methods
    ADD CONSTRAINT fk_methods_record_type_id FOREIGN KEY (record_type_id) REFERENCES tbl_record_types(record_type_id) ON UPDATE CASCADE;


--
-- Name: tbl_methods fk_methods_unit_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_methods
    ADD CONSTRAINT fk_methods_unit_id FOREIGN KEY (unit_id) REFERENCES tbl_units(unit_id) ON UPDATE CASCADE;


--
-- Name: tbl_physical_sample_features fk_physical_sample_features_feature_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_physical_sample_features
    ADD CONSTRAINT fk_physical_sample_features_feature_id FOREIGN KEY (feature_id) REFERENCES tbl_features(feature_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tbl_physical_sample_features fk_physical_sample_features_physical_sample_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_physical_sample_features
    ADD CONSTRAINT fk_physical_sample_features_physical_sample_id FOREIGN KEY (physical_sample_id) REFERENCES tbl_physical_samples(physical_sample_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tbl_physical_samples fk_physical_samples_sample_name_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_physical_samples
    ADD CONSTRAINT fk_physical_samples_sample_name_type_id FOREIGN KEY (alt_ref_type_id) REFERENCES tbl_alt_ref_types(alt_ref_type_id) ON UPDATE CASCADE;


--
-- Name: tbl_physical_samples fk_physical_samples_sample_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_physical_samples
    ADD CONSTRAINT fk_physical_samples_sample_type_id FOREIGN KEY (sample_type_id) REFERENCES tbl_sample_types(sample_type_id) ON UPDATE CASCADE;


--
-- Name: tbl_projects fk_projects_project_stage_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_projects
    ADD CONSTRAINT fk_projects_project_stage_id FOREIGN KEY (project_stage_id) REFERENCES tbl_project_stages(project_stage_id);


--
-- Name: tbl_projects fk_projects_project_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_projects
    ADD CONSTRAINT fk_projects_project_type_id FOREIGN KEY (project_type_id) REFERENCES tbl_project_types(project_type_id);


--
-- Name: tbl_rdb_codes fk_rdb_codes_rdb_system_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_rdb_codes
    ADD CONSTRAINT fk_rdb_codes_rdb_system_id FOREIGN KEY (rdb_system_id) REFERENCES tbl_rdb_systems(rdb_system_id);


--
-- Name: tbl_rdb fk_rdb_rdb_code_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_rdb
    ADD CONSTRAINT fk_rdb_rdb_code_id FOREIGN KEY (rdb_code_id) REFERENCES tbl_rdb_codes(rdb_code_id);


--
-- Name: tbl_rdb_systems fk_rdb_systems_biblio_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_rdb_systems
    ADD CONSTRAINT fk_rdb_systems_biblio_id FOREIGN KEY (biblio_id) REFERENCES tbl_biblio(biblio_id) ON UPDATE CASCADE;


--
-- Name: tbl_rdb_systems fk_rdb_systems_location_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_rdb_systems
    ADD CONSTRAINT fk_rdb_systems_location_id FOREIGN KEY (location_id) REFERENCES tbl_locations(location_id);


--
-- Name: tbl_rdb fk_rdb_taxon_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_rdb
    ADD CONSTRAINT fk_rdb_taxon_id FOREIGN KEY (taxon_id) REFERENCES tbl_taxa_tree_master(taxon_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tbl_relative_age_refs fk_relative_age_refs_biblio_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_relative_age_refs
    ADD CONSTRAINT fk_relative_age_refs_biblio_id FOREIGN KEY (biblio_id) REFERENCES tbl_biblio(biblio_id) ON UPDATE CASCADE;


--
-- Name: tbl_relative_age_refs fk_relative_age_refs_relative_age_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_relative_age_refs
    ADD CONSTRAINT fk_relative_age_refs_relative_age_id FOREIGN KEY (relative_age_id) REFERENCES tbl_relative_ages(relative_age_id) ON UPDATE CASCADE;


--
-- Name: tbl_relative_ages fk_relative_ages_location_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_relative_ages
    ADD CONSTRAINT fk_relative_ages_location_id FOREIGN KEY (location_id) REFERENCES tbl_locations(location_id);


--
-- Name: tbl_relative_ages fk_relative_ages_relative_age_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_relative_ages
    ADD CONSTRAINT fk_relative_ages_relative_age_type_id FOREIGN KEY (relative_age_type_id) REFERENCES tbl_relative_age_types(relative_age_type_id);


--
-- Name: tbl_relative_dates fk_relative_dates_dating_uncertainty_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_relative_dates
    ADD CONSTRAINT fk_relative_dates_dating_uncertainty_id FOREIGN KEY (dating_uncertainty_id) REFERENCES tbl_dating_uncertainty(dating_uncertainty_id);


--
-- Name: tbl_relative_dates fk_relative_dates_method_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_relative_dates
    ADD CONSTRAINT fk_relative_dates_method_id FOREIGN KEY (method_id) REFERENCES tbl_methods(method_id);


--
-- Name: tbl_relative_dates fk_relative_dates_physical_sample_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_relative_dates
    ADD CONSTRAINT fk_relative_dates_physical_sample_id FOREIGN KEY (physical_sample_id) REFERENCES tbl_physical_samples(physical_sample_id) ON UPDATE CASCADE;


--
-- Name: tbl_relative_dates fk_relative_dates_relative_age_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_relative_dates
    ADD CONSTRAINT fk_relative_dates_relative_age_id FOREIGN KEY (relative_age_id) REFERENCES tbl_relative_ages(relative_age_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_alt_refs fk_sample_alt_refs_alt_ref_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_alt_refs
    ADD CONSTRAINT fk_sample_alt_refs_alt_ref_type_id FOREIGN KEY (alt_ref_type_id) REFERENCES tbl_alt_ref_types(alt_ref_type_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_alt_refs fk_sample_alt_refs_physical_sample_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_alt_refs
    ADD CONSTRAINT fk_sample_alt_refs_physical_sample_id FOREIGN KEY (physical_sample_id) REFERENCES tbl_physical_samples(physical_sample_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_colours fk_sample_colours_colour_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_colours
    ADD CONSTRAINT fk_sample_colours_colour_id FOREIGN KEY (colour_id) REFERENCES tbl_colours(colour_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_colours fk_sample_colours_physical_sample_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_colours
    ADD CONSTRAINT fk_sample_colours_physical_sample_id FOREIGN KEY (physical_sample_id) REFERENCES tbl_physical_samples(physical_sample_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_coordinates fk_sample_coordinates_coordinate_method_dimension_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_coordinates
    ADD CONSTRAINT fk_sample_coordinates_coordinate_method_dimension_id FOREIGN KEY (coordinate_method_dimension_id) REFERENCES tbl_coordinate_method_dimensions(coordinate_method_dimension_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_coordinates fk_sample_coordinates_physical_sample_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_coordinates
    ADD CONSTRAINT fk_sample_coordinates_physical_sample_id FOREIGN KEY (physical_sample_id) REFERENCES tbl_physical_samples(physical_sample_id);


--
-- Name: tbl_sample_description_sample_group_contexts fk_sample_description_sample_group_contexts_sampling_context_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_description_sample_group_contexts
    ADD CONSTRAINT fk_sample_description_sample_group_contexts_sampling_context_id FOREIGN KEY (sampling_context_id) REFERENCES tbl_sample_group_sampling_contexts(sampling_context_id);


--
-- Name: tbl_sample_description_sample_group_contexts fk_sample_description_types_sample_group_context_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_description_sample_group_contexts
    ADD CONSTRAINT fk_sample_description_types_sample_group_context_id FOREIGN KEY (sample_description_type_id) REFERENCES tbl_sample_description_types(sample_description_type_id);


--
-- Name: tbl_sample_descriptions fk_sample_descriptions_physical_sample_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_descriptions
    ADD CONSTRAINT fk_sample_descriptions_physical_sample_id FOREIGN KEY (physical_sample_id) REFERENCES tbl_physical_samples(physical_sample_id);


--
-- Name: tbl_sample_descriptions fk_sample_descriptions_sample_description_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_descriptions
    ADD CONSTRAINT fk_sample_descriptions_sample_description_type_id FOREIGN KEY (sample_description_type_id) REFERENCES tbl_sample_description_types(sample_description_type_id);


--
-- Name: tbl_sample_dimensions fk_sample_dimensions_dimension_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_dimensions
    ADD CONSTRAINT fk_sample_dimensions_dimension_id FOREIGN KEY (dimension_id) REFERENCES tbl_dimensions(dimension_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_dimensions fk_sample_dimensions_measurement_method_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_dimensions
    ADD CONSTRAINT fk_sample_dimensions_measurement_method_id FOREIGN KEY (method_id) REFERENCES tbl_methods(method_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_dimensions fk_sample_dimensions_physical_sample_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_dimensions
    ADD CONSTRAINT fk_sample_dimensions_physical_sample_id FOREIGN KEY (physical_sample_id) REFERENCES tbl_physical_samples(physical_sample_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_group_description_type_sampling_contexts fk_sample_group_description_type_sampling_context_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_description_type_sampling_contexts
    ADD CONSTRAINT fk_sample_group_description_type_sampling_context_id FOREIGN KEY (sample_group_description_type_id) REFERENCES tbl_sample_group_description_types(sample_group_description_type_id);


--
-- Name: tbl_sample_group_descriptions fk_sample_group_descriptions_sample_group_description_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_descriptions
    ADD CONSTRAINT fk_sample_group_descriptions_sample_group_description_type_id FOREIGN KEY (sample_group_description_type_id) REFERENCES tbl_sample_group_description_types(sample_group_description_type_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_group_dimensions fk_sample_group_dimensions_dimension_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_dimensions
    ADD CONSTRAINT fk_sample_group_dimensions_dimension_id FOREIGN KEY (dimension_id) REFERENCES tbl_dimensions(dimension_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_group_dimensions fk_sample_group_dimensions_sample_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_dimensions
    ADD CONSTRAINT fk_sample_group_dimensions_sample_group_id FOREIGN KEY (sample_group_id) REFERENCES tbl_sample_groups(sample_group_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_group_images fk_sample_group_images_image_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_images
    ADD CONSTRAINT fk_sample_group_images_image_type_id FOREIGN KEY (image_type_id) REFERENCES tbl_image_types(image_type_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_group_images fk_sample_group_images_sample_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_images
    ADD CONSTRAINT fk_sample_group_images_sample_group_id FOREIGN KEY (sample_group_id) REFERENCES tbl_sample_groups(sample_group_id);


--
-- Name: tbl_sample_group_coordinates fk_sample_group_positions_coordinate_method_dimension_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_coordinates
    ADD CONSTRAINT fk_sample_group_positions_coordinate_method_dimension_id FOREIGN KEY (coordinate_method_dimension_id) REFERENCES tbl_coordinate_method_dimensions(coordinate_method_dimension_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_group_coordinates fk_sample_group_positions_sample_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_coordinates
    ADD CONSTRAINT fk_sample_group_positions_sample_group_id FOREIGN KEY (sample_group_id) REFERENCES tbl_sample_groups(sample_group_id);


--
-- Name: tbl_sample_group_references fk_sample_group_references_biblio_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_references
    ADD CONSTRAINT fk_sample_group_references_biblio_id FOREIGN KEY (biblio_id) REFERENCES tbl_biblio(biblio_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_group_references fk_sample_group_references_sample_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_references
    ADD CONSTRAINT fk_sample_group_references_sample_group_id FOREIGN KEY (sample_group_id) REFERENCES tbl_sample_groups(sample_group_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_groups fk_sample_group_sampling_context_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_groups
    ADD CONSTRAINT fk_sample_group_sampling_context_id FOREIGN KEY (sampling_context_id) REFERENCES tbl_sample_group_sampling_contexts(sampling_context_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_group_description_type_sampling_contexts fk_sample_group_sampling_context_id0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_description_type_sampling_contexts
    ADD CONSTRAINT fk_sample_group_sampling_context_id0 FOREIGN KEY (sampling_context_id) REFERENCES tbl_sample_group_sampling_contexts(sampling_context_id);


--
-- Name: tbl_sample_groups fk_sample_groups_method_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_groups
    ADD CONSTRAINT fk_sample_groups_method_id FOREIGN KEY (method_id) REFERENCES tbl_methods(method_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_group_descriptions fk_sample_groups_sample_group_descriptions_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_descriptions
    ADD CONSTRAINT fk_sample_groups_sample_group_descriptions_id FOREIGN KEY (sample_group_id) REFERENCES tbl_sample_groups(sample_group_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_groups fk_sample_groups_site_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_groups
    ADD CONSTRAINT fk_sample_groups_site_id FOREIGN KEY (site_id) REFERENCES tbl_sites(site_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_horizons fk_sample_horizons_horizon_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_horizons
    ADD CONSTRAINT fk_sample_horizons_horizon_id FOREIGN KEY (horizon_id) REFERENCES tbl_horizons(horizon_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_horizons fk_sample_horizons_physical_sample_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_horizons
    ADD CONSTRAINT fk_sample_horizons_physical_sample_id FOREIGN KEY (physical_sample_id) REFERENCES tbl_physical_samples(physical_sample_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_images fk_sample_images_image_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_images
    ADD CONSTRAINT fk_sample_images_image_type_id FOREIGN KEY (image_type_id) REFERENCES tbl_image_types(image_type_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_images fk_sample_images_physical_sample_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_images
    ADD CONSTRAINT fk_sample_images_physical_sample_id FOREIGN KEY (physical_sample_id) REFERENCES tbl_physical_samples(physical_sample_id) ON UPDATE CASCADE;


--
-- Name: tbl_sample_location_type_sampling_contexts fk_sample_location_sampling_contexts_sampling_context_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_location_type_sampling_contexts
    ADD CONSTRAINT fk_sample_location_sampling_contexts_sampling_context_id FOREIGN KEY (sample_location_type_id) REFERENCES tbl_sample_location_types(sample_location_type_id);


--
-- Name: tbl_sample_location_type_sampling_contexts fk_sample_location_type_sampling_context_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_location_type_sampling_contexts
    ADD CONSTRAINT fk_sample_location_type_sampling_context_id FOREIGN KEY (sampling_context_id) REFERENCES tbl_sample_group_sampling_contexts(sampling_context_id);


--
-- Name: tbl_sample_locations fk_sample_locations_physical_sample_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_locations
    ADD CONSTRAINT fk_sample_locations_physical_sample_id FOREIGN KEY (physical_sample_id) REFERENCES tbl_physical_samples(physical_sample_id);


--
-- Name: tbl_sample_locations fk_sample_locations_sample_location_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_locations
    ADD CONSTRAINT fk_sample_locations_sample_location_type_id FOREIGN KEY (sample_location_type_id) REFERENCES tbl_sample_location_types(sample_location_type_id);


--
-- Name: tbl_sample_notes fk_sample_notes_physical_sample_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_notes
    ADD CONSTRAINT fk_sample_notes_physical_sample_id FOREIGN KEY (physical_sample_id) REFERENCES tbl_physical_samples(physical_sample_id) ON UPDATE CASCADE;


--
-- Name: tbl_physical_samples fk_samples_sample_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_physical_samples
    ADD CONSTRAINT fk_samples_sample_group_id FOREIGN KEY (sample_group_id) REFERENCES tbl_sample_groups(sample_group_id) ON UPDATE CASCADE;


--
-- Name: tbl_seasons fk_seasons_season_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_seasons
    ADD CONSTRAINT fk_seasons_season_type_id FOREIGN KEY (season_type_id) REFERENCES tbl_season_types(season_type_id) ON UPDATE CASCADE;


--
-- Name: tbl_site_images fk_site_images_contact_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_images
    ADD CONSTRAINT fk_site_images_contact_id FOREIGN KEY (contact_id) REFERENCES tbl_contacts(contact_id) ON UPDATE CASCADE;


--
-- Name: tbl_site_images fk_site_images_image_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_images
    ADD CONSTRAINT fk_site_images_image_type_id FOREIGN KEY (image_type_id) REFERENCES tbl_image_types(image_type_id) ON UPDATE CASCADE;


--
-- Name: tbl_site_images fk_site_images_site_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_images
    ADD CONSTRAINT fk_site_images_site_id FOREIGN KEY (site_id) REFERENCES tbl_sites(site_id);


--
-- Name: tbl_site_natgridrefs fk_site_natgridrefs_method_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_natgridrefs
    ADD CONSTRAINT fk_site_natgridrefs_method_id FOREIGN KEY (method_id) REFERENCES tbl_methods(method_id);


--
-- Name: tbl_site_natgridrefs fk_site_natgridrefs_sites_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_natgridrefs
    ADD CONSTRAINT fk_site_natgridrefs_sites_id FOREIGN KEY (site_id) REFERENCES tbl_sites(site_id);


--
-- Name: tbl_site_other_records fk_site_other_records_biblio_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_other_records
    ADD CONSTRAINT fk_site_other_records_biblio_id FOREIGN KEY (biblio_id) REFERENCES tbl_biblio(biblio_id) ON UPDATE CASCADE;


--
-- Name: tbl_site_other_records fk_site_other_records_record_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_other_records
    ADD CONSTRAINT fk_site_other_records_record_type_id FOREIGN KEY (record_type_id) REFERENCES tbl_record_types(record_type_id) ON UPDATE CASCADE;


--
-- Name: tbl_site_other_records fk_site_other_records_site_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_other_records
    ADD CONSTRAINT fk_site_other_records_site_id FOREIGN KEY (site_id) REFERENCES tbl_sites(site_id) ON UPDATE CASCADE;


--
-- Name: tbl_site_preservation_status fk_site_preservation_status_site_id ; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_preservation_status
    ADD CONSTRAINT "fk_site_preservation_status_site_id " FOREIGN KEY (site_id) REFERENCES tbl_sites(site_id) ON UPDATE CASCADE;


--
-- Name: tbl_site_references fk_site_references_biblio_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_references
    ADD CONSTRAINT fk_site_references_biblio_id FOREIGN KEY (biblio_id) REFERENCES tbl_biblio(biblio_id) ON UPDATE CASCADE;


--
-- Name: tbl_site_references fk_site_references_site_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_site_references
    ADD CONSTRAINT fk_site_references_site_id FOREIGN KEY (site_id) REFERENCES tbl_sites(site_id) ON UPDATE CASCADE;


--
-- Name: tbl_species_associations fk_species_associations_associated_taxon_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_species_associations
    ADD CONSTRAINT fk_species_associations_associated_taxon_id FOREIGN KEY (taxon_id) REFERENCES tbl_taxa_tree_master(taxon_id) ON UPDATE CASCADE;


--
-- Name: tbl_species_associations fk_species_associations_association_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_species_associations
    ADD CONSTRAINT fk_species_associations_association_type_id FOREIGN KEY (association_type_id) REFERENCES tbl_species_association_types(association_type_id);


--
-- Name: tbl_species_associations fk_species_associations_biblio_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_species_associations
    ADD CONSTRAINT fk_species_associations_biblio_id FOREIGN KEY (biblio_id) REFERENCES tbl_biblio(biblio_id) ON UPDATE CASCADE;


--
-- Name: tbl_species_associations fk_species_associations_taxon_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_species_associations
    ADD CONSTRAINT fk_species_associations_taxon_id FOREIGN KEY (taxon_id) REFERENCES tbl_taxa_tree_master(taxon_id);


--
-- Name: tbl_taxa_common_names fk_taxa_common_names_language_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_common_names
    ADD CONSTRAINT fk_taxa_common_names_language_id FOREIGN KEY (language_id) REFERENCES tbl_languages(language_id) ON UPDATE CASCADE;


--
-- Name: tbl_taxa_common_names fk_taxa_common_names_taxon_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_common_names
    ADD CONSTRAINT fk_taxa_common_names_taxon_id FOREIGN KEY (taxon_id) REFERENCES tbl_taxa_tree_master(taxon_id) ON UPDATE CASCADE;


--
-- Name: tbl_taxa_images fk_taxa_images_image_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_images
    ADD CONSTRAINT fk_taxa_images_image_type_id FOREIGN KEY (image_type_id) REFERENCES tbl_image_types(image_type_id);


--
-- Name: tbl_taxa_images fk_taxa_images_taxa_tree_master_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_images
    ADD CONSTRAINT fk_taxa_images_taxa_tree_master_id FOREIGN KEY (taxon_id) REFERENCES tbl_taxa_tree_master(taxon_id);


--
-- Name: tbl_taxa_measured_attributes fk_taxa_measured_attributes_taxon_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_measured_attributes
    ADD CONSTRAINT fk_taxa_measured_attributes_taxon_id FOREIGN KEY (taxon_id) REFERENCES tbl_taxa_tree_master(taxon_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tbl_taxa_reference_specimens fk_taxa_reference_specimens_contact_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_reference_specimens
    ADD CONSTRAINT fk_taxa_reference_specimens_contact_id FOREIGN KEY (contact_id) REFERENCES tbl_contacts(contact_id);


--
-- Name: tbl_taxa_reference_specimens fk_taxa_reference_specimens_taxon_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_reference_specimens
    ADD CONSTRAINT fk_taxa_reference_specimens_taxon_id FOREIGN KEY (taxon_id) REFERENCES tbl_taxa_tree_master(taxon_id);


--
-- Name: tbl_taxa_seasonality fk_taxa_seasonality_activity_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_seasonality
    ADD CONSTRAINT fk_taxa_seasonality_activity_type_id FOREIGN KEY (activity_type_id) REFERENCES tbl_activity_types(activity_type_id) ON UPDATE CASCADE;


--
-- Name: tbl_taxa_seasonality fk_taxa_seasonality_location_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_seasonality
    ADD CONSTRAINT fk_taxa_seasonality_location_id FOREIGN KEY (location_id) REFERENCES tbl_locations(location_id);


--
-- Name: tbl_taxa_seasonality fk_taxa_seasonality_season_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_seasonality
    ADD CONSTRAINT fk_taxa_seasonality_season_id FOREIGN KEY (season_id) REFERENCES tbl_seasons(season_id) ON UPDATE CASCADE;


--
-- Name: tbl_taxa_seasonality fk_taxa_seasonality_taxon_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_seasonality
    ADD CONSTRAINT fk_taxa_seasonality_taxon_id FOREIGN KEY (taxon_id) REFERENCES tbl_taxa_tree_master(taxon_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tbl_taxa_synonyms fk_taxa_synonyms_biblio_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_synonyms
    ADD CONSTRAINT fk_taxa_synonyms_biblio_id FOREIGN KEY (biblio_id) REFERENCES tbl_biblio(biblio_id) ON UPDATE CASCADE;


--
-- Name: tbl_taxa_synonyms fk_taxa_synonyms_family_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_synonyms
    ADD CONSTRAINT fk_taxa_synonyms_family_id FOREIGN KEY (family_id) REFERENCES tbl_taxa_tree_families(family_id) ON UPDATE CASCADE;


--
-- Name: tbl_taxa_synonyms fk_taxa_synonyms_genus_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_synonyms
    ADD CONSTRAINT fk_taxa_synonyms_genus_id FOREIGN KEY (genus_id) REFERENCES tbl_taxa_tree_genera(genus_id) ON UPDATE CASCADE;


--
-- Name: tbl_taxa_synonyms fk_taxa_synonyms_taxa_tree_author_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_synonyms
    ADD CONSTRAINT fk_taxa_synonyms_taxa_tree_author_id FOREIGN KEY (author_id) REFERENCES tbl_taxa_tree_authors(author_id);


--
-- Name: tbl_taxa_synonyms fk_taxa_synonyms_taxon_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_synonyms
    ADD CONSTRAINT fk_taxa_synonyms_taxon_id FOREIGN KEY (taxon_id) REFERENCES tbl_taxa_tree_master(taxon_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tbl_taxa_tree_families fk_taxa_tree_families_order_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_tree_families
    ADD CONSTRAINT fk_taxa_tree_families_order_id FOREIGN KEY (order_id) REFERENCES tbl_taxa_tree_orders(order_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tbl_taxa_tree_genera fk_taxa_tree_genera_family_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_tree_genera
    ADD CONSTRAINT fk_taxa_tree_genera_family_id FOREIGN KEY (family_id) REFERENCES tbl_taxa_tree_families(family_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tbl_taxa_tree_master fk_taxa_tree_master_author_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_tree_master
    ADD CONSTRAINT fk_taxa_tree_master_author_id FOREIGN KEY (author_id) REFERENCES tbl_taxa_tree_authors(author_id) ON UPDATE CASCADE;


--
-- Name: tbl_taxa_tree_master fk_taxa_tree_master_genus_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_tree_master
    ADD CONSTRAINT fk_taxa_tree_master_genus_id FOREIGN KEY (genus_id) REFERENCES tbl_taxa_tree_genera(genus_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tbl_taxa_tree_orders fk_taxa_tree_orders_record_type_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxa_tree_orders
    ADD CONSTRAINT fk_taxa_tree_orders_record_type_id FOREIGN KEY (record_type_id) REFERENCES tbl_record_types(record_type_id) ON UPDATE CASCADE;


--
-- Name: tbl_taxonomic_order_biblio fk_taxonomic_order_biblio_biblio_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxonomic_order_biblio
    ADD CONSTRAINT fk_taxonomic_order_biblio_biblio_id FOREIGN KEY (biblio_id) REFERENCES tbl_biblio(biblio_id) ON UPDATE CASCADE;


--
-- Name: tbl_taxonomic_order_biblio fk_taxonomic_order_biblio_taxonomic_order_system_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxonomic_order_biblio
    ADD CONSTRAINT fk_taxonomic_order_biblio_taxonomic_order_system_id FOREIGN KEY (taxonomic_order_system_id) REFERENCES tbl_taxonomic_order_systems(taxonomic_order_system_id) ON UPDATE CASCADE;


--
-- Name: tbl_taxonomic_order fk_taxonomic_order_taxon_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxonomic_order
    ADD CONSTRAINT fk_taxonomic_order_taxon_id FOREIGN KEY (taxon_id) REFERENCES tbl_taxa_tree_master(taxon_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tbl_taxonomic_order fk_taxonomic_order_taxonomic_order_system_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxonomic_order
    ADD CONSTRAINT fk_taxonomic_order_taxonomic_order_system_id FOREIGN KEY (taxonomic_order_system_id) REFERENCES tbl_taxonomic_order_systems(taxonomic_order_system_id) ON UPDATE CASCADE;


--
-- Name: tbl_taxonomy_notes fk_taxonomy_notes_biblio_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxonomy_notes
    ADD CONSTRAINT fk_taxonomy_notes_biblio_id FOREIGN KEY (biblio_id) REFERENCES tbl_biblio(biblio_id) ON UPDATE CASCADE;


--
-- Name: tbl_taxonomy_notes fk_taxonomy_notes_taxon_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_taxonomy_notes
    ADD CONSTRAINT fk_taxonomy_notes_taxon_id FOREIGN KEY (taxon_id) REFERENCES tbl_taxa_tree_master(taxon_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tbl_rdb fk_tbl_rdb_tbl_location_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_rdb
    ADD CONSTRAINT fk_tbl_rdb_tbl_location_id FOREIGN KEY (location_id) REFERENCES tbl_locations(location_id);


--
-- Name: tbl_sample_group_notes fk_tbl_sample_group_notes_sample_groups; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_sample_group_notes
    ADD CONSTRAINT fk_tbl_sample_group_notes_sample_groups FOREIGN KEY (sample_group_id) REFERENCES tbl_sample_groups(sample_group_id) ON UPDATE CASCADE;


--
-- Name: tbl_tephra_dates fk_tephra_dates_analysis_entity_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_tephra_dates
    ADD CONSTRAINT fk_tephra_dates_analysis_entity_id FOREIGN KEY (analysis_entity_id) REFERENCES tbl_analysis_entities(analysis_entity_id) ON UPDATE CASCADE;


--
-- Name: tbl_tephra_dates fk_tephra_dates_dating_uncertainty_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_tephra_dates
    ADD CONSTRAINT fk_tephra_dates_dating_uncertainty_id FOREIGN KEY (dating_uncertainty_id) REFERENCES tbl_dating_uncertainty(dating_uncertainty_id);


--
-- Name: tbl_tephra_dates fk_tephra_dates_tephra_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_tephra_dates
    ADD CONSTRAINT fk_tephra_dates_tephra_id FOREIGN KEY (tephra_id) REFERENCES tbl_tephras(tephra_id) ON UPDATE CASCADE;


--
-- Name: tbl_tephra_refs fk_tephra_refs_biblio_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_tephra_refs
    ADD CONSTRAINT fk_tephra_refs_biblio_id FOREIGN KEY (biblio_id) REFERENCES tbl_biblio(biblio_id) ON UPDATE CASCADE;


--
-- Name: tbl_tephra_refs fk_tephra_refs_tephra_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_tephra_refs
    ADD CONSTRAINT fk_tephra_refs_tephra_id FOREIGN KEY (tephra_id) REFERENCES tbl_tephras(tephra_id) ON UPDATE CASCADE;


--
-- Name: tbl_text_biology fk_text_biology_biblio_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_text_biology
    ADD CONSTRAINT fk_text_biology_biblio_id FOREIGN KEY (biblio_id) REFERENCES tbl_biblio(biblio_id) ON UPDATE CASCADE;


--
-- Name: tbl_text_biology fk_text_biology_taxon_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_text_biology
    ADD CONSTRAINT fk_text_biology_taxon_id FOREIGN KEY (taxon_id) REFERENCES tbl_taxa_tree_master(taxon_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tbl_text_distribution fk_text_distribution_biblio_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_text_distribution
    ADD CONSTRAINT fk_text_distribution_biblio_id FOREIGN KEY (biblio_id) REFERENCES tbl_biblio(biblio_id) ON UPDATE CASCADE;


--
-- Name: tbl_text_distribution fk_text_distribution_taxon_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_text_distribution
    ADD CONSTRAINT fk_text_distribution_taxon_id FOREIGN KEY (taxon_id) REFERENCES tbl_taxa_tree_master(taxon_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tbl_text_identification_keys fk_text_identification_keys_biblio_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_text_identification_keys
    ADD CONSTRAINT fk_text_identification_keys_biblio_id FOREIGN KEY (biblio_id) REFERENCES tbl_biblio(biblio_id) ON UPDATE CASCADE;


--
-- Name: tbl_text_identification_keys fk_text_identification_keys_taxon_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tbl_text_identification_keys
    ADD CONSTRAINT fk_text_identification_keys_taxon_id FOREIGN KEY (taxon_id) REFERENCES tbl_taxa_tree_master(taxon_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

