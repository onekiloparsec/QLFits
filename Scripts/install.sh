#!/bin/sh

#  install.sh
#  QLFits3
#
#  Created by Cédric Foellmi on 11/03/15.
#  Copyright (c) 2015 onekiloparsec. All rights reserved.

#!/bin/sh

PLUGIN_VERSION="3.1.2"
GENERATOR_NAME="QLFits3.qlgenerator"
DOWNLOAD_URL="https://github.com/onekiloparsec/QLFits/releases/download/${PLUGIN_VERSION}/${GENERATOR_NAME}.zip"
SYSTEM_QUICKLOOK_DIR="/Library/QuickLook"
LOCAL_QUICKLOOK_DIR="${HOME}/Library/QuickLook"
ZIP_FILE_PATH="${SYSTEM_QUICKLOOK_DIR}/${GENERATOR_NAME}.zip"

echo "\n *** Installing ${GENERATOR_NAME} ${PLUGIN_VERSION} into ${SYSTEM_QUICKLOOK_DIR}"
echo " *** Installing in the system directory is mandatory for QLFits to work, sorry (otherwise, it has a weird bug preventing any display)."

if [ -e "${LOCAL_QUICKLOOK_DIR}/${GENERATOR_NAME}" ]; then
    echo "\n >>> An old generator is located in ${LOCAL_QUICKLOOK_DIR}"
    echo " >>> You should remove it first, to avoid conflicts, and relaunch the same command."
    echo " >>> Here is the command to issue:\nrm -rf ${LOCAL_QUICKLOOK_DIR}/${GENERATOR_NAME}\n"
    exit 1
fi

echo "\n *** Downloading QLFits3 from https://github.com/onekiloparsec/QLFits..."
echo " *** You may be prompted for your password."
sudo curl -kL -# ${DOWNLOAD_URL} -o ${ZIP_FILE_PATH}
echo "\n *** QLFits3 successfully downloaded. Unzipping..."

sudo unzip -o -q ${ZIP_FILE_PATH} -d ${SYSTEM_QUICKLOOK_DIR}
if [ -s ${SYSTEM_QUICKLOOK_DIR}/${GENERATOR_NAME} ]
then
  echo " *** QLFits3 successfully unzipped. "
  sudo rm -f "${SYSTEM_QUICKLOOK_DIR}/${GENERATOR_NAME}.zip" >& /dev/null
else
  echo " *** Couldn't unzip the file: ${ZIP_FILE_PATH} ???"
  echo " *** Try restarting the script. Or send a mail to cedric@onekiloparsec.dev\n\n"
  exit 1
fi

echo "\n *** Restarting the QuickLook daemon..."
qlmanage -r  >& /dev/null

echo " *** Restarting the QLFits Config Helper app (used for QLFits options)..."
killall QLFitsConfig >& /dev/null
open "${SYSTEM_QUICKLOOK_DIR}/${GENERATOR_NAME}/Contents/Helpers/QLFitsConfig.app" >& /dev/null
VAR_PID=`pgrep QLFitsConfig`
if [ -z "$VAR_PID" ]
then
  echo "For some reason, the helper app couldn't be started. Here is another attempt, with logs:"
  open "${SYSTEM_QUICKLOOK_DIR}/${GENERATOR_NAME}/Contents/Helpers/QLFitsConfig.app"
fi

echo "\n *** QLFits3 ${PLUGIN_VERSION} successfuly installed! Enjoy. All inquiries to be sent to cedric@onekiloparsec.dev"
echo " *** More FITS utilities as well as awesome apps for astronomers: http://onekiloparsec.dev\n\n"
