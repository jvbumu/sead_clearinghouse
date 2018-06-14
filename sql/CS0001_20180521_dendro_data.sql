
/****************************************************************************************************************
  Change author
    Mattias Sjölander, Roger Mähler, 2018-06-12
  Change description
    DDL changes to SEAD DB to accommodate Dendro data
  Risk assessment
    Low risk since the data is new
  Planning
    Low risk
  Change execution and rollback
    Apply this script.
    Steps to verify change: N/A
    Steps to rollback change: N/A
  Change prerequisites (e.g. tests)
  Change reviewer
    Mattias Sjölander
  Change Approver Signoff
    Phil Buckland
  Notes:
    FK constraint is of "SIMPLE MATCH" which allows NULL FK values i.e. no change needed
  Impact on dependent modules
    Changes must be propagated to Clearing House
*****************************************************************************************************************/

drop view postgrest_default_api.dendro_date;
drop view clearing_house.view_dendro_dates;

DO $$
BEGIN
	BEGIN TRANSACTION;

	create table public.tbl_age_types (
		age_type_id serial PRIMARY KEY,
		age_type character varying(150) NOT NULL,
		description text,
		date_updated timestamp with time zone DEFAULT now()
	);

	create table public.tbl_error_uncertainties (
		error_uncertainty_id serial PRIMARY KEY,
		error_uncertainty_type character varying(150) NOT NULL,
		description text,
		date_updated timestamp with time zone DEFAULT now()
	);

	create table public.tbl_season_or_qualifier (
		season_or_qualifier_id serial PRIMARY KEY,
		season_or_qualifier_type character varying(150) NOT NULL,
		description text,
		date_updated timestamp with time zone DEFAULT now()
	);

	alter table tbl_dendro_dates rename column cal_age_older to age_older;
	alter table tbl_dendro_dates rename column cal_age_younger to age_younger;
	alter table tbl_dendro_dates drop column error;
	alter table tbl_dendro_dates add column error_plus int;
	alter table tbl_dendro_dates add column error_minus int;

	alter table tbl_dendro_dates add column dendro_lookup_id integer not null,
		  add constraint fk_dendro_lookup_dendro_lookup_id
		  foreign key (dendro_lookup_id)
		  references tbl_dendro_lookup (dendro_lookup_id);

	alter table tbl_dendro_dates
	  add column error_uncertainty_id integer not null,
		  add constraint fk_tbl_error_uncertainties_error_uncertainty_id
		  foreign key (error_uncertainty_id)
		  references tbl_error_uncertainties (error_uncertainty_id);

	alter table tbl_dendro_dates drop column years_type_id;
	alter table tbl_dendro_dates
	  add column age_type_id integer not null,
		  add constraint fk_tbl_age_types_age_type_id
		  foreign key (age_type_id)
		  references tbl_age_types (age_type_id);

    ALTER TABLE public.tbl_age_types OWNER to sead_master;
    ALTER TABLE public.tbl_error_uncertainties OWNER to sead_master;
    ALTER TABLE public.tbl_season_or_qualifier OWNER to sead_master;

    GRANT ALL ON TABLE public.tbl_age_types, public.tbl_error_uncertainties, public.tbl_season_or_qualifier
        TO sead_master, sead_read, humlab_admin, mattias, postgres;

    GRANT SELECT ON TABLE public.tbl_age_types, public.tbl_error_uncertainties, public.tbl_season_or_qualifier
        TO humlab_read;

	COMMIT;
END $$;

BEGIN TRANSACTION;

INSERT INTO tbl_locations (location_name, location_type_id) VALUES
    ('Jönköpings län','2'),
    ('Kalmar län','2'),
    ('Kronobergs län','2'),
    ('Alvesta kommun','2'),
    ('Borgholm kommun','2'),
    ('Eksjö kommun','2'),
    ('Emmaboda kommun','2'),
    ('Gislaved kommun','2'),
    ('Hultsfred kommun','2'),
    ('Hylte kommun','2'),
    ('Högsby kommun','2'),
    ('Jönköping kommun','2'),
    ('Kalmar kommun','2'),
    ('Lessebo kommun','2'),
    ('Ljungby kommun','2'),
    ('Mönsterås kommun','2'),
    ('Nybro kommun','2'),
    ('Oskarshamn kommun','2'),
    ('Tranås kommun','2'),
    ('Uppvidinge kommun','2'),
    ('Vaggeryd kommun','2'),
    ('Vetlanda kommun','2'),
    ('Vimmerby kommun','2'),
    ('Värnamo kommun','2'),
    ('Västervik kommun','2'),
    ('Växjö kommun','2'),
    ('Aneby socken','2'),
    ('Björkö socken','2'),
    ('Bottnaryd socken','2'),
    ('Burseryd socken','2'),
    ('Dädesjö socken','2'),
    ('Döderhult socken','2'),
    ('Fagerhult socken','2'),
    ('Föra socken','2'),
    ('Hagby socken','2'),
    ('Huskvarna socken','2'),
    ('Höreda socken','2'),
    ('Ingatorp socken','2'),
    ('Jät socken','2'),
    ('Kalmar stad socken','2'),
    ('Kristdala socken','2'),
    ('Kånna socken','2'),
    ('Källa socken','2'),
    ('Linderås socken','2'),
    ('Ljuder socken','2'),
    ('Madesjö socken','2'),
    ('Mortorp socken','2'),
    ('Målilla-Gårdveda socken','2'),
    ('Månsarp socken','2'),
    ('Mönsterås socken','2'),
    ('Nävelsjö socken','2'),
    ('Rumskulla  socken','2'),
    ('Skatelöv socken','2'),
    ('Svenarum socken','2'),
    ('Södra Unnaryd socken','2'),
    ('Tånnö socken','2'),
    ('Vetlanda socken','2'),
    ('Vimmerby socken','2'),
    ('Visingsö socken','2'),
    ('Vissefjärda socken','2'),
    ('Västervik socken','2'),
    ('Ålem socken','2'),
    ('Åseda socken','2'),
    ('Älghult socken','2'),
    ('Osby kommun','2'),
    ('Örkeneds socken','2'),
    ('Axebo','2'),
    ('Brunstorp','2'),
    ('Bråten','2'),
    ('Byestad','2'),
    ('Bökhult','2'),
    ('Dädesjö','2'),
    ('Edema','2'),
    ('Ejdern','2'),
    ('Fallebotorp','2'),
    ('Flöxhult','2'),
    ('Föra','2'),
    ('Göberga','2'),
    ('Hagby','2'),
    ('Hagetorp','2'),
    ('Hattmakaren','2'),
    ('Hellerö','2'),
    ('Hyltan ','2'),
    ('Hökagården','2'),
    ('Jät','2'),
    ('Klyvaren','2'),
    ('Kronobäck','2'),
    ('Källa','2'),
    ('Lilla Rätö ','2'),
    ('Mortorp','2'),
    ('Måcketorp','2'),
    ('Målajord','2'),
    ('Näktergalen','2'),
    ('Näset ','2'),
    ('Nävelsjö','2'),
    ('Oset','2'),
    ('Ripan','2'),
    ('Rådmannen','2'),
    ('Räpplinge','2'),
    ('Rödjenäs','2'),
    ('S:ta Gertruds kyrka ','2'),
    ('Skatelövs torp','2'),
    ('Skedebäckshult','2'),
    ('Skoflickaren ','2'),
    ('Skrikebo','2'),
    ('Skäveryd','2'),
    ('Slammarp','2'),
    ('Smedbyn','2'),
    ('Strömsrum ','2'),
    ('Trollestorp','2'),
    ('Uranäs','2'),
    ('Viggesbo','2'),
    ('Vinäs','2'),
    ('Yxenhaga','2'),
    ('Övrabo','2'),
    ('Vaggeryd kommun','2'),
    ('Algutsboda socken','2'),
    ('Gamleby socken','2'),
    ('Gladhammar socken','2'),
    ('Hagshult socken','2'),
    ('Målilla socken','2'),
    ('Rumskulla socken','2'),
    ('Sjösås socken','2'),
    ('Södra Vi socken','2'),
    ('Växjö socken','2'),
    ('Abborre','2'),
    ('Ansvaret','2'),
    ('Diplomaten','2'),
    ('Gladhammar','2'),
    ('Kronobäck ','2'),
    ('kv Druvan/Dovhjorten','2'),
    ('Kvarnholmen','2'),
    ('Rostock','2'),
    ('Skirsnäs','2'),
    ('Tyresbo','2'),
    ('Vi ','2'),
    ('Västra kajen','2'),
    ('Åldermannen ','2');

-- INSERT INTO tbl_sample_group_sampling_contexts (sampling_context, description) VALUES
--     ('Dendrochronological building investigation','Investigation of wood for age determination, sampled in a historic building context'),
--     ('Dendrochronological archaeological sampling','Investigation of wood for age determination, sampled in an archaeological context');

INSERT INTO tbl_sample_location_types (location_type, location_type_description) VALUES
    ('Sampled section','A description of the sampled area. i.e. what building or what part of the building was sampled, and possibly its function. (e.g. Västtorn, östra ladan, kor, långhus).'),
    ('Building level','On what floor was the sample/-s retrieved.'),
    ('Room','In what room of the building was the sample/-s retrieved.'),
    ('Construction part','What type of construction part (e.g. wall, roof beam) was sampled.'),
    ('Sampled direction','Description of what direction the sampled area is (e.g. byggnadens östra sida, nära norra hörnet).'),
    ('Sampled area','Description of the area in the room/building that was sampled (e.g. dörr, under trappan, takstol).'),
    ('Sampled object','Description of the object, or part of object, was sampled (e.g. 3:e timmervarv, sparre, grov bjälke, dörrkarm). ');

