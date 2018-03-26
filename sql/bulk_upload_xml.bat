@Echo Off
SET SOURCE_DIR="C:\Users\roma0050\Google Drive\Project\Projects\VISEAD (Humlab)\Shared\SEAD Ceramics & Dendro\output"
SET SOURCE_FILE=ceramics_20180325-133051_tidy.xml

::For %%A in (%SOURCE_PATH%) do (
::    Set SOURCE_DIR="%%~dpA"
::    Set SOURCE_FILE=%%~nxA
::)
::echo.Folder is: "%SOURCE_DIR%"
::echo.Name is: %SOURCE_FILE%

SET DBHOST=snares.humlab.umu.se
SET DBNAME=sead_master_9_ceramics
SET DBUSER=clearinghouse_worker

SET PGCLIENTENCODING=utf-8
chcp 65001

cd %SOURCE_DIR%

IF EXIST .\temp_upload.txt DEL /F .\temp_upload.txt

@echo delete from clearing_house.tbl_clearinghouse_xml_temp; >> ./temp_upload.txt
@echo \lo_import '%SOURCE_FILE%'; > ./temp_upload.txt
@echo insert into clearing_house.tbl_clearinghouse_xml_temp (xmldata) values (clearing_house.xml_import(:LASTOID, true)); >> ./temp_upload.txt
@echo Select clearing_house.xml_transfer_bulk_upload(NULL,NULL,4); >> ./temp_upload.txt

psql --echo-queries --file=./temp_upload.txt --host=%DBHOST% --username=%DBUSER% --password --dbname=%DBNAME%

::del .\temp_upload.txt

@echo Import done!
pause
