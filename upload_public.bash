#!/bin/bash
TARGET_HOST=snares.humlab.umu.se
DEPLOY_USER=roger
SCRIPT_FOLDER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REMOTE_FOLDER=projects/sead_clearinghouse

echo "Copying server files to ${TARGET_HOST}"
echo "Script folder is        ${SCRIPT_FOLDER}"

sftp ${TARGET_HOST} <<EOF
lcd ${SCRIPT_FOLDER}/dist
cd ${REMOTE_FOLDER}
put bundle.zip
put start_clearing_house.bash
exit
EOF

echo "Docker rebuild and install: start_clearing_house.bash --build"