INSERT INTO tbl_feature_types (feature_type_name, feature_type_description) VALUES
    ('Barrier', DEFAULT),
    ('Beam', DEFAULT),
    ('Border marker', DEFAULT),
    ('Bridge', DEFAULT),
    ('Collection pit (tar)', DEFAULT),
    ('Container', DEFAULT),
    ('Doorsill timber', DEFAULT),
    ('Dragare (translation pending)', DEFAULT),
    ('Fill layer', DEFAULT),
    ('Floor joist', DEFAULT),
    ('Gabion','Cage, cylinder or box filled with rocks, concrete or sometimes sand and soil for use in civil engineering, road building, military application and landscaping'),
    ('Grillage ','A framework of timber or steel for support in marshy or treacherous soil '),
    ('Horse gin', DEFAULT),
    ('Jetty/Quay', DEFAULT),
    ('Palisade(in water)', DEFAULT),
    ('Pile bridge', DEFAULT),
    ('Pile of logs', DEFAULT),
    ('Pilings', DEFAULT),
    ('Platform', DEFAULT),
    ('Pole', DEFAULT),
    ('Post', DEFAULT),
    ('Quay', DEFAULT),
    ('Revetment', DEFAULT),
    ('Road construction', DEFAULT),
    ('Roast bed','Deposits resulting from the roasting of ore.'),
    ('Sill', DEFAULT),
    ('Sill log', DEFAULT),
    ('Sill or foundation', DEFAULT),
    ('Slag deposit','Deposits of slag resulting from metal production.'),
    ('Stone sill', DEFAULT),
    ('Storage pit', DEFAULT),
    ('Tar funnel', DEFAULT),
    ('Timber', DEFAULT),
    ('Timber storage', DEFAULT),
    ('Top-board (Pipe organ)', DEFAULT),
    ('Water gutter', DEFAULT),
    ('Wooden feature', DEFAULT),
    ('Wooden floor', DEFAULT),
    ('Wooden house foundation', DEFAULT),
    ('Wooden plank', DEFAULT),
    ('Wooden sill', DEFAULT),
    ('Wooden trackway', DEFAULT),
    ('Wooden tub', DEFAULT),
    ('Wooden wall', DEFAULT),
    ('Profile ','A wall of a trench/test pit in an archaeological excavation, depicting the layers at the site and often sampled.'),
    ('Excavation area', DEFAULT);


DO $$
DECLARE v_data_type_group int;
BEGIN

	INSERT INTO tbl_data_type_groups (data_type_group_name, description) VALUES
		('Geographical','Geographical data either as a value or as a string.')
			RETURNING data_type_group_id INTO v_data_type_group;

	INSERT INTO tbl_data_types (data_type_group_id, data_type_name, definition) VALUES
		(v_data_type_group, 'Estimated Years','Dates that are an estimation'),
		(v_data_type_group, 'Composite date','A date which may include other information than the age, such as season, terminus and/or error margin.'),
		(v_data_type_group, 'Approximate location','Geographical location given as approximate values or text. May include multiple levels, text strings and exclusions (e.g. not Poland).');

END $$;

INSERT INTO tbl_dataset_masters (master_name, url) VALUES
    ('The Laboratory for Wood Anatomy and Dendrochronology (Lund)','https://www.geology.lu.se/research/laboratories-equipment/the-laboratory-for-wood-anatomy-and-dendrochronology');

INSERT INTO tbl_dendro_lookup (method_id, name, description) VALUES
    (10, 'Tree species', 'Species name of the tree the sample came from.'),
    (10, 'Tree rings', 'Number of tree rings inferred as years.'),
    (10, 'earlywood/late wood', 'A notation on whether the outermost part of the tree grew early in the growing season or late in the growing season.'),
    (10, 'No. of radius ', 'Number of radius analysed.'),
    (10, '3 time series', 'A notation on whether 3 time series have been analysed for the sample. '),
    (10, 'Sapwood (Sp)', 'The outer layers of a tree, between the pith and the cambium. '),
    (10, 'Bark (B)', 'Whether bark was present in the sample. '),
    (10, 'Waney edge (W)', 'The last formed tree ring before felling or sampling. Presence of this represents the last year of growth.'),
    (10, 'Pith (P)', 'The central core of a tree stem or twig.'),
    (10, 'Tree age ≥', 'The analysed age of the tree.'),
    (10, 'Tree age ≤', 'The analysed age of the tree.'),
    (10, 'Inferred growth year ≥', 'The growth year inferred from the analysed tree rings. '),
    (10, 'Inferred growth year ≤', 'The growth year inferred from the analysed tree rings. '),
    (10, 'Estimated felling year', ' The felling year, inferred from the  analysed outermost tree-ring date'),
    (10, 'Estimated felling year, lower accuracy', ' The felling year, inferred from the  analysed tree rings, with lower accuracy'),
    (10, 'Provenance', 'The provenance of the sampled tree, inferred by comparing the sample with others. '),
    (10, 'Outermost tree-ring date', 'The date of the outermost tree-ring'),
    (10, 'Not dated', 'Used to mark samples as not having been succesfully dated, i. e. analysed but not dated'),
    (10, 'Date note', 'Notes on  a sample not dated'),
    (10, 'Provenance comment', 'Comments on the provenance of a sample');

INSERT INTO tbl_error_uncertainties (error_uncertainty_type, description) VALUES
    ('Ca','The error of a date is estimated as being "circa" (e.g. 1800 + ca 20 years)');

INSERT INTO tbl_age_types (age_type, description) VALUES
    ('AD','Anno Domini, Christian era; calendar era dates according to the Gregorian calendar.');

INSERT INTO tbl_season_or_qualifier (season_or_qualifier_type, description) VALUES
    ('Winter','Felling date estimated as being during the winter, which is the resting period of the tree'),
    ('Summer','Summer period (at most May to August) for the estimated felling date of a tree'),
    ('After','When the waney edge is missing in dendrochronological analysis the felling date is estimated after the date of the outermost tree ring');

INSERT INTO tbl_sample_description_types (type_name, type_description) VALUES
    ('Wood function','Function or format of the wood'),
    ('Wood shape','Information about how the wood has been handled (e.g. how has a log been split: full section, half section etc.)'),
    ('Wood processing markings','Information about potential processing grooves (e.g. axe grooves)'),
    ('Wood processing technique','Specification about the technique used to cause the wood markings'),
    ('Wood general markings','Information about wood markings not related to the processing of it (e.g. traces of paint)'),
    ('Wood reuse','Information about the potential reuse of the wood (e.g. house move, reused timber)');

