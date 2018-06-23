
-- Select * From clearing_house.fn_dba_get_pk_constraints('public');
-- Select * From clearing_house.fn_dba_get_fk_constraints('public');
Select *
From clearing_house.fn_dba_get_sead_public_db_schema_new('public') A
Full Outer Join clearing_house.fn_dba_get_sead_public_db_schema_newer('public') B USING(table_name, column_name)
Where (A.ordinal_position <> B.ordinal_position) Or
(A.data_type <> B.data_type) Or
(A.numeric_precision <> B.numeric_precision) Or
(A.numeric_scale <> B.numeric_scale) Or
(A.character_maximum_length <> B.character_maximum_length) Or
(A.is_nullable <> B.is_nullable) Or
(A.is_pk <> B.is_pk)
;

Select * From clearing_house.fn_dba_get_sead_public_db_schema_new('public');

CREATE OR REPLACE FUNCTION clearing_house.fn_dba_get_sead_public_db_schema_new(p_schema_name text default 'public')
RETURNS TABLE (
    table_schema information_schema.sql_identifier,
    table_name information_schema.sql_identifier,
    column_name information_schema.sql_identifier,
    ordinal_position information_schema.cardinal_number,
    data_type information_schema.character_data,
    numeric_precision information_schema.cardinal_number,
    numeric_scale information_schema.cardinal_number,
    character_maximum_length information_schema.cardinal_number,
    is_nullable information_schema.yes_or_no,
    is_pk information_schema.yes_or_no
) LANGUAGE 'plpgsql'
AS $BODY$
Begin
	Return Query

    Select  p_schema_name::information_schema.sql_identifier,
            t.tablename::information_schema.sql_identifier,
            c.column_name::information_schema.sql_identifier,
            c.ordinal_position,
            c.data_type,
            c.numeric_precision,
            c.numeric_scale,
            c.character_maximum_length,
            c.is_nullable,
            Case When pk.column_name Is Null Then 'NO' Else 'YES' End::information_schema.yes_or_no
    From pg_tables t
    Join INFORMATION_SCHEMA.columns c
      On c.table_schema = t.schemaname
     And c.table_name = t.tablename
    Left Join clearing_house.fn_dba_get_pk_constraints('public') pk
      On pk.table_name = t.tablename
     And pk.column_name = c.column_name
    Where t.schemaname = p_schema_name;

End
$BODY$;
select * from clearing_house.fn_dba_get_sead_public_db_schema_newer('public')
CREATE OR REPLACE FUNCTION clearing_house.fn_dba_get_sead_public_db_schema_newer(p_schema_name text default 'public')
RETURNS TABLE (
    table_schema information_schema.sql_identifier,
    table_name information_schema.sql_identifier,
    column_name information_schema.sql_identifier,
    ordinal_position information_schema.cardinal_number,
    data_type information_schema.character_data,
    numeric_precision information_schema.cardinal_number,
    numeric_scale information_schema.cardinal_number,
    character_maximum_length information_schema.cardinal_number,
    is_nullable information_schema.yes_or_no,
    is_pk information_schema.yes_or_no,
    is_fk information_schema.yes_or_no,
    fk_table_name information_schema.sql_identifier,
    fk_column_name information_schema.sql_identifier
) LANGUAGE 'plpgsql'
AS $BODY$
Begin
	Return Query
    SELECT  pg_tables.schemaname::information_schema.sql_identifier AS table_schema,
        pg_tables.tablename::information_schema.sql_identifier AS table_name,
        pg_attribute.attname::information_schema.sql_identifier AS column_name, 
        pg_attribute.attnum::information_schema.cardinal_number AS ordinal_position,
        format_type(pg_attribute.atttypid, NULL)::information_schema.character_data AS data_type,
        CASE pg_attribute.atttypid
             WHEN 21 /*int2*/ THEN 16
             WHEN 23 /*int4*/ THEN 32
             WHEN 20 /*int8*/ THEN 64
             WHEN 1700 /*numeric*/ THEN
                  CASE WHEN pg_attribute.atttypmod = -1
                       THEN null
                       ELSE ((pg_attribute.atttypmod - 4) >> 16) & 65535     -- calculate the precision
                       END
             WHEN 700 /*float4*/ THEN 24 /*FLT_MANT_DIG*/
             WHEN 701 /*float8*/ THEN 53 /*DBL_MANT_DIG*/
             ELSE null
        END::information_schema.cardinal_number AS numeric_precision,
        CASE 
        WHEN pg_attribute.atttypid IN (21, 23, 20) THEN 0
        WHEN pg_attribute.atttypid IN (1700) THEN            
            CASE 
                WHEN pg_attribute.atttypmod = -1 THEN null       
                ELSE (pg_attribute.atttypmod - 4) & 65535            -- calculate the scale  
            END
           ELSE null
        END::information_schema.cardinal_number AS numeric_scale,
        CASE WHEN pg_attribute.atttypmod = -1 THEN NULL ELSE pg_attribute.atttypmod END::information_schema.cardinal_number AS character_maximum_length,
        CASE pg_attribute.attnotnull WHEN false THEN 'YES' ELSE 'NO' END::information_schema.yes_or_no AS is_nullable, 
        CASE WHEN pk.contype Is Null Then 'NO' Else 'YES' End::information_schema.yes_or_no AS is_pk,
        CASE WHEN fk.contype Is Null Then 'NO' Else 'YES' End::information_schema.yes_or_no AS is_fk,
        fk.confrelid::regclass::information_schema.sql_identifier AS fk_table_name,
        fkc.attname::information_schema.sql_identifier as fk_column_name
FROM pg_tables
JOIN pg_class 
  ON pg_class.relname = pg_tables.tablename 
JOIN pg_namespace ns
  ON ns.oid = pg_class.relnamespace
 AND ns.nspname  = pg_tables.schemaname
JOIN pg_attribute
  ON pg_class.oid = pg_attribute.attrelid 
 AND pg_attribute.attnum > 0 
LEFT JOIN pg_constraint pk
  ON pk.contype = 'p'::"char" 
 AND pk.conrelid = pg_class.oid
 AND (pg_attribute.attnum = ANY (pk.conkey)) 
LEFT JOIN pg_constraint AS fk
  ON fk.contype = 'f'::"char" 
 AND fk.conrelid = pg_class.oid 
 AND (pg_attribute.attnum = ANY (fk.conkey))
LEFT JOIN pg_attribute fkc
  ON fkc.attrelid = fk.confrelid
 AND fkc.attnum = fk.confkey[1]
WHERE TRUE 
  -- AND pg_tables.tableowner = "current_user"() 
  AND pg_attribute.atttypid <> 0::oid  
  AND pg_tables.schemaname = p_schema_name
ORDER BY table_name, ordinal_position ASC;

End
$BODY$;

