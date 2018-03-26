# -*- coding: utf-8 -*-

import pandas as pd
import numpy as np

'''
Script that reduces the size of Excel file by removing temporary sheets and excel formulas.
'''

meta_data_filename = './input/table metadata.xlsx'
data_filename = './input/tunnslipstabell - in progress 20170914.xlsm'
output_filename = './output/test.xlsx'

df_tables = pd.read_excel(meta_data_filename, 'Tables')
df_columns = pd.read_excel(meta_data_filename, 'Columns')

df_excel_sheetnames = df_tables.loc[np.logical_or(df_tables.OnlyNewData.notnull(), df_tables.NewData.notnull())]['ExcelSheet']

reader = pd.ExcelFile(data_filename)
writer = pd.ExcelWriter(output_filename)

for sheetname in df_excel_sheetnames:
    reader.parse(sheetname).to_excel(writer, sheetname, index=False)
    # break

writer.save()