INSERT INTO tbl_biblio (authors, year, title, full_reference) VALUES
    ('Andersson, Iwar','1967', 'Hagby fästningskyrka. Fornvännen, vol 62, 1967, s. 22-36.', 'Andersson, Iwar (1967). Hagby fästningskyrka. Fornvännen, vol 62, 1967, s. 22-36.'),
    ('Bartholin, Thomas','1985', 'Dendrokronologisk analyse af loftsbod, Bråtens gård, Taberg, Månsarp sn, Småland. Kvartärsgeologiska avdelningen, Lunds universitet, 1985-04-12.', 'Bartholin, Thomas (1985). Dendrokronologisk analyse af loftsbod, Bråtens gård, Taberg, Månsarp sn, Småland. Kvartärsgeologiska avdelningen, Lunds universitet, 1985-04-12.'),
    ('Bartholin, Thomas','1986', 'Dendrokronologisk datering af loft fra Vissingsö. Kvartärsgeologiska avdelningen, Lunds universitet, 1986-07-28.', 'Bartholin, Thomas (1986). Dendrokronologisk datering af loft fra Vissingsö. Kvartärsgeologiska avdelningen, Lunds universitet, 1986-07-28.'),
    ('Bartholin, Thomas','1987', 'Dendrokronologisk undersögelse af Appelbladska Smedjan, Huskvarna. Kvartärsgeologiska avdelningen, Lunds universitet, 1987-08-06.', 'Bartholin, Thomas (1987). Dendrokronologisk undersögelse af Appelbladska Smedjan, Huskvarna. Kvartärsgeologiska avdelningen, Lunds universitet, 1987-08-06.'),
    ('Bartholin, Thomas','1987', 'Dendrokronologisk undersögelse af loft vägplank fra Yxenhaga Gammelstuga med formodet oprindelse fra "Sanda k:a", nu magasinet på Brunstorp, Huskvarna. Kvartärsgeologiska avdelningen, Lunds universitet, 1987-08-10.', 'Bartholin, Thomas (1987). Dendrokronologisk undersögelse af loft vägplank fra Yxenhaga Gammelstuga med formodet oprindelse fra "Sanda k:a", nu magasinet på Brunstorp, Huskvarna. Kvartärsgeologiska avdelningen, Lunds universitet, 1987-08-10.'),
    ('Bartholin, Thomas','1987', 'Dendrokronologisk undersögelse af loft, Brunstorp, Huskvarna. Kvartärsgeologiska avdelningen, Lunds universitet, 1987-08-05.', 'Bartholin, Thomas (1987). Dendrokronologisk undersögelse af loft, Brunstorp, Huskvarna. Kvartärsgeologiska avdelningen, Lunds universitet, 1987-08-05.'),
    ('Bartholin, Thomas','1989', 'Dendrokronologisk datering af loft på Dädesjö hembygdsgård, Småland. Kvartärsgeologiska avdelningen, Lunds universitet, 1989-11-30.', 'Bartholin, Thomas (1989). Dendrokronologisk datering af loft på Dädesjö hembygdsgård, Småland. Kvartärsgeologiska avdelningen, Lunds universitet, 1989-11-30.'),
    ('Bartholin, Thomas','1992', 'Dendrokronologisk analyse af tagstolene over långhuset, Jät ka, Småland. Dendroprov nr. 75109-127. Kvartärsgeologiska avdelningen, Lunds universitet, 1992-11-05.', 'Bartholin, Thomas (1992). Dendrokronologisk analyse af tagstolene over långhuset, Jät ka, Småland. Dendroprov nr. 75109-127. Kvartärsgeologiska avdelningen, Lunds universitet, 1992-11-05.'),
    ('Bartholin, Thomas','1993', 'Dendrokronologisk analyse af  f d bostadshus på gården Högetorp, Döderhults sn, Småland. Kvartärsgeologiska avdelningen, Lunds universitet, 1993-01-16.', 'Bartholin, Thomas (1993). Dendrokronologisk analyse af  f d bostadshus på gården Högetorp, Döderhults sn, Småland. Kvartärsgeologiska avdelningen, Lunds universitet, 1993-01-16.'),
    ('Bartholin, Thomas','1993', 'Dendrokronologisk analyse af tagstolen i Nävelsjö kyrka. Kvartärsgeologiska avdelningen, Lunds universitet, 1993-02-04.', 'Bartholin, Thomas (1993). Dendrokronologisk analyse af tagstolen i Nävelsjö kyrka. Kvartärsgeologiska avdelningen, Lunds universitet, 1993-02-04.'),
    ('Bartholin, Thomas','1994', 'Dendrokronologisk analyse af fähus på "Sjöhorven", Målajord 1:7, Dädesjö sn. Kvartärsgeologiska avdelningen, Lunds universitet, 1994-08-30.', 'Bartholin, Thomas (1994). Dendrokronologisk analyse af fähus på "Sjöhorven", Målajord 1:7, Dädesjö sn. Kvartärsgeologiska avdelningen, Lunds universitet, 1994-08-30.'),
    ('Bartholin, Thomas','1994', 'Dendrokronologisk analyse af pröver fra bostadshus, "Pärlhuset", Bystad 1:2, Vetlanda sn. Kvartärsgeologiska avdelningen, Lunds universitet, 1994-11-03.', 'Bartholin, Thomas (1994). Dendrokronologisk analyse af pröver fra bostadshus, "Pärlhuset", Bystad 1:2, Vetlanda sn. Kvartärsgeologiska avdelningen, Lunds universitet, 1994-11-03.'),
    ('Bartholin, Thomas','1995', 'Dendrokronologisk analyse af gästgivaregården, Trollestorp 1:8, Annerstad. Kvartärsgeologiska avdelningen, Lunds universitet, 1995-05-10.', 'Bartholin, Thomas (1995). Dendrokronologisk analyse af gästgivaregården, Trollestorp 1:8, Annerstad. Kvartärsgeologiska avdelningen, Lunds universitet, 1995-05-10.'),
    ('Bartholin, Thomas','1995', 'Dendrokronologisk analyse af kv Näktergalen 3, Vimmerby sn, Småland. Kvartärsgeologiska avdelningen, Lunds universitet, 1995-02-15.', 'Bartholin, Thomas (1995). Dendrokronologisk analyse af kv Näktergalen 3, Vimmerby sn, Småland. Kvartärsgeologiska avdelningen, Lunds universitet, 1995-02-15.'),
    ('Bartholin, Thomas','1995', 'Dendrokronologisk analyse af soldattorpet  "Sjöhorven", Målajord 1:7, Dädesjö sn. Kvartärsgeologiska avdelningen, Lunds universitet, 1995-05-10.', 'Bartholin, Thomas (1995). Dendrokronologisk analyse af soldattorpet  "Sjöhorven", Målajord 1:7, Dädesjö sn. Kvartärsgeologiska avdelningen, Lunds universitet, 1995-05-10.'),
    ('Bartholin, Thomas','1996', 'Dendrokronologisk analys av Vinäs slott, Västra Eds sn, Småland. Nationalmuseet/NNU Köpenhamn, rapport 12 mars 1996.', 'Bartholin, Thomas (1996). Dendrokronologisk analys av Vinäs slott, Västra Eds sn, Småland. Nationalmuseet/NNU Köpenhamn, rapport 12 mars 1996.'),
    ('Barup, Kerstin & Iakobi, Johan','1995', 'Dackestugan på Kulturen i Lund. Byggnadsundersökning av Dacke stugan 1995. LTH-Arkitektur II, Bebyggelsevård.', 'Barup, Kerstin & Iakobi, Johan (1995). Dackestugan på Kulturen i Lund. Byggnadsundersökning av Dacke stugan 1995. LTH-Arkitektur II, Bebyggelsevård.'),
    ('Barup, Kerstin & Iakobi, Johan','1995', 'Dackestugan på Kulturen i Lund. Byggnadsundersökning av Dackestugan 1995. LTH-Arkitektur II, Bebyggelsevård.', 'Barup, Kerstin & Iakobi, Johan (1995). Dackestugan på Kulturen i Lund. Byggnadsundersökning av Dackestugan 1995. LTH-Arkitektur II, Bebyggelsevård.'),
    ('Boström, Ragnhild','1969', 'Källa kyrkor. Sveriges kyrkor, vol. 128. Öland 1:4.', 'Boström, Ragnhild (1969). Källa kyrkor. Sveriges kyrkor, vol. 128. Öland 1:4.'),
    ('Boström, Ragnhild','1972', 'Föra kyrkor. Sveriges kyrkor, vol. 142. Öland 1:6.', 'Boström, Ragnhild (1972). Föra kyrkor. Sveriges kyrkor, vol. 142. Öland 1:6.'),
    ('Boström, Ragnhild','1990', '"Räpplinge kyrka" ur: En bok om Räpplinge. Utgiven av Räpplinge Hembygdsförening 1990.', 'Boström, Ragnhild (1990). "Räpplinge kyrka" ur: En bok om Räpplinge. Utgiven av Räpplinge Hembygdsförening 1990.'),
    ('Eggertsson, Ólafur','1995', 'Dendrokronologisk analys. Kv Näktergalen 3, Vimmerby. Laboratoriet för Vedanatomi och Dendrokronologi, 1995-12-07.', 'Eggertsson, Ólafur (1995). Dendrokronologisk analys. Kv Näktergalen 3, Vimmerby. Laboratoriet för Vedanatomi och Dendrokronologi, 1995-12-07.'),
    ('Eggertsson, Ólafur','1998', 'Dendrokronologisk analys. Kristdala och norra Skåne. Laboratoriet för Vedanatomi och Dendrokronologi, 1998-11-20.', 'Eggertsson, Ólafur (1998). Dendrokronologisk analys. Kristdala och norra Skåne. Laboratoriet för Vedanatomi och Dendrokronologi, 1998-11-20.'),
    ('Eggertsson, Ólafur','1998', 'Dendrokronologisk analys. Norregård, Aneby, Vetlanda kommun. Laboratoriet för Vedanatomi och Dendrokronologi, 1998-08-24.', 'Eggertsson, Ólafur (1998). Dendrokronologisk analys. Norregård, Aneby, Vetlanda kommun. Laboratoriet för Vedanatomi och Dendrokronologi, 1998-08-24.'),
    ('Eggertsson, Ólafur','1998', 'Dendrokronologisk analys. Prover från fastigheten Rådmannen 2 i Kalmar. Laboratoriet för Vedanatomi och Dendrokronologi, 1998-04-08.', 'Eggertsson, Ólafur (1998). Dendrokronologisk analys. Prover från fastigheten Rådmannen 2 i Kalmar. Laboratoriet för Vedanatomi och Dendrokronologi, 1998-04-08.'),
    ('Eggertsson, Ólafur','1998', 'Dendrokronologisk analys. Skrikebo 1:29, Baggestorpskvarn. Laboratoriet för Vedanatomi och Dendrokronologi, 1998-10-20.', 'Eggertsson, Ólafur (1998). Dendrokronologisk analys. Skrikebo 1:29, Baggestorpskvarn. Laboratoriet för Vedanatomi och Dendrokronologi, 1998-10-20.'),
    ('Eggertsson, Ólafur','1998', 'Dendrokronologisk analys.Rödjenäs gård och torpstuga från Rödjenäs, Björkö sn. Laboratoriet för Vedanatomi och Dendrokronologi, 1998-08-24.', 'Eggertsson, Ólafur (1998). Dendrokronologisk analys.Rödjenäs gård och torpstuga från Rödjenäs, Björkö sn. Laboratoriet för Vedanatomi och Dendrokronologi, 1998-08-24.'),
    ('Eggertsson, Ólafur','1999', 'Dendrokronologisk analys. Aspagården, Västervik. Laboratoriet för Vedanatomi och Dendrokronologi, 1999-06-04.', 'Eggertsson, Ólafur (1999). Dendrokronologisk analys. Aspagården, Västervik. Laboratoriet för Vedanatomi och Dendrokronologi, 1999-06-04.'),
    ('Eggertsson, Ólafur','1999', 'Dendrokronologisk analys. Två prover från en stuga, Burseryd. Laboratoriet för Vedanatomi och Dendrokronologi, 1999-03-02.', 'Eggertsson, Ólafur (1999). Dendrokronologisk analys. Två prover från en stuga, Burseryd. Laboratoriet för Vedanatomi och Dendrokronologi, 1999-03-02.'),
    ('Eggertsson, Ólafur','2000', 'Dendrokronologisk analys. Klockstapel i Ljuder sn. Laboratoriet för Vedanatomi och Dendrokronologi, 2000-06-26.', 'Eggertsson, Ólafur (2000). Dendrokronologisk analys. Klockstapel i Ljuder sn. Laboratoriet för Vedanatomi och Dendrokronologi, 2000-06-26.'),
    ('Jonsson, Magdalena','2010', '”Gröna stugan”, kulturhistorisk utredning, kv Klyvaren 6, Ängö, Kalmar kn, Kalmar län, Småland. Kalmar läns museum, byggnadsantikvarisk rapport 2010.', 'Jonsson, Magdalena (2010). ”Gröna stugan”, kulturhistorisk utredning, kv Klyvaren 6, Ängö, Kalmar kn, Kalmar län, Småland. Kalmar läns museum, byggnadsantikvarisk rapport 2010.'),
    ('Lamke, Lotta','2010', 'Röda huset i Hyltan. Hyltan 1.3, Målilla sn, Kalmar län, Småland. Antikvarisk medverkan vid renovering av yttertak och skorsten. Kalmar läns museum, byggnadsantikvarisk rapport 2010.', 'Lamke, Lotta (2010). Röda huset i Hyltan. Hyltan 1.3, Målilla sn, Kalmar län, Småland. Antikvarisk medverkan vid renovering av yttertak och skorsten. Kalmar läns museum, byggnadsantikvarisk rapport 2010.'),
    ('Linderson, Hans & Eggertsson, Ólafur','1997', 'Dendrokronologisk analys. Datering av Grankvistgården i Vimmerby. Laboratoriet för Vedanatomi och Dendrokronologi, 1997-06-04.', 'Linderson, Hans & Eggertsson, Ólafur (1997). Dendrokronologisk analys. Datering av Grankvistgården i Vimmerby. Laboratoriet för Vedanatomi och Dendrokronologi, 1997-06-04.'),
    ('Linderson, Hans & Eggertsson, Ólafur','1997', 'Dendrokronologisk analys. Skedebäckshult, Smedjevik, Nybro. Laboratoriet för Vedanatomi och Dendrokronologi, 1997.', 'Linderson, Hans & Eggertsson, Ólafur (1997). Dendrokronologisk analys. Skedebäckshult, Smedjevik, Nybro. Laboratoriet för Vedanatomi och Dendrokronologi, 1997.'),
    ('Linderson, Hans & Eggertsson, Ólafur','1999', 'Dendrokronologisk analys. Göberga gård, Tranås kommun, huvudbyggnad och flygel. Laboratoriet för Vedanatomi och Dendrokronologi, 1999-10-27.', 'Linderson, Hans & Eggertsson, Ólafur (1999). Dendrokronologisk analys. Göberga gård, Tranås kommun, huvudbyggnad och flygel. Laboratoriet för Vedanatomi och Dendrokronologi, 1999-10-27.'),
    ('Linderson, Hans','2000', 'Dendrokronologisk analys. Timmerhus på Skrikebo 1:29 (övre våning tidigare daterad), Oskarshamn kn. Laboratoriet för Vedanatomi och Dendrokronologi, 2000-11-15.', 'Linderson, Hans (2000). Dendrokronologisk analys. Timmerhus på Skrikebo 1:29 (övre våning tidigare daterad), Oskarshamn kn. Laboratoriet för Vedanatomi och Dendrokronologi, 2000-11-15.'),
    ('Linderson, Hans','2001', 'Dendrokronologisk analys av ett hus i Bökhult, 15 km öster om Hyltebruk. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2001:49.', 'Linderson, Hans (2001). Dendrokronologisk analys av ett hus i Bökhult, 15 km öster om Hyltebruk. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2001:49.'),
    ('Linderson, Hans','2002', 'Dendrokronologisk analys av fastigheten Målajord 1:7, Dädesjö. Småland. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2002:51.', 'Linderson, Hans (2002). Dendrokronologisk analys av fastigheten Målajord 1:7, Dädesjö. Småland. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2002:51.'),
    ('Linderson, Hans','2002', 'Dendrokronologisk analys av Lilla Rätö gårds huvudbyggnad i Västervik. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2002:15.', 'Linderson, Hans (2002). Dendrokronologisk analys av Lilla Rätö gårds huvudbyggnad i Västervik. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2002:15.'),
    ('Linderson, Hans','2003', 'Dendrokronologisk analys av den ursprungliga huvudbyggnaden på Hellerö egendom, N Västervik. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2003:13.', 'Linderson, Hans (2003). Dendrokronologisk analys av den ursprungliga huvudbyggnaden på Hellerö egendom, N Västervik. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2003:13.'),
    ('Linderson, Hans','2003', 'Dendrokronologisk analys av huvudbyggnad, rättarbostad och bränneri i Viggesbo, Vimmerby. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2003:20.', 'Linderson, Hans (2003). Dendrokronologisk analys av huvudbyggnad, rättarbostad och bränneri i Viggesbo, Vimmerby. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2003:20.'),
    ('Linderson, Hans','2004', 'Dendrokronologisk analys av brandskadade fastigheten Ripan 10 i Vimmerby. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2004:24.', 'Linderson, Hans (2004). Dendrokronologisk analys av brandskadade fastigheten Ripan 10 i Vimmerby. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2004:24.'),
    ('Linderson, Hans','2004', 'Dendrokronologisk analys av Grankvistgården i Vimmerby. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2004:25.', 'Linderson, Hans (2004). Dendrokronologisk analys av Grankvistgården i Vimmerby. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2004:25.'),
    ('Linderson, Hans','2004', 'Dendrokronologisk analys av huvudbyggnad, rättarbostad, bränneri, mejeri samt västra och östra ladugårdslängorna i Viggesbo , Vimmerby. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2004:32.', 'Linderson, Hans (2004). Dendrokronologisk analys av huvudbyggnad, rättarbostad, bränneri, mejeri samt västra och östra ladugårdslängorna i Viggesbo , Vimmerby. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2004:32.'),
    ('Linderson, Hans','2007', 'Dendrokronologisk analys  av fastigheten Rådmannen 6, Kalmar. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2007:54.', 'Linderson, Hans (2007). Dendrokronologisk analys  av fastigheten Rådmannen 6, Kalmar. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2007:54.'),
    ('Linderson, Hans','2007', 'Dendrokronologisk analys av gamla arrendatorbostaden på Flöxhults säteri i Älghult. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2007:30.', 'Linderson, Hans (2007). Dendrokronologisk analys av gamla arrendatorbostaden på Flöxhults säteri i Älghult. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2007:30.'),
    ('Linderson, Hans','2008', 'Dendrokronologisk analys av ett gårdshus på Hattmakaren 6, Kvarnholmen, Kalmar. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2008:3.', 'Linderson, Hans (2008). Dendrokronologisk analys av ett gårdshus på Hattmakaren 6, Kvarnholmen, Kalmar. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2008:3.'),
    ('Linderson, Hans','2008', 'Dendrokronologisk analys av golvbjälklaget i mangårdsbyggnaden, Övrabo, Höreda socken, Eksjö. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2008:54.', 'Linderson, Hans (2008). Dendrokronologisk analys av golvbjälklaget i mangårdsbyggnaden, Övrabo, Höreda socken, Eksjö. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2008:54.'),
    ('Linderson, Hans','2008', 'Dendrokronologisk analys av stenkällaren på Kronobäcks klosterruin, Mönsterås. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2008:05.', 'Linderson, Hans (2008). Dendrokronologisk analys av stenkällaren på Kronobäcks klosterruin, Mönsterås. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2008:05.'),
    ('Linderson, Hans','2008', 'Dendrokronologisk analys av Vinäs "slott", Kalmar län. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2008:27.', 'Linderson, Hans (2008). Dendrokronologisk analys av Vinäs "slott", Kalmar län. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2008:27.'),
    ('Linderson, Hans','2008', 'Dendrokronologisk analys samt dito komplettering av fastigheten Rådmannen 6, Kalmar. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2008:8.', 'Linderson, Hans (2008). Dendrokronologisk analys samt dito komplettering av fastigheten Rådmannen 6, Kalmar. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2008:8.'),
    ('Linderson, Hans','2009', 'Dendrokronologisk analys av Dackestugan på Kulturen i Lund. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2009:62.', 'Linderson, Hans (2009). Dendrokronologisk analys av Dackestugan på Kulturen i Lund. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2009:62.'),
    ('Linderson, Hans','2009', 'Dendrokronologisk analys av huvudbyggnaden i Slammarp 1:14, Ingatorp, Eksjö kommun. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2009:13.', 'Linderson, Hans (2009). Dendrokronologisk analys av huvudbyggnaden i Slammarp 1:14, Ingatorp, Eksjö kommun. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2009:13.'),
    ('Linderson, Hans','2009', 'Dendrokronologisk analys av mangårdsbyggnaden på Skatelövs torp 5:9 i Alvesta kommun. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2009:70.', 'Linderson, Hans (2009). Dendrokronologisk analys av mangårdsbyggnaden på Skatelövs torp 5:9 i Alvesta kommun. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2009:70.'),
    ('Linderson, Hans','2009', 'Dendrokronologisk analys av västra ladan och "svinhuset" på Viggesbo, Vimmerby. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2009:23.', 'Linderson, Hans (2009). Dendrokronologisk analys av västra ladan och "svinhuset" på Viggesbo, Vimmerby. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2009:23.'),
    ('Linderson, Hans','2010', 'Dendrokronologisk analys av bårhuset, sannolikt en före detta tiondebod, vid Mortorp kyrka.. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:13.', 'Linderson, Hans (2010). Dendrokronologisk analys av bårhuset, sannolikt en före detta tiondebod, vid Mortorp kyrka.. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:13.'),
    ('Linderson, Hans','2010', 'Dendrokronologisk analys av ett hanband i gamla Källa kyrkas vapenhus, Öland. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:45.', 'Linderson, Hans (2010). Dendrokronologisk analys av ett hanband i gamla Källa kyrkas vapenhus, Öland. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:45.'),
    ('Linderson, Hans','2010', 'Dendrokronologisk analys av fastigheten Klyvaren 6 i Kalmar. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:24.', 'Linderson, Hans (2010). Dendrokronologisk analys av fastigheten Klyvaren 6 i Kalmar. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:24.'),
    ('Linderson, Hans','2010', 'Dendrokronologisk analys av fiskarstugan Näset 1 på Stensö, Kalmar. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:38.', 'Linderson, Hans (2010). Dendrokronologisk analys av fiskarstugan Näset 1 på Stensö, Kalmar. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:38.'),
    ('Linderson, Hans','2010', 'Dendrokronologisk analys av Föra kyrkas västtorn, Öland. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:44.', 'Linderson, Hans (2010). Dendrokronologisk analys av Föra kyrkas västtorn, Öland. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:44.'),
    ('Linderson, Hans','2010', 'Dendrokronologisk analys av Hagby kyrka, Kalmar. Nationella laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2001:35.', 'Linderson, Hans (2010). Dendrokronologisk analys av Hagby kyrka, Kalmar. Nationella laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2001:35.'),
    ('Linderson, Hans','2010', 'Dendrokronologisk analys av Mangårdsbyggnaden på Lagerhamnska gården, Ålem, Mönsterås. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:59.', 'Linderson, Hans (2010). Dendrokronologisk analys av Mangårdsbyggnaden på Lagerhamnska gården, Ålem, Mönsterås. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:59.'),
    ('Linderson, Hans','2010', 'Dendrokronologisk analys av mangårdsbyggnaden på Skatelövs torp 5:9 i Alvesta kommun - komplettering. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:26.', 'Linderson, Hans (2010). Dendrokronologisk analys av mangårdsbyggnaden på Skatelövs torp 5:9 i Alvesta kommun - komplettering. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:26.'),
    ('Linderson, Hans','2010', 'Dendrokronologisk analys av mangårdsbyggnaden på Skäveryd 1:1, Vissefjärda, Småland. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:23.', 'Linderson, Hans (2010). Dendrokronologisk analys av mangårdsbyggnaden på Skäveryd 1:1, Vissefjärda, Småland. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:23.'),
    ('Linderson, Hans','2010', 'Dendrokronologisk analys av porten mellan långhuset och vapenhuset i Källa gamla kyrka på Öland. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:69.', 'Linderson, Hans (2010). Dendrokronologisk analys av porten mellan långhuset och vapenhuset i Källa gamla kyrka på Öland. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:69.'),
    ('Linderson, Hans','2011', 'Dendrokronologisk analys av Dackestugan på Kulturen i Lund - komplettering av golvplank. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2011:70.', 'Linderson, Hans (2011). Dendrokronologisk analys av Dackestugan på Kulturen i Lund - komplettering av golvplank. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2011:70.'),
    ('Linderson, Hans','2011', 'Dendrokronologisk analys av Mangårdsbyggnaden på fastigheten Hyltan 1:3 i Målilla, Kalmar län. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2011:62.', 'Linderson, Hans (2011). Dendrokronologisk analys av Mangårdsbyggnaden på fastigheten Hyltan 1:3 i Målilla, Kalmar län. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2011:62.'),
    ('Linderson, Hans','2011', 'Dendrokronologisk analys av prover från Rackargården, Kalmar. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2011:45.', 'Linderson, Hans (2011). Dendrokronologisk analys av prover från Rackargården, Kalmar. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2011:45.'),
    ('Linderson, Hans','2011', 'Dendrokronologisk analys av Räpplinge kyrkas västtorn, Öland. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:46.', 'Linderson, Hans (2011). Dendrokronologisk analys av Räpplinge kyrkas västtorn, Öland. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:46.'),
    ('Linderson, Hans','2012', 'Dendrokronologisk analys av Mocketorpsgården, Kulturen i Lund. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2012:13.', 'Linderson, Hans (2012). Dendrokronologisk analys av Mocketorpsgården, Kulturen i Lund. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2012:13.'),
    ('Linderson, Hans','2012', 'Dendrokronologisk analys av målat virke i magasinet på Brunstorp, Huskvarna. Är Öxnahaga (Yxenhagas) gammelstuga byggt av virke från den försvunna Sanda kyrka? Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2012:27.', 'Linderson, Hans (2012). Dendrokronologisk analys av målat virke i magasinet på Brunstorp, Huskvarna. Är Öxnahaga (Yxenhagas) gammelstuga byggt av virke från den försvunna Sanda kyrka? Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2012:27.'),
    ('Linderson, Hans','2012', 'Dendrokronologisk analys av torpet Försjö, Oset 1:2, Ryforsbruk, Bottnaryd. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2012:3.', 'Linderson, Hans (2012). Dendrokronologisk analys av torpet Försjö, Oset 1:2, Ryforsbruk, Bottnaryd. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2012:3.'),
    ('Magnusson, Gösta','2004', 'Sjöhorven : kulturhistoriska studier kring Målajords soldattorp i Dädesjö socken', 'Magnusson, Gösta (2004). Sjöhorven : kulturhistoriska studier kring Målajords soldattorp i Dädesjö socken'),
    ('Meissner, Katja ','2010', 'Dendrokronologisk datering av fiskestugan på fastigheten Näset 1, Stensö, Kalmar. Kalmar läns museum, rapport 2010.', 'Meissner, Katja  (2010). Dendrokronologisk datering av fiskestugan på fastigheten Näset 1, Stensö, Kalmar. Kalmar läns museum, rapport 2010.'),
    ('Meissner, Katja ','2010', 'Dendrokronologisk datering av Räpplinge kyrka, Räpplinge socken, Borgholm kommun, Öland. Kalmar läns museum, rapport 2010.', 'Meissner, Katja  (2010). Dendrokronologisk datering av Räpplinge kyrka, Räpplinge socken, Borgholm kommun, Öland. Kalmar läns museum, rapport 2010.'),
    ('Meissner, Katja & Jonsson, Magdalena','2011', 'Dendrokronologisk datering Skoflickaren 5, ”Rackargården”, Kvarnholmen, Kalmar kommun, Småland. Kalmar läns museum, rapport 2011.', 'Meissner, Katja & Jonsson, Magdalena (2011). Dendrokronologisk datering Skoflickaren 5, ”Rackargården”, Kvarnholmen, Kalmar kommun, Småland. Kalmar läns museum, rapport 2011.'),
    ('Meissner, Katja','2010', 'Dendrokronologisk datering av Föra kyrka, Föra socken, Borgholm kommun, Öland. Kalmar läns museum, rapport 2010.', 'Meissner, Katja (2010). Dendrokronologisk datering av Föra kyrka, Föra socken, Borgholm kommun, Öland. Kalmar läns museum, rapport 2010.'),
    ('Meissner, Katja','2010', 'Dendrokronologisk datering av Källa gamla kyrka, Källa socken, Borgholm kommun, Öland. Kalmar läns museum, rapport 2010.', 'Meissner, Katja (2010). Dendrokronologisk datering av Källa gamla kyrka, Källa socken, Borgholm kommun, Öland. Kalmar läns museum, rapport 2010.'),
    ('Meissner, Katja','2010', 'Dendrokronologisk datering av Lagerhamnska gården, Strömsrum 2:3, Ålem socken, Mönsterås kommun, Småland. Kalmar läns museum, rapport 2010.', 'Meissner, Katja (2010). Dendrokronologisk datering av Lagerhamnska gården, Strömsrum 2:3, Ålem socken, Mönsterås kommun, Småland. Kalmar läns museum, rapport 2010.'),
    ('Meissner, Katja','2010', 'Dendrokronologisk datering av långhusportalen i Källa gamla kyrka, Källa socken, Borgholm kommun, Öland. Kalmar läns museum, rapport 2010.', 'Meissner, Katja (2010). Dendrokronologisk datering av långhusportalen i Källa gamla kyrka, Källa socken, Borgholm kommun, Öland. Kalmar läns museum, rapport 2010.'),
    ('Molander, Örjan','2008', 'Arkiater Wahlboms hus, Kvarteret Rådmannen 6, Kvarnholmen, Kalmar kommun, Småland. Kalmar läns museum, byggnadsantikvarisk rapport 2008.', 'Molander, Örjan (2008). Arkiater Wahlboms hus, Kvarteret Rådmannen 6, Kvarnholmen, Kalmar kommun, Småland. Kalmar läns museum, byggnadsantikvarisk rapport 2008.'),
    ('Molander, Örjan','2008', 'Dendrokronologisk datering av gårdshus på fastigheten Hattmakaren 6, Kvarnholmen, Kalmar. Rapport 2008-02-28.', 'Molander, Örjan (2008). Dendrokronologisk datering av gårdshus på fastigheten Hattmakaren 6, Kvarnholmen, Kalmar. Rapport 2008-02-28.'),
    ('Molander, Örjan','2009', 'Dendrokronologisk datering av Vinäs, ”Slottet”, Västra Ed socken, Västerviks kommun, Kalmar län, Småland. Kalmar läns museum, rapport 2009.', 'Molander, Örjan (2009). Dendrokronologisk datering av Vinäs, ”Slottet”, Västra Ed socken, Västerviks kommun, Kalmar län, Småland. Kalmar läns museum, rapport 2009.'),
    ('Molander, Örjan','2010', 'F.d. Tiondebod vid Mortorp kyrka, Mortorp socken, Kalmar län, Växjö stift, Småland. Resultat från dendrokronologisk undersökning. Kalmar läns museum, kyrkoantikvarisk rapport 2010.', 'Molander, Örjan (2010). F.d. Tiondebod vid Mortorp kyrka, Mortorp socken, Kalmar län, Växjö stift, Småland. Resultat från dendrokronologisk undersökning. Kalmar läns museum, kyrkoantikvarisk rapport 2010.'),
    ('Palm, Veronika','2008', 'Silverskatten vid Hellerö. Rapport från arkeologisk undersökning. Hellerö 1:21, Västra Ed socken, Småland. Kalmar läns museum, Arkeologisk rapport 2008.', 'Palm, Veronika (2008). Silverskatten vid Hellerö. Rapport från arkeologisk undersökning. Hellerö 1:21, Västra Ed socken, Småland. Kalmar läns museum, Arkeologisk rapport 2008.'),
    ('Riksantikvarieämbetet','1981', 'Byggnadsminnen 1961-1978 - Förteckning över byggnadsminnen enligt lagen den 9 december 1960 (nr 690).  ', 'Riksantikvarieämbetet (1981). Byggnadsminnen 1961-1978 - Förteckning över byggnadsminnen enligt lagen den 9 december 1960 (nr 690).  '),
    ('Serlander, Daniel & Grimhammar, Daniel &  Nilsson, Nicholas','2011', 'Kronobäcks klosterkyrkoruin. Förundersökning inför byggandet av ny informationsbyggnad 2009-2010. Kronobäck 1:7, Mönsterås socken och kommun, Kalmar län. Kalmar läns museum, Arkeologisk rapport 2011:17.', 'Serlander, Daniel & Grimhammar, Daniel &  Nilsson, Nicholas (2011). Kronobäcks klosterkyrkoruin. Förundersökning inför byggandet av ny informationsbyggnad 2009-2010. Kronobäck 1:7, Mönsterås socken och kommun, Kalmar län. Kalmar läns museum, Arkeologisk rapport 2011:17.'),
    ('Tengö, Pär','2006', 'Gårdshus, Hattmakaren 6, Kalmar.', 'Tengö, Pär (2006). Gårdshus, Hattmakaren 6, Kalmar.'),
    ('Bartholin, Thomas','1991', 'Dendrokronologisk analyse af pröver fra Gammleby og Kalmar. Kvartärsgeologiska avdelningen, Lunds universitet, 1991-11-08.', 'Bartholin, Thomas. 1991. Dendrokronologisk analyse af pröver fra Gammleby og Kalmar. Kvartärsgeologiska avdelningen, Lunds universitet, 1991-11-08.'),
    ('Bartholin, Thomas','1991', 'Dendrokronologisk undersögelse af pålbron i Södra Vi sn, Vi 15:1, Småland. Kvartärsgeologiska avdelningen, Lunds universitet, 1991-09-25.', 'Bartholin, Thomas. 1991. Dendrokronologisk undersögelse af pålbron i Södra Vi sn, Vi 15:1, Småland. Kvartärsgeologiska avdelningen, Lunds universitet, 1991-09-25.'),
    ('Bartholin, Thomas','1991', 'Dendrokronologisk undersögelse av påle fra pålbro i Södra Vi sn. Kvartärsgeologiska avdelningen, Lunds universitet, 1991-04-23.', 'Bartholin, Thomas. 1991. Dendrokronologisk undersögelse av påle fra pålbro i Södra Vi sn. Kvartärsgeologiska avdelningen, Lunds universitet, 1991-04-23.'),
    ('Bartholin, Thomas','1992', 'Dendrokronologisk analyse af 2 päle fra Garpön, Rumskulla sn, Fl. nr 234. Kvartärsgeologiska avdelningen, Lunds universitet, 1992-10-26.', 'Bartholin, Thomas. 1992. Dendrokronologisk analyse af 2 päle fra Garpön, Rumskulla sn, Fl. nr 234. Kvartärsgeologiska avdelningen, Lunds universitet, 1992-10-26.'),
    ('Bartholin, Thomas','1994', 'Dendrokronologisk og vedanatomisk analyse af  pröver fra VA-schakt, Hamngatan, Gamleby, mars-april 1994. Kvartärsgeologiska avdelningen, Lunds universitet, 1994-06-24.', 'Bartholin, Thomas. 1994. Dendrokronologisk og vedanatomisk analyse af  pröver fra VA-schakt, Hamngatan, Gamleby, mars-april 1994. Kvartärsgeologiska avdelningen, Lunds universitet, 1994-06-24.'),
    ('Bartholin, Thomas','1995', 'Dendrokronologisk undersögelse af 2 päle fra bro ved Krönsberg Vi 15:1, Södra Vi sn, Småland. Kvartärsgeologiska avdelningen, Lunds universitet, 1995-01-17.', 'Bartholin, Thomas. 1995. Dendrokronologisk undersögelse af 2 päle fra bro ved Krönsberg Vi 15:1, Södra Vi sn, Småland. Kvartärsgeologiska avdelningen, Lunds universitet, 1995-01-17.'),
    ('Eggertsson, Ólafur & Linderson, Hans','1998', 'Dendrokronologisk analys. Träanläggning, troligen kavelbro, Gamleby, Kalmar län. Laboratoriet för Vedanatomi och Dendrokronologi, 1998-02-16.', 'Eggertsson, Ólafur & Linderson, Hans. 1998. Dendrokronologisk analys. Träanläggning, troligen kavelbro, Gamleby, Kalmar län. Laboratoriet för Vedanatomi och Dendrokronologi, 1998-02-16.'),
    ('Eggertsson, Ólafur','1996', 'Dendrokronologisk analys. Dendroprov från arkeologisk undersökning vid järnvägsstationen, Kalmar. Laboratoriet för Vedanatomi och Dendrokronologi, 1996-09-06.', 'Eggertsson, Ólafur. 1996. Dendrokronologisk analys. Dendroprov från arkeologisk undersökning vid järnvägsstationen, Kalmar. Laboratoriet för Vedanatomi och Dendrokronologi, 1996-09-06.'),
    ('Eggertsson, Ólafur','1996', 'Dendrokronologisk analys. Källarholmen, Mönsterås sn, Småland, Fornl.nr 82: prov nr 1-6. Kalmar, centralstation, Pålverk vid bastionen Christina Regina: påle 2 och 3. Laboratoriet för Vedanatomi och Dendrokronologi, 1996-01-11.', 'Eggertsson, Ólafur. 1996. Dendrokronologisk analys. Källarholmen, Mönsterås sn, Småland, Fornl.nr 82: prov nr 1-6. Kalmar, centralstation, Pålverk vid bastionen Christina Regina: påle 2 och 3. Laboratoriet för Vedanatomi och Dendrokronologi, 1996-01-11.'),
    ('Eggertsson, Ólafur','1997', 'Dendrokronologisk analys. Dendroprov från kv Åldermannen 19, Kalmar. Laboratoriet för Vedanatomi och Dendrokronologi, 1997-01-27.', 'Eggertsson, Ólafur. 1997. Dendrokronologisk analys. Dendroprov från kv Åldermannen 19, Kalmar. Laboratoriet för Vedanatomi och Dendrokronologi, 1997-01-27.'),
    ('Eggertsson, Ólafur','1997', 'Dendrokronologisk analys. Prov från bropåle, Kalmar. Laboratoriet för Vedanatomi och Dendrokronologi, 1997-01-10.', 'Eggertsson, Ólafur. 1997. Dendrokronologisk analys. Prov från bropåle, Kalmar. Laboratoriet för Vedanatomi och Dendrokronologi, 1997-01-10.'),
    ('Eggertsson, Ólafur','1998', 'Dendrokronologisk analys. Bryggkonstruktion, Kalmar län. Laboratoriet för Vedanatomi och Dendrokronologi, 1998-01-21.', 'Eggertsson, Ólafur. 1998. Dendrokronologisk analys. Bryggkonstruktion, Kalmar län. Laboratoriet för Vedanatomi och Dendrokronologi, 1998-01-21.'),
    ('Eggertsson, Ólafur','1998', 'Dendrokronologisk analys. Prover från Kvarnholmen 2:6, fästningsverk. Laboratoriet för Vedanatomi och Dendrokronologi, 1998-12-16.', 'Eggertsson, Ólafur. 1998. Dendrokronologisk analys. Prover från Kvarnholmen 2:6, fästningsverk. Laboratoriet för Vedanatomi och Dendrokronologi, 1998-12-16.'),
    ('Eggertsson, Ólafur','1998', 'Dendrokronologisk analys. Två prover från Rostockaholme, Kalmar län. Laboratoriet för Vedanatomi och Dendrokronologi, 1998-04-08.', 'Eggertsson, Ólafur. 1998. Dendrokronologisk analys. Två prover från Rostockaholme, Kalmar län. Laboratoriet för Vedanatomi och Dendrokronologi, 1998-04-08.'),
    ('Eggertsson, Ólafur','1999', 'Dendrokronologisk analys. Förhistorisk väganläggning, ev. vagndelar, Växjö sn. Laboratoriet för Vedanatomi och Dendrokronologi, 1999-05-25.', 'Eggertsson, Ólafur. 1999. Dendrokronologisk analys. Förhistorisk väganläggning, ev. vagndelar, Växjö sn. Laboratoriet för Vedanatomi och Dendrokronologi, 1999-05-25.'),
    ('Linderson, Hans','2002', 'Dendrokronologisk analys av bropålar i sjön Örken, centrala Småland. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2002:38', 'Linderson, Hans. 2002. Dendrokronologisk analys av bropålar i sjön Örken, centrala Småland. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2002:38'),
    ('Linderson, Hans','2004', 'Dendrokronologisk analys av Munkbron mot Nydalakloster,  Jönköping länd. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2004:03', 'Linderson, Hans. 2004. Dendrokronologisk analys av Munkbron mot Nydalakloster,  Jönköping länd. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2004:03'),
    ('Linderson, Hans','2007', 'Dendrokronologisk analys av byggrester från kvarteret Diplomaten, Jönköping. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2007:33.', 'Linderson, Hans. 2007. Dendrokronologisk analys av byggrester från kvarteret Diplomaten, Jönköping. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2007:33.'),
    ('Linderson, Hans','2008', 'Dendrokronologisk analys av byggrester från kvarteret Diplomaten, Jönköping. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2008:12.', 'Linderson, Hans. 2008. Dendrokronologisk analys av byggrester från kvarteret Diplomaten, Jönköping. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2008:12.'),
    ('Linderson, Hans','2008', 'Dendrokronologisk analys av en pålspärr vid Kronobäck, Mönsterås. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2008:10.', 'Linderson, Hans. 2008. Dendrokronologisk analys av en pålspärr vid Kronobäck, Mönsterås. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2008:10.'),
    ('Linderson, Hans','2008', 'Dendrokronologisk analys av stenkista från kvarteret Dovhjorten, Jönköping. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2008:59.', 'Linderson, Hans. 2008. Dendrokronologisk analys av stenkista från kvarteret Dovhjorten, Jönköping. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2008:59.'),
    ('Linderson, Hans','2009', 'Dendrokronologisk analys av en större slaggdeponi från Gladhammars gruvor. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2009:53.', 'Linderson, Hans. 2009. Dendrokronologisk analys av en större slaggdeponi från Gladhammars gruvor. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2009:53.'),
    ('Linderson, Hans','2009', 'Dendrokronologisk analys av rundtimmer från kvarteret Mästaren i Kalmar. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2009:71.', 'Linderson, Hans. 2009. Dendrokronologisk analys av rundtimmer från kvarteret Mästaren i Kalmar. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2009:71.'),
    ('Linderson, Hans','2009', 'Dendrokronologisk analys av virkesfynd från en arkeologisk utgrävning av kvarteret Ansvaret i Jönköping. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2009:32.', 'Linderson, Hans. 2009. Dendrokronologisk analys av virkesfynd från en arkeologisk utgrävning av kvarteret Ansvaret i Jönköping. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2009:32.'),
    ('Linderson, Hans','2010', 'Dendrokronologisk analys av en spontanläggning utanför befästningen i Kalmar, Kvarnholmen 2:2. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:71.', 'Linderson, Hans. 2010. Dendrokronologisk analys av en spontanläggning utanför befästningen i Kalmar, Kvarnholmen 2:2. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:71.'),
    ('Linderson, Hans','2010', 'Dendrokronologisk analys av en stabiliserande påle till stadsmuren från kvarteret Gesällen i Kalmar. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:42.', 'Linderson, Hans. 2010. Dendrokronologisk analys av en stabiliserande påle till stadsmuren från kvarteret Gesällen i Kalmar. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:42.'),
    ('Linderson, Hans','2010', 'Dendrokronologisk analys av träkistor mot vättern på kvarteret Abborren, Jönköping. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:6.', 'Linderson, Hans. 2010. Dendrokronologisk analys av träkistor mot vättern på kvarteret Abborren, Jönköping. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:6.'),
    ('Linderson, Hans','2010', 'Dendrokronologisk analys av virke från ett område (K) med tjärrframställningsanläggningar vid Målilla, väg 23. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapportnr. 2010:67.', 'Linderson, Hans. 2010. Dendrokronologisk analys av virke från ett område (K) med tjärrframställningsanläggningar vid Målilla, väg 23. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapportnr. 2010:67.'),
    ('Linderson, Hans','2010', 'Dendrokronologisk analys från en arkeologisk undersökning, Gota Media, Kalmar. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:62.', 'Linderson, Hans. 2010. Dendrokronologisk analys från en arkeologisk undersökning, Gota Media, Kalmar. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2010:62.'),
    ('Linderson, Hans','2011', 'Dendrokronologisk analys av byggrester från kvarteret Druvan/Dovhjorten, Jönköping. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr  2011:44.', 'Linderson, Hans. 2011. Dendrokronologisk analys av byggrester från kvarteret Druvan/Dovhjorten, Jönköping. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr  2011:44.'),
    ('Linderson, Hans','2011', 'Dendrokronologisk analys av en arkeologisk förundersökning vid västra kajen i Jönköping. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2011:49', 'Linderson, Hans. 2011. Dendrokronologisk analys av en arkeologisk förundersökning vid västra kajen i Jönköping. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2011:49'),
    ('Linderson, Hans','2011', 'Dendrokronologisk analys av virke från markanläggningar vid Gladhammars gruvor, Kalmar län. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2011:19.', 'Linderson, Hans. 2011. Dendrokronologisk analys av virke från markanläggningar vid Gladhammars gruvor, Kalmar län. Nationella Laboratoriet för Vedanatomi och Dendrokronologi, rapport nr 2011:19.'),
    (' Sandberg, Fredrik & Palm, Veronica & Nilsson, Nicholas med bidrag från GAL och SLU','2011', 'Gladhammars gruvor - Särskild arkeologisk undersökning 2010. Kalmar läns museum, Arkeologisk rapport 2011:19.', ' Sandberg, Fredrik & Palm, Veronica & Nilsson, Nicholas med bidrag från GAL och SLU. 2011. Gladhammars gruvor - Särskild arkeologisk undersökning 2010. Kalmar läns museum, Arkeologisk rapport 2011:19.'),
    (' Skoglund, Peter &  Lagerås, Per','2002', 'En vendeltida vagn från södra Småland - fyndet från Skirsnäs mosse i ny belysningning. Fornvännen, vol 97, 2002, s. 73-86.', ' Skoglund, Peter &  Lagerås, Per. 2002. En vendeltida vagn från södra Småland - fyndet från Skirsnäs mosse i ny belysningning. Fornvännen, vol 97, 2002, s. 73-86.'),
    ('Blohmé, Mats','2006', 'Christina Regina. Ölandskajen, Kvarnholmen, Fornl.nr 93, Småland. Arkeologisk förundersökning, 2001. Kalmar läns museum. Nationella rapportprojektet 2006. ', 'Blohmé, Mats. 2006. Christina Regina. Ölandskajen, Kvarnholmen, Fornl.nr 93, Småland. Arkeologisk förundersökning, 2001. Kalmar läns museum. Nationella rapportprojektet 2006. '),
    ('Bramstång, Carina & Tagesson, Göran','2011', 'Bastionen Gustavus Primus. Bevarade bastionsmurar inom fastigheten Kvarnholmen 2:5, RAÄ 93, Kalmar stad och kommun, Kalmar län. Arkeologisk förundersökning, UV öst rapport 2011:11.', 'Bramstång, Carina & Tagesson, Göran. 2011. Bastionen Gustavus Primus. Bevarade bastionsmurar inom fastigheten Kvarnholmen 2:5, RAÄ 93, Kalmar stad och kommun, Kalmar län. Arkeologisk förundersökning, UV öst rapport 2011:11.'),
    ('Gustafsson, Pierre &  Schütz, Berit','1998', ' Kulbackensmuseum, B. Schutz/P. Gustafsson. Arkeologisk undersökning på Storgatan NV om tingshuset. 98.08.26/MBL.', 'Gustafsson, Pierre &  Schütz, Berit. 1998.  Kulbackensmuseum, B. Schutz/P. Gustafsson. Arkeologisk undersökning på Storgatan NV om tingshuset. 98.08.26/MBL.'),
    ('Haltiner Nordström, Susanne','2009', 'Arkeologisk förundersökning. Kvarteret Dovhjorten. Inför nybyggnation inom RAÄ 50, stadsdelen Öster, Jönköpings stad. Jönköpings läns museum, rapport 2009:20. ', 'Haltiner Nordström, Susanne. 2009. Arkeologisk förundersökning. Kvarteret Dovhjorten. Inför nybyggnation inom RAÄ 50, stadsdelen Öster, Jönköpings stad. Jönköpings läns museum, rapport 2009:20. '),
    ('Heimdahl, Jens & Vestbö Franzén, Å. ','2009', 'Tyska madens gröna rum. Specialstudier till den arkeologiska undersökningen i kvarteret Diplomaten, RAÄ 50, Jönköpings stad. Jönköpings läns museum. Arkeologisk rapport 2009:41. ', 'Heimdahl, Jens & Vestbö Franzén, Å. . 2009. Tyska madens gröna rum. Specialstudier till den arkeologiska undersökningen i kvarteret Diplomaten, RAÄ 50, Jönköpings stad. Jönköpings läns museum. Arkeologisk rapport 2009:41. '),
    ('Hällström, Agneta ','2007', 'Rostockaholme. Rostock 1:4, Algutsboda socken, Emmaboda kommun, Småland. Fornl nr 79. Arkeologisk undersökning 1991 - 2001. Nationella rapportprojektet 2007,Kalmar läns museum, Rapport juni 2007.', 'Hällström, Agneta . 2007. Rostockaholme. Rostock 1:4, Algutsboda socken, Emmaboda kommun, Småland. Fornl nr 79. Arkeologisk undersökning 1991 - 2001. Nationella rapportprojektet 2007,Kalmar läns museum, Rapport juni 2007.'),
    ('Konsmar, Angelika','2011', 'Befästningskonstruktioner norr om kv Muren, Kvarnholmen 2:2 och del av 2:1, Kvarnholmen Kalmar, RAÄ 93, Kalmar domkyrkoförsamling, Kalmar stad och kommun, Kalmar län, Småland.  Arkeologisk förundersökning, UV öst rapport 2011:3.', 'Konsmar, Angelika. 2011. Befästningskonstruktioner norr om kv Muren, Kvarnholmen 2:2 och del av 2:1, Kvarnholmen Kalmar, RAÄ 93, Kalmar domkyrkoförsamling, Kalmar stad och kommun, Kalmar län, Småland.  Arkeologisk förundersökning, UV öst rapport 2011:3.'),
    ('Lamke, Lotta & Nilsson, Håkan','2004', 'Lamke , L. & Nilsson, H. 2004. Kulturhistorisk utredning av Gladhammarsgruvområde . Kalmar läns museum , Projekt Gladhammar, Rapport 2004:09. ', 'Lamke, Lotta & Nilsson, Håkan. 2004. Lamke , L. & Nilsson, H. 2004. Kulturhistorisk utredning av Gladhammarsgruvområde . Kalmar läns museum , Projekt Gladhammar, Rapport 2004:09. '),
    ('Lamke, Lotta','2005', 'Kv Magistern, Kvarnholmen. Kulturhistorisk utredning, Kalmar läns museum, Kalmar.', 'Lamke, Lotta. 2005. Kv Magistern, Kvarnholmen. Kulturhistorisk utredning, Kalmar läns museum, Kalmar.'),
    ('Lamke, Lotta','2010', 'Gesällen 25, Kvarnholmen 2:2 och del av Kvarnholmen 2:1 – Bebyggelsehistorisk översikt. Kalmar läns museum, Byggnadsantikvarisk rapport 2010.', 'Lamke, Lotta. 2010. Gesällen 25, Kvarnholmen 2:2 och del av Kvarnholmen 2:1 – Bebyggelsehistorisk översikt. Kalmar läns museum, Byggnadsantikvarisk rapport 2010.'),
    ('Nilsson, Nicholas & Källström, Michael','2009', 'Kv Åldermannen. Arkeologisk förundersökning 1996. Kv Åldermannen, Norra Långgatan, Kvarnholmen, Kalmar. Kalmar läns museum, Arkeologisk rapport 2009:22.', 'Nilsson, Nicholas & Källström, Michael. 2009. Kv Åldermannen. Arkeologisk förundersökning 1996. Kv Åldermannen, Norra Långgatan, Kvarnholmen, Kalmar. Kalmar läns museum, Arkeologisk rapport 2009:22.'),
    ('Nordman, Ann-Marie & Pettersson, Claes','2009', 'Arkeologisk förundersökning. Att öppna arkivet, inför planerad byggnation av ABM-hus inom del av kvarteret Diplomaten, Jönköpings stad, fornlämning RAÄ 50. Kristine församling i Jönköpings stad, Jönköpings län. Jönköpings läns museum. Arkeologisk rapport 2009:39. ', 'Nordman, Ann-Marie & Pettersson, Claes. 2009. Arkeologisk förundersökning. Att öppna arkivet, inför planerad byggnation av ABM-hus inom del av kvarteret Diplomaten, Jönköpings stad, fornlämning RAÄ 50. Kristine församling i Jönköpings stad, Jönköpings län. Jönköpings läns museum. Arkeologisk rapport 2009:39. '),
    ('Nordman, Ann-Marie & Pettersson, Claes  ','2009', 'Den centrala periferin. Arkeologisk undersökning i kvarteret Diplomaten, faktori- och hantverksgårdar i Jönköping 1620-1790, RAÄ 50, Jönköpings stad. Jönköpings läns museum. Arkeologisk rapport 2009:40. ', 'Nordman, Ann-Marie & Pettersson, Claes  . 2009. Den centrala periferin. Arkeologisk undersökning i kvarteret Diplomaten, faktori- och hantverksgårdar i Jönköping 1620-1790, RAÄ 50, Jönköpings stad. Jönköpings läns museum. Arkeologisk rapport 2009:40. '),
    ('Nordman, Ann-Marie & Pettersson, Claes & Heimdahl, Jens','2010', 'På denna blöta grund – 2,5 meter stadsarkeologi i ett kärr. SKAS, vol 2/2010', 'Nordman, Ann-Marie & Pettersson, Claes & Heimdahl, Jens. 2010. På denna blöta grund – 2,5 meter stadsarkeologi i ett kärr. SKAS, vol 2/2010'),
    ('Nordman, Ann-Marie','2010', 'Kv Abborren 2. Rapport över arkeologisk förundersökning inom fornlämning 50, Jönköpings stad, Jönköpings län. Jönköpings läns museum. Arkeologisk rapport 2010:61.', 'Nordman, Ann-Marie. 2010. Kv Abborren 2. Rapport över arkeologisk förundersökning inom fornlämning 50, Jönköpings stad, Jönköpings län. Jönköpings läns museum. Arkeologisk rapport 2010:61.'),
    ('Nordström, Annika  &  Tagesson, Göran','2009', 'Stadslager inom kv Mästaren på Kvarnholmen. Kv Mästaren 5-8, 21-22, RAÄ 93,Kalmar stad och kommun, Kalmar län. Arkeologisk förundersökning, UV öst rapport 2009:31.', 'Nordström, Annika  &  Tagesson, Göran. 2009. Stadslager inom kv Mästaren på Kvarnholmen. Kv Mästaren 5-8, 21-22, RAÄ 93,Kalmar stad och kommun, Kalmar län. Arkeologisk förundersökning, UV öst rapport 2009:31.'),
    ('Palm, Veronika & Åstrand, Johan & Danielsson, Peter','2011', 'Boplatslämningar, kolningsgropar och tjärdalar. Arkeologisk förundersökning och särskild undersökning 2010. Förbifart Målilla - omläggning av väg 23/47, Målilla socken, Hultsfreds kommun. Kalmar läns museum, Arkeologisk rapport 2011:05.', 'Palm, Veronika & Åstrand, Johan & Danielsson, Peter. 2011. Boplatslämningar, kolningsgropar och tjärdalar. Arkeologisk förundersökning och särskild undersökning 2010. Förbifart Målilla - omläggning av väg 23/47, Målilla socken, Hultsfreds kommun. Kalmar läns museum, Arkeologisk rapport 2011:05.'),
    ('Rajala, Eeva','2006', 'Källarholmen. Källarholmen, Mönsterås socken, Mönsterås kommun, Småland. Fornl nr 82, Arkeologisk undersökning, 1994, Dendroprovtagning, 1995. Rapport december 2006, Kalmar läns museum. Nationella rapportprojektet 2006.', 'Rajala, Eeva. 2006. Källarholmen. Källarholmen, Mönsterås socken, Mönsterås kommun, Småland. Fornl nr 82, Arkeologisk undersökning, 1994, Dendroprovtagning, 1995. Rapport december 2006, Kalmar läns museum. Nationella rapportprojektet 2006.'),
    ('Rubensson, Leif & Åstrand, Johan','2007', 'Gamleby. Fornlämning 450, Gamleby sn, Västerviks kommun, Småland. Arkeologiska förundersökningar 1991 och 1994. Kalmar läns museum. Nationella rapportprojektet 2007. ', 'Rubensson, Leif & Åstrand, Johan. 2007. Gamleby. Fornlämning 450, Gamleby sn, Västerviks kommun, Småland. Arkeologiska förundersökningar 1991 och 1994. Kalmar läns museum. Nationella rapportprojektet 2007. '),
    ('Sandberg, Fredrik & Palm, Veronika & Carlsson, Eva & Nilsson, Nicholas','2009', 'Gladhammars gruvor. Arkeologisk förundersökning 2009. Gladhammars gruvområde, RAÄ 155 och 229, samt hyttområde, RAÄ 277. Gladhammars socken, Västerviks kommun, Kalmar län. Kalmar läns museum, rapport 2009:52. ', 'Sandberg, Fredrik & Palm, Veronika & Carlsson, Eva & Nilsson, Nicholas. 2009. Gladhammars gruvor. Arkeologisk förundersökning 2009. Gladhammars gruvområde, RAÄ 155 och 229, samt hyttområde, RAÄ 277. Gladhammars socken, Västerviks kommun, Kalmar län. Kalmar läns museum, rapport 2009:52. '),
    ('Stibéus, Magnus & Tagesson, Göran','2008', 'Bebyggelse och kulturlager från 1600-tal fram till idag vid Norra Munksjöstranden. RAÄ 50, kv Ansvaret 5 och 6, Jönköpings stad och kommun, Jönköpings län. Arkeologisk förundersökning, UV öst rapport 2008:4.', 'Stibéus, Magnus & Tagesson, Göran. 2008. Bebyggelse och kulturlager från 1600-tal fram till idag vid Norra Munksjöstranden. RAÄ 50, kv Ansvaret 5 och 6, Jönköpings stad och kommun, Jönköpings län. Arkeologisk förundersökning, UV öst rapport 2008:4.');

