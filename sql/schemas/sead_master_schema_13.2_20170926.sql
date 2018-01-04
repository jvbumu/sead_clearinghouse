CREATE SCHEMA "metainformation" AUTHORIZATION "postgres";


COMMENT ON SCHEMA "metainformation" IS 'Used to store meta information about the database. for easy access to read only users.';

CREATE TABLE "public"."_pgmdd_backup_tbl_ceramics_2017-26-09_10:27" AS
	SELECT * FROM public.tbl_ceramics;

ALTER TABLE "tbl_ceramics" 
	RENAME COLUMN "ceramics_measurement_id" TO "ceramics_lookup_id";

CREATE TABLE "public"."_pgmdd_backup_tbl_dendro_2017-26-09_10:27" AS
	SELECT * FROM public.tbl_dendro;

ALTER TABLE "tbl_dendro" 
	RENAME COLUMN "dendro_measurement_id" TO "dendro_lookup_id";

COMMENT ON TABLE "tbl_analysis_entity_prep_methods" IS '20170907PIB: Devolved due to problems in isolating measurement datasets with pretreatment/without. Many to many between datasets and methods used as replacement.
20120506PIB: created to cater for multiple preparation methods for analysis but maintaining simple dataset concept.';

CREATE TABLE "public"."_pgmdd_backup_tbl_chronologies_2017-26-09_10:27" AS
	SELECT * FROM public.tbl_chronologies;

ALTER TABLE "tbl_chronologies" ALTER COLUMN "sample_group_id" DROP NOT NULL;

ALTER TABLE "tbl_chronologies" 
	ALTER COLUMN "chronology_name" TYPE varchar(255);

ALTER TABLE "tbl_chronologies" 
	ALTER COLUMN "age_model" TYPE varchar(255);

ALTER TABLE "tbl_chronologies" 
	ADD COLUMN "relative_age_type_id" int4;

COMMENT ON COLUMN "tbl_chronologies"."relative_age_type_id" IS 'Constraint removed to obsolete table (tbl_age_types), replaced by non-binding id of relative_age_types - but not fully implemented. Notes should be used to inform on chronology years types and construction.';

ALTER TABLE "public"."tbl_chronologies" 
	DROP COLUMN "age_type_id" CASCADE;

COMMENT ON TABLE "tbl_chronologies" IS '20170911PIB: Removed Not Null requirement for sample-group_id to allow for chronologies not tied to a single sample group (e.e. calibrated ages for DataArc or other projects)
Increased length of some fields.
20120504PIB: Note that the dropped age type recorded the type of dates (C14 etc) used in constructing the chronology... but is only one per chonology enough? Can a chronology not be made up of mulitple types of age? (No, years types can only be of one sort - need to calibrate if mixed?)';

CREATE TABLE "public"."_pgmdd_backup_tbl_analysis_entity_ages_2017-26-09_10:27" AS
	SELECT * FROM public.tbl_analysis_entity_ages;

ALTER TABLE "tbl_analysis_entity_ages" 
	ALTER COLUMN "age_younger" TYPE numeric(20,5);

ALTER TABLE "tbl_analysis_entity_ages" 
	ALTER COLUMN "age_older" TYPE numeric(20,5);

ALTER TABLE "tbl_analysis_entity_ages" 
	ALTER COLUMN "age" TYPE numeric(20,5);

COMMENT ON TABLE "tbl_analysis_entity_ages" IS '20170911PIB: Changed numeric ranges of values to 20,5 to match tbl_relative_ages
20120504PIB: Should this be connected to physical sample instead of analysis entities? Allowing multiple ages (from multiple dates) for a sample. At the moment it requires a lot of backtracing to find a sample''s age... but then again, it allows... what, exactly?';

-- ------------------------------------------------------------
-- Description:
-- Measurement/description categories for describing ceramics. List of acceptable values is provided where appropriate.
-- ------------------------------------------------------------

-- ------------------------------------------------------------
-- Annotation:
-- 13.2 Restructured to a single table from two tables
-- ------------------------------------------------------------

CREATE TABLE "tbl_ceramics_lookup" (
	"ceramics_lookup_id" SERIAL NOT NULL,
	"method_id" int4 NOT NULL,
	"description" text,
	"name" varchar NOT NULL,
	"date_updated" timestamp with time zone DEFAULT now(),
	PRIMARY KEY("ceramics_lookup_id")
);

ALTER TABLE "tbl_ceramics_lookup" OWNER TO "seadworker";

COMMENT ON TABLE "tbl_ceramics_lookup" IS 'Type=lookup';

-- ------------------------------------------------------------
-- Description:
-- Defines measurements stored in tbl_dendro and allows values selected from list in tbl_dendro_measurement_lookup.
-- ------------------------------------------------------------

-- ------------------------------------------------------------
-- Annotation:
-- 13.2 Reduced to single table cf ceramics. Will need testing with real data.
-- Old: May move this all over to methods if more appropriate/useful. There may be aspects of dendro which do not work with either 
-- option and may be moved up to sample level. Preveniens might be awkward.
-- ------------------------------------------------------------

CREATE TABLE "tbl_dendro_lookup" (
	"dendro_lookup_id" SERIAL NOT NULL,
	"method_id" int4,
	"name" varchar NOT NULL,
	"description" text,
	"date_updated" timestamp with time zone DEFAULT now(),
	PRIMARY KEY("dendro_lookup_id")
);

ALTER TABLE "tbl_dendro_lookup" OWNER TO "seadworker";

COMMENT ON TABLE "tbl_dendro_lookup" IS 'Type=lookup';

ALTER TABLE "tbl_ceramics_lookup" ADD CONSTRAINT "fk_ceramics_lookup_method_id" FOREIGN KEY ("method_id")
	REFERENCES "tbl_methods"("method_id")
	MATCH SIMPLE
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	NOT DEFERRABLE;

ALTER TABLE "tbl_dendro_lookup" ADD CONSTRAINT "fk_dendro_lookup_method_id" FOREIGN KEY ("method_id")
	REFERENCES "tbl_methods"("method_id")
	MATCH SIMPLE
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	NOT DEFERRABLE;

ALTER TABLE "public"."tbl_dendro" 
	DROP CONSTRAINT "fk_dendro_dendro_measurement_id" CASCADE;

ALTER TABLE "tbl_dendro" ADD CONSTRAINT "fk_dendro_dendro_lookup_id" FOREIGN KEY ("dendro_lookup_id")
	REFERENCES "tbl_dendro_lookup"("dendro_lookup_id")
	MATCH SIMPLE
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	NOT DEFERRABLE;

ALTER TABLE "public"."tbl_ceramics" 
	DROP CONSTRAINT "fk_ceramics_ceramics_measurement_id" CASCADE;

ALTER TABLE "tbl_ceramics" ADD CONSTRAINT "fk_ceramics_ceramics_lookup_id" FOREIGN KEY ("ceramics_lookup_id")
	REFERENCES "tbl_ceramics_lookup"("ceramics_lookup_id")
	MATCH SIMPLE
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	NOT DEFERRABLE;
