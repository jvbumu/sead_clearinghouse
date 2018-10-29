@Echo Off

Echo "This script is DEPRECATED and should not be used. It has been replaced by new features in process.py"
pause
goto :eof

SET SOURCE_DIR="C:\Users\roma0050\Google Drive\Project\Projects\VISEAD (Humlab)\SEAD Ceramics & Dendro\output"
REM SET SOURCE_FILE=tunnslipstabell_20180608_20180608-212746_tidy.xml
REM SET SOURCE_FILE=02_Ark_dendro_20180608_20180610-110946_tidy.xml
SET SOURCE_FILE=01_BYGG_20180608_20180609-120400_tidy.xml

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

echo psql --echo-queries --file=./temp_upload.txt --host=%DBHOST% --username=%DBUSER% --password --dbname=%DBNAME%

::del .\temp_upload.txt

@echo Import done!
pause
:eof