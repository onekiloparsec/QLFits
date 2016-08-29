#!/bin/sh

#  install.sh
#  QLFits3
#
#  Created by Cédric Foellmi on 11/03/15.
#  Copyright (c) 2015 onekiloparsec. All rights reserved.

#!/bin/sh

GENERATOR_NAME="QLFits3.qlgenerator"
DOWNLOAD_URL="https://github.com/onekiloparsec/QLFits/releases/download/3.1.2/${GENERATOR_NAME}.zip"
SYSTEM_QUICKLOOK_DIR="/Library/QuickLook"
LOCAL_QUICKLOOK_DIR="${HOME}/Library/QuickLook"
ZIP_FILE_PATH="${SYSTEM_QUICKLOOK_DIR}/${GENERATOR_NAME}.zip"

echo "\n *** Installing ${GENERATOR_NAME} into ${SYSTEM_QUICKLOOK_DIR}"

if [ -e "${LOCAL_QUICKLOOK_DIR}/${GENERATOR_NAME}" ]; then
    echo "\n >>> An old generator is located in ${LOCAL_QUICKLOOK_DIR}"
    echo " >>> You should remove it first, to avoid conflicts, and relaunch the same command."
    echo " >>> The new generator has to be installed in the system QuickLooks due to a bug in Yosemite."
    echo " >>> Here is the command to issue:\n$ rm -rf ${LOCAL_QUICKLOOK_DIR}/${GENERATOR_NAME}\n"
    exit 0
fi

echo " === Due to a bug on Yosemite, the new quicklook has to be installed in ${SYSTEM_QUICKLOOK_DIR}"
echo " === For that reason, your password might be requested below.\n"

sudo mkdir -p "${SYSTEM_QUICKLOOK_DIR}"
# curl -kL $DOWNLOAD_URL | /usr/bin/bsdtar -x -v -z -C "${SYSTEM_QUICKLOOK_DIR}"
echo "\n *** Downloading QLFits3 from https://github.com/onekiloparsec/QLFits..."
sudo curl -kL -# $DOWNLOAD_URL -o ${ZIP_FILE_PATH}
echo "\n *** QLFits3 successfully downloaded. Unzipping..."

sudo unzip -o -q ${ZIP_FILE_PATH} -d ${SYSTEM_QUICKLOOK_DIR}
if [ -s ${SYSTEM_QUICKLOOK_DIR}/${GENERATOR_NAME} ]
then
  echo " *** QLFits3 successfully unzipped. "
  sudo rm -f "${SYSTEM_QUICKLOOK_DIR}/${GENERATOR_NAME}.zip" >& /dev/null
else
  echo " *** Couldn't unzip the file: ${ZIP_FILE_PATH} ???"
  echo " *** Try restarting the script. Or send a mail to cedric@onekilopars.ec\n\n"
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

echo "\n *** QLFits3 successfuly installed! Enjoy. All inquiry to be sent to cedric@onekilopars.ec"
echo " *** More FITS utilities as well as awesome apps for astronomers: http://onekilopars.ec\n\n"
