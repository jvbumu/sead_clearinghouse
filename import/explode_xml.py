# -*- coding: utf-8 -*-
import logging
import psycopg2

logger = logging.getLogger('Excel XML processor')

def extract_xml_values(connection, submission_id):
    try:
        cursor = connection.cursor()
        logger.info('Extracting tables...')
        cursor.callproc('clearing_house.fn_extract_and_store_submission_tables', (submission_id,))
        logger.info('Extracting columns...')
        cursor.callproc('clearing_house.fn_extract_and_store_submission_columns', (submission_id,))
        logger.info('Extracting records...')
        cursor.callproc('clearing_house.fn_extract_and_store_submission_records', (submission_id,))
        logger.info('Extracting values...')
        cursor.callproc('clearing_house.fn_extract_and_store_submission_values', (submission_id,))
        cursor.connection.commit()
        cursor.close()
    except Exception as _:
        logger.exception('explode_xml')
        cursor.connection.rollback()
        cursor.close()
        raise

def copy_extracted_values_to_entity_table(connection, submission_id, p_dry_run=False, p_add_missing_columns=False):

    try:
        tables_names_sql = """
            Select Distinct t.table_name_underscored
            From clearing_house.tbl_clearinghouse_submission_tables t
            Join clearing_house.tbl_clearinghouse_submission_xml_content_tables c
            On c.table_id = t.table_id
            Where c.submission_id = %s
        """
        cursor = connection.cursor()

        cursor.execute(tables_names_sql, (submission_id,))
        table_names = cursor.fetchall()
        for table_name_underscored in table_names:

            logger.info('Processing table %s', table_name_underscored)

            if p_add_missing_columns:
                cursor.callproc('clearing_house.fn_add_new_public_db_columns', (submission_id, table_name_underscored))

            if not p_dry_run:
                cursor.callproc('clearing_house.fn_copy_extracted_values_to_entity_table', (submission_id, table_name_underscored))

            # logger.info('PERFORM clearing_house.fn_copy_extracted_values_to_entity_table(%s, ''%s'');', submission_id, table_name_underscored)

        cursor.connection.commit()
        cursor.close()

        set_submission_state(connection, submission_id, state_id=2)

    except Exception as _:
        logger.exception('copy_extracted_values_to_entity_table')
        cursor.connection.rollback()
        cursor.close()
        raise

def explode_xml_to_rdb(submission_id, **db_opts):
    connection = psycopg2.connect(**db_opts)
    extract_xml_values(connection, submission_id)
    copy_extracted_values_to_entity_table(connection, submission_id, p_dry_run=False, p_add_missing_columns=False)
    connection.close()

def set_submission_state(connection, submission_id, state_id=2, state_text='Pending'):

    try:
        update_sql = '''
            UPDATE clearing_house.tbl_clearinghouse_submissions
                SET submission_state_id = %s, status_text = ''%s''
            WHERE submission_id = %s
        '''
        cursor = connection.cursor()
        cursor.execute(update_sql, (submission_id, state_id, state_text, ))
        cursor.connection.commit()
        cursor.close()
    except Exception as _:
        logger.exception('set_submission_state')

def truncate_all_clearinghouse_entity_tables(**db_opts):
    connection = psycopg2.connect(**db_opts)
    cursor = connection.cursor()
    cursor.callproc('clearing_house.fn_truncate_all_entity_tables', ())
    cursor.connection.commit()
    cursor.close()
    connection.close()
