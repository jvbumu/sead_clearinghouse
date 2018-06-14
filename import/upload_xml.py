# -*- coding: utf-8 -*-
import psycopg2
import io
import logging

from explode_xml import extract_xml_values, copy_extracted_values_to_entity_table # , explode_xml_to_rdb

logger = logging.getLogger('Excel XML processor')

def insert_xml(connection, xml, submission_state_id=1, data_types='', upload_user_id=4, status_text='Pending'):
    insert_sql = """
        INSERT INTO clearing_house.tbl_clearinghouse_submissions(submission_state_id, data_types, upload_user_id, xml, status_text)
        VALUES (%s, %s, %s, %s, %s) RETURNING submission_id;
    """
    cursor = connection.cursor()
    cursor.execute(insert_sql, (submission_state_id, data_types, upload_user_id, xml, status_text))
    submission_id = cursor.fetchone()[0]
    cursor.connection.commit()
    cursor.close()
    return submission_id

def upload_xml(xml_filename, submission_state_id=1, data_types='', upload_user_id=4, **db_opts):

    connection = psycopg2.connect(**db_opts)

    with io.open(xml_filename, mode="r", encoding="utf-8") as f:
        xml = f.read()

    submission_id = insert_xml(connection, xml, submission_state_id=submission_state_id, data_types=data_types, upload_user_id=upload_user_id)

    extract_xml_values(connection, submission_id)
    copy_extracted_values_to_entity_table(connection, submission_id, p_dry_run=False, p_add_missing_columns=False)

    connection.close()
    return submission_id



