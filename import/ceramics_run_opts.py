# -*- coding: utf-8 -*-
import os
jj = os.path.join

db_opts = dict(
    database="sead_dev_clearinghouse",
    user=os.environ['SEAD_CH_USER'],
    password=os.environ['SEAD_CH_PASSWORD'],
    host="snares.humlab.umu.se",
    port=5432
)

source_folder = jj(os.environ['HOME'], "Google Drive\\Project\\Projects\\VISEAD (Humlab)\\SEAD Ceramics & Dendro")
# output_filename=jj(source_folder, 'output', 'ceramics_data_latest_20180628-071836_tidy.xml'),

run_opts = [
    dict(
        skip=False,
        input_folder=jj(source_folder, 'input'),
        output_folder=jj(source_folder, 'output'),
        meta_filename='metadata_latest.xlsx',
        data_filename='ceramics_data_latest.xlsm',
        data_types='Ceramics',
        table_names=None
    )
]
