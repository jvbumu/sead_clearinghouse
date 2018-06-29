#!/bin/bash

DBHOST=snares.humlab.umu.se
DBPORT=5432
DBNAME=sead_dev_clearinghouse
DBUSER=${SEAD_CH_USER}

for i in "$@"; do
    case $i in
        -h=*|--dbhost=*); DBHOST="${i#*=}"; shift;;
        -p=*|--port=*); DBPORT="${i#*=}"; shift ;;
        -d=*|--dbname=*); DBNAME="${i#*=}"; shift;;
        -u=*|--dbuser=*); DBUSER="${i#*=}"; shift ;;
        *);;
    esac
done
echo "Deploy target ${DBNAME} on ${DBHOST}"

psql --host=$DBHOST --port=$DBPORT --username=$DBUSER --dbname=$DBNAME --password -v ON_ERROR_STOP=1 <<EOF
    BEGIN;

        SET client_min_messages TO WARNING;

        \i '00 - create_schema.sql'
        \i '00 - utility_functions.sql'
        \i '01 - transfer_sead_rdb_schema.sql'
        \i '02 - create_clearing_house_data_model.sql'
        \i '02 - populate_clearing_house_data_model.sql'

        SELECT clearing_house.fn_dba_create_clearing_house_db_model(FALSE);
        SELECT clearing_house.fn_dba_populate_clearing_house_db_model();

        \i '03 - create_rdb_entity_data_model.sql'

        SELECT clearing_house.fn_create_clearinghouse_public_db_model(FALSE, FALSE);

        \i '04 - explode_submission_xml_to_rdb.sql'
        \i '05 - client_review_ceramic_values.sql'
        \i '05 - client_review_dataset_data_procedures.sql'
        \i '05 - client_review_sample_data_procedures.sql'
        \i '05 - client_review_sample_group_data_procedures.sql'
        \i '05 - client_review_site_data_procedures.sql'
        \i '05 - report_procedures.sql'

        GRANT clearinghouse_worker TO mattias;

    END;
EOF
