# -*- coding: utf-8 -*-
import os

extend = lambda a,b: a.update(b) or a
jj = os.path.join

db_opts = dict(
    database="sead_dev_clearinghouse",
    user=os.environ['SEAD_CH_USER'],
    password=os.environ['SEAD_CH_PASSWORD'],
    host="snares.humlab.umu.se",
    port=5432
)

source_folder = os.path.join(os.environ['HOMEPATH'], "Google Drive\\Project\\Projects\\VISEAD (Humlab)\\SEAD Ceramics & Dendro")

input_folder = os.path.join(source_folder, "input")
output_folder = os.path.join(source_folder, "output")

default_opt = dict(
    skip=False,
    input_folder=input_folder,
    output_folder=output_folder,
    meta_filename='metadata_latest.xlsx',
    table_names=None
)

run_opts = [
    extend(dict(default_opt), dict(
        meta_filename='metadata_latest.xlsx',
        data_filename='ceramics_data_latest.xlsm',
        submission_id=3,
        output_filename=jj(output_folder, 'ceramics_data_latest_20180704-131757_tidy.xml'),
        data_types='Ceramics'
    ))
]