INSERT INTO tbl_contacts (address_1, address_2, first_name, last_name, email, url, location_id) VALUES
    ('Knadriks Kulturbygg','Blekinge, Skåne', 'Karl-Magnus', 'Melin', DEFAULT, 'http://www.knadrikskulturbygg.se/', 1004),
    ('The Laboratory for Wood Anatomy and Dendrochronology','Lund University', 'Hans', 'Linderson', 'hans.linderson@geol.lu.se', 'https://www.geology.lu.se/hans-linderson', DEFAULT),
    ('Byggkult: Byggnadsvård och kulturmiljö','Kalmar', 'Katja', 'Meissner', 'katja@byggkult.se', 'http://www.byggkult.se/kontakt/', DEFAULT),
    ('Kalmar läns museum','Kalmar stad', 'Nicholas', 'Nilsson', DEFAULT, 'http://www.kalmarlansmuseum.se/museet/personal/nicholas-nilsson/', DEFAULT),
    ('Kalmar läns museum','Kalmar', 'Lotta', 'Lamke', DEFAULT, 'http://www.kalmarlansmuseum.se/', DEFAULT),
    ('Kalmar läns museum','Kalmar', 'Magdalena', 'Jonsson', DEFAULT, 'http://www.kalmarlansmuseum.se/', DEFAULT),
    ('Kalmar läns museum','Kalmar', 'Max', 'Jahrehorn', DEFAULT, 'http://www.kalmarlansmuseum.se/', DEFAULT),
    ('Kalmar läns museum','Kalmar', 'Richard', 'Edlund', DEFAULT, 'http://www.kalmarlansmuseum.se/', DEFAULT),
    ('Kulturen','Lund', 'Örjan', 'Hörlin', DEFAULT, 'https://www.kulturen.com/', DEFAULT),
    ('Kalmar läns museum','Kalmar', 'Örjan', 'Molander', DEFAULT, 'http://www.kalmarlansmuseum.se/', DEFAULT),
    ('Länstyrelsen Jönköping län','Jönköping', 'Anders', 'Wallander', DEFAULT, DEFAULT, DEFAULT),
    ('CMB Uppdragsarkeologi AB ','Löddeköpinge', 'Bondesson Hvid', 'Bo', DEFAULT, 'https://se.linkedin.com/in/bo-bondesson-hvid-8866a4aa', DEFAULT),
    ('Hembygdsförening Oskarshamn-Döderhult', 'Kalmar', 'Torsten', 'Karlsson', DEFAULT, DEFAULT, DEFAULT),
    ('Kalmar läns museum','Kalmar stad', 'Eeva', 'Rajala', DEFAULT, DEFAULT, DEFAULT),
    ('Kalmar läns museum','Kalmar stad', 'Lars', 'Einarsson', DEFAULT, DEFAULT, DEFAULT),
    ('Kalmar läns museum','Kalmar stad', 'Mats', 'Pettersson', DEFAULT, DEFAULT, DEFAULT),
    ('Kalmar läns museum','Kalmar stad', 'Michael', 'Källström', DEFAULT, DEFAULT, DEFAULT),
    ('Smålands museum','Växjö', 'Peter', 'Skoglund', DEFAULT, DEFAULT, DEFAULT),
    ('Kalmar läns museum','Kalmar stad', 'Torbjörn', 'Sjögren', DEFAULT, DEFAULT, DEFAULT),
    ('Västerviks museum','Kulbacken', 'Pierre', 'Gustafsson', DEFAULT, DEFAULT, DEFAULT),
    ('Kalmar läns museum','Kalmar stad', 'Per', 'Olin', DEFAULT, DEFAULT, DEFAULT),
    ('Byggnadsvård Qvarnarp', DEFAULT, 'Sten', 'Janér', DEFAULT, 'http://www.byggnadsvardqvarnarp.se/', DEFAULT),
    ('The Laboratory for Wood Anatomy and Dendrochronology','Lund University', 'VDL', DEFAULT, DEFAULT, 'https://www.geology.lu.se/research/laboratories-equipment/the-laboratory-for-wood-anatomy-and-dendrochronology', DEFAULT),
    ('Riksantikvarieämbetet', DEFAULT, 'Peter', 'Sjömar', DEFAULT, DEFAULT, DEFAULT),
    (DEFAULT, DEFAULT, 'Harry', 'Bergensblad', DEFAULT, DEFAULT, DEFAULT),
    (DEFAULT, DEFAULT, 'Jarl', 'Karlsson', DEFAULT, DEFAULT, DEFAULT),
    (DEFAULT, DEFAULT, 'Lennart', 'Grandelius', DEFAULT, DEFAULT, DEFAULT),
    (DEFAULT, DEFAULT, 'Magnus', 'Samuelsson', DEFAULT, DEFAULT, DEFAULT),
    (DEFAULT, DEFAULT, 'Ólafur', 'Eggertsson', DEFAULT, DEFAULT, DEFAULT),
    (DEFAULT, DEFAULT, 'Thomas', 'Bartholin', DEFAULT, DEFAULT, DEFAULT),
    (DEFAULT, DEFAULT, 'Unspecified', DEFAULT, DEFAULT, DEFAULT, DEFAULT),
    (DEFAULT, DEFAULT, 'Private', DEFAULT, DEFAULT, DEFAULT, DEFAULT);

INSERT INTO tbl_project_types (project_type_name, description) VALUES
    ('Unclassified','A project of unknown character.');

INSERT INTO tbl_project_stages (stage_name, description) VALUES
    ('Dendrochronological study','An investigation using tree rings to determine the age of wood. Sampling in historic building investigation and archaeological contexts.');


COMMIT;

-- UPDATE ClearingHouse schema:
