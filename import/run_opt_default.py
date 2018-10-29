# -*- coding: utf-8 -*-
import os

extend = lambda a,b: a.update(b) or a

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

default_opt = dict(skip=False, input_folder=input_folder, output_folder=output_folder, meta_filename='metadata_latest.xlsx', table_names=None)

run_opts = [
    extend(dict(default_opt), dict(skip=True, data_filename='dendro_ark_data_latest.xlsm', data_types='Dendro ARKEO')),
    extend(dict(default_opt), dict(skip=True, data_filename='dendro_build_data_latest.xlsm', data_types='Dendro BYGG')),
    extend(dict(default_opt), dict(skip=False, data_filename='ceramics_data_latest.xlsm', data_types='Ceramics'))
]
