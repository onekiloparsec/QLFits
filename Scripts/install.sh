#!/bin/sh

#  install.sh
#  QLFits3
#
#  Created by Cédric Foellmi on 11/03/15.
#  Copyright (c) 2015 onekiloparsec. All rights reserved.

#!/bin/sh

GENERATOR_NAME="QLFits3.qlgenerator"
DOWNLOAD_URL="https://github.com/onekiloparsec/QLFits/releases/download/3.0.3/${GENERATOR_NAME}.zip"
SYSTEM_QUICKLOOK_DIR="/Library/QuickLook"
LOCAL_QUICKLOOK_DIR="${HOME}/Library/QuickLook"

echo "\n *** Installing QLFits3.qlgenerator into /Library/QuickLook"

if [ -e "${LOCAL_QUICKLOOK_DIR}/${GENERATOR_NAME}" ]; then
    echo "\n >>> An old generator is located in ${LOCAL_QUICKLOOK_DIR}"
    echo " >>> You should remove it first, to avoid conflicts, and relaunch the same command."
    echo " >>> The new generator has to be installed in the system QuickLooks due to a bug in Yosemite."
    echo " >>> Here is the command to issue:\nrm -rf ${LOCAL_QUICKLOOK_DIR}/${GENERATOR_NAME}\n"
    exit 0
fi

echo " *** Due to a bug on Yosemite, the new quicklook has to be installed in ${SYSTEM_QUICKLOOK_DIR}"
echo " *** For that reason, your password might be requested below.\n"

sudo mkdir -p "${SYSTEM_QUICKLOOK_DIR}"
curl -L $DOWNLOAD_URL | tar xvz -C "${SYSTEM_QUICKLOOK_DIR}"
rm "${SYSTEM_QUICKLOOK_DIR}/${GENERATOR_NAME}.zip"

echo "\n *** QLFits3 successfull downloaded and unzipped. Now reseting the daemon."
qlmanage -r
echo "\n *** QLFits3 successfuly installed! Enjoy. All inquiry to be sent to cedric@onekilopars.ec\n"
