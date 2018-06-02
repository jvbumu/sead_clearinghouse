
CREATE USER clearinghouse_worker WITH
  LOGIN
  SUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  VALID UNTIL 'infinity'

GRANT sead_read TO clearinghouse_worker;

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