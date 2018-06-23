#!/bin/bash

DUMP_DATE=$(date +"%Y%m%d")
echo ${DUMP_DATE}
DUMP_FILENAME=${DUMP_DATE}_clearinghouse_schema.sql
DUMP_SERVER=dataserver.humlab.umu.se
DUMP_USER=clearinghouse_worker
DUMP_SCHEMA=clearing_house
DUMP_DATABASE=sead_master_8
DUMP_CMD=pg_dump.exe

pg_dump.exe --file ${DUMP_FILENAME} --host ${DUMP_SERVER} --port "5432" --username ${DUMP_USER} --schema=${DUMP_SCHEMA} --no-password --verbose --format=plain --schema-only --no-owner --no-privileges --no-tablespaces --no-unlogged-table-data --encoding "UTF8" ${DUMP_DATABASE}
