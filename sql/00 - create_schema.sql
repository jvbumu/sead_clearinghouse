/*****************************************************************************************************************************
**	What		User defined types and domains
**	Uses
**	Used By
**	Revisions
******************************************************************************************************************************/
DO $$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'clearinghouse_worker') THEN
        RAISE NOTICE 'create clearinghouse_worker must be run as superuser';
        -- CREATE USER clearinghouse_worker WITH LOGIN SUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION VALID UNTIL 'infinity';
        -- GRANT sead_read TO clearinghouse_worker;
   ELSE
        RAISE NOTICE 'clearinghouse_worker does exists';
   END IF;
END $$ LANGUAGE plpgsql;

/*****************************************************************************************************************************
**	Create "clearing_house" schema
******************************************************************************************************************************/

DROP SCHEMA IF EXISTS clearing_house CASCADE;

CREATE SCHEMA IF NOT EXISTS clearing_house AUTHORIZATION clearinghouse_worker;

/*****************************************************************************************************************************
**	Create	User defined types and domains
******************************************************************************************************************************/

-- DROP DOMAIN clearing_house.transport_crud_type;

CREATE DOMAIN clearing_house.transport_crud_type CHAR
    CHECK (VALUE IS NULL OR VALUE IN ('C', 'U', 'D'))
    DEFAULT NULL
    NULL;

/*****************************************************************************************************************************
**	Make sure all clearing_house schema objects are owned by clearinghouse_worker
******************************************************************************************************************************/

/*
--
-- CHANGE OWNER IF schema clearing_house EXISTS WITH WRONG OWNER
-- APPLY IF EXISTS BUT OWNED BY WRONG USER
--
SELECT tablename, 'ALTER TABLE '||schemaname||'.'||tablename||' OWNER TO clearinghouse_worker;'  FROM pg_tables where schemaname = 'clearing_house'

SELECT viewname, 'ALTER VIEW '||schemaname||'.'||viewname||' OWNER TO clearinghouse_worker;'
FROM pg_views where schemaname = 'clearing_house'

ALTER SCHEMA clearing_house OWNER TO clearinghouse_worker;

SELECT 'alter function ' || nsp.nspname || '.' || p.proname || '(' ||
     pg_get_function_identity_arguments(p.oid)||') owner to clearinghouse_worker;'
FROM pg_proc p
JOIN pg_namespace nsp ON p.pronamespace = nsp.oid
WHERE nsp.nspname = 'clearing_house';

*/