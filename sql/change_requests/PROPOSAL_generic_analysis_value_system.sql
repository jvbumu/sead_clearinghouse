
/* proposal: a more generic SEAD analysis value storage using inheritence and partitioning */
/* complemented with an EAV-model using JSONB */

drop schema if exists development cascade;

create schema if not exists development;

/* lookups */
create table if not exists development.tbl_analysis_value_lookups (
    lookup_id serial primary key,
    name character varying,
    description character varying,
    note text,
    date_updated timestamp with time zone DEFAULT now()
);

create table if not exists development.tbl_analysis_value_method_lookups (
    method_id int /*,
    constraint fk_analysis_value_method_lookups_method_id foreign key (method_id) references tbl_methods (method_id) */
) inherits (development.tbl_analysis_value_lookups);


/* common entity table many-to-one relations */
create table if not exists development.tbl_analysis_value_lookup (
    lookup_id serial primary key,
    name character varying,
    description character varying
);

/* abstract tables */
create table if not exists development.tbl_analysis_values (
    analysis_value_id serial primary key,
    analysis_entity_id int /* references tbl_analysis_entity(analysis_entity_id) */,
    properties jsonb null, /* FIXME: Move to own table to be inherited where needed? */
    lookup_id int null references development.tbl_analysis_value_lookups (lookup_id),
    date_updated timestamp with time zone DEFAULT now(),
    note text /* FIXME: not used for all children. Can be relaced by tbl_analysis_value_notes */
);

create table if not exists development.tbl_analysis_value_counts (
    value int not null,
    constraint pk_tbl_analysis_value_counts primary key (analysis_value_id)
) inherits (development.tbl_analysis_values);

create table if not exists development.tbl_analysis_value_measures (
    value decimal(20,10),
    constraint pk_tbl_analysis_value_measure primary key (analysis_value_id)
) inherits (development.tbl_analysis_values);
    
create table if not exists development.tbl_analysis_value_tokens (
    value character varying,
    constraint pk_tbl_analysis_value_tokens primary key (analysis_value_id)
) inherits (development.tbl_analysis_values);

create table if not exists development.tbl_analysis_value_taxon (
    taxon_id int not null /* references tbl_taxa_tree(taxon_id) */,
    constraint pk_tbl_analysis_value_taxon primary key (analysis_value_id)
) inherits (development.tbl_analysis_values);

create table if not exists development.tbl_analysis_value_laboratory (
    lab_id int not null /* references tbl_dating_labs(dating_lab_id) or tbl_laboratory(lab_id) */,
    lab_reference_id character varying,
    constraint pk_tbl_analysis_value_laboratory primary key (analysis_value_id)
) inherits (development.tbl_analysis_values);

create table if not exists development.tbl_analysis_value_tephra (
    -- notes moved to tbl_analysis_value_notes
    tephra_id integer references public.tbl_tephras (tephra_id),
    dating_uncertainty_id integer /* references public.tbl_dating_uncertainty (dating_uncertainty_id) */,
    constraint pk_tbl_analysis_value_tephra primary key (analysis_value_id)
) inherits (development.tbl_analysis_values);

create table if not exists development.tbl_analysis_value_age_range (
    
    -- FIXME: Split into several tables?
    age_type_id integer NOT NULL, -- references public.tbl_age_types (age_type_id),
    age_younger integer,
    age_older integer,
    
    error_uncertainty_id integer, -- references public.tbl_error_uncertainties (error_uncertainty_id),
    error_plus integer,
    error_minus integer,

    dating_uncertainty_id integer, -- references public.tbl_dating_uncertainty (dating_uncertainty_id),
    season_or_qualifier_id integer,
    constraint pk_tbl_analysis_value_age_range primary key (analysis_value_id)
    
) inherits (development.tbl_analysis_values);

create table if not exists development.tbl_analysis_value_geochronology (
    
    age numeric(20, 5) NOT NULL,
    error_younger numeric(20, 5),
    error_older numeric(20, 5),
    delta_13c numeric(10, 5),
    
    dating_uncertainty_id integer, -- references public.tbl_dating_uncertainty (dating_uncertainty_id),
    
    constraint pk_tbl_analysis_value_geochronology primary key (analysis_value_id)
    
) inherits (development.tbl_analysis_values, development.tbl_analysis_value_laboratory);

/* concrete tables */
create table if not exists development.tbl_abundance (
    constraint pk_tbl_analysis_value_abundance primary key (analysis_value_id)
) inherits (development.tbl_analysis_value_counts, development.tbl_analysis_value_taxon);

create table if not exists development.tbl_ceramics (
    constraint pk_tbl_analysis_value_ceramics primary key (analysis_value_id)
) inherits (development.tbl_analysis_value_tokens);

create table if not exists development.tbl_dendro (
    constraint pk_tbl_analysis_value_dendro primary key (analysis_value_id)
) inherits (development.tbl_analysis_value_tokens);

create table if not exists development.tbl_dendro_date (
    constraint pk_tbl_analysis_value_dendro_date primary key (analysis_value_id)
) inherits (development.tbl_analysis_value_age_range);

-- redundant: create table if not exists development.tbl_dendro_date_notes (
-- ) inherits (development.tbl_analysis_value_notes);

/* common entity table zero-to-many relations */
create table if not exists development.tbl_analysis_value_identification_details (
    identification_detail_id serial primary key,
    analysis_value_id int not null /* references tbl_analysis_values(analysis_value_id) */,
    identification_level_id int null /* references tbl_identification_levels(analysis_value_id) */
);

create table if not exists development.tbl_analysis_value_modification_details (
    modification_detail_id serial primary key,
    analysis_value_id int not null /* references tbl_analysis_values(analysis_value_id) */,
    modification_type_id int null /* references tbl_modification_types(modification_type_id) */
);

create table if not exists development.tbl_analysis_value_notes (
    analysis_value_note_id serial primary key,
    analysis_value_id int not null /* references tbl_analysis_values(analysis_value_id) */,
    note text
);
    
create table if not exists development.tbl_analysis_value_dimensions (
    analysis_value_dimension_id serial primary key,
    analysis_value_id int not null /* references tbl_analysis_values(analysis_value_id) */,
    dimension_id int not null /* references tbl_dimensions(dimension_id) */,
    dimension_value numeric(18, 10)
);


create table if not exists development.tbl_analysis_value_properties (
    analysis_value_property_id serial primary key,
    analysis_entity_id int /* references tbl_analysis_entity(analysis_entity_id) */,
    properties jsonb null
);

/********************************************************/


-- renames:
--   abundance_id         -> analysis_value_id
--   abundance            -> value_count
--   abundance_element_id -> lookup_id
--   tbl_abundance_detail_levels -> tbl_identification_levels


