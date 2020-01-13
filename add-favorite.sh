#!/bin/sh


# add-favorite.sh
# https://www.github.com/kloverde/linux-utils
#
# Copyright (c) 2020, Kurtis LoVerde
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#    1. Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#    2. Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#    3. Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived from
#       this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


EXIT_CODE_SUCCESS=0
EXIT_CODE_INCORRECT_USAGE=1
EXIT_CODE_USER_ABORT=2
EXIT_CODE_FILE_NOT_FOUND=3
EXIT_CODE_FILE_EXISTS_IN_DESTINATION=4
EXIT_CODE_FAVORITE_ENTRY_ALREADY_EXISTS=5
EXIT_CODE_GSETTINGS_NOT_INSTALLED=6
EXIT_CODE_CHMOD_FAILED=7
EXIT_CODE_CHOWN_FAILED=8
EXIT_CODE_CHGRP_FAILED=9
EXIT_CODE_FILE_MOVE_FAILED=10
EXIT_CODE_GSETTINGS_FAILED=11

DEST_DIR=/usr/share/applications

if [ "`which gsettings`" = "" ]
then
   echo "This application requires gsettings.  Install it from your package manager and try again."
   exit ${EXIT_CODE_GSETTINGS_NOT_INSTALLED}
fi

if [ ${#} != 1 ]
then
   echo "Usage:  ${0} [.desktop file]"
   exit ${EXIT_CODE_INCORRECT_USAGE}
fi

launcherFullPath=`readlink -f "${1}"`

if [ -f "${launcherFullPath}" ]
then
   launcherFilename=`basename "${launcherFullPath}"`

   if [ -f "${DEST_DIR}/${launcherFilename}" ]
   then
      echo "File with matching name already exists in ${DEST_DIR}.  Aborting."
      exit ${EXIT_CODE_FILE_EXISTS_IN_DESTINATION}
   fi

   faves=`gsettings get org.gnome.shell favorite-apps`

   for f in `echo "${faves}" | sed -e "s/[][']//g"`
   do
      if [ "${launcherFilename}" = "${f}" ]
      then
         echo "Entry '${launcherFilename}' already exists as a favorite.  Aborting."
         exit ${EXIT_CODE_FAVORITE_ENTRY_ALREADY_EXISTS}
      fi
   done

   echo "This script will add a desktop launcher to your Gnome favorites."
   echo "As part of this process, the launcher will be moved, not copied,"
   echo "to /usr/share/applications, its owner and group will be changed"
   echo "to root, and its permissions will be set to -rw-r--r-- (644)."

   echo "\nCurrent favorites list:\n\n${faves}"

   newFaves="`echo "${faves}" | sed 's/\]$//'`, '${launcherFilename}']"

   echo "\nList will be updated to:\n\n${newFaves}"

   echo "\nIf the updated list contains a formatting error, DO NOT continue.\n"

   proceedWithUpdate=""

   while [ "${proceedWithUpdate}" != "Y" -a "${proceedWithUpdate}" != "N" ]
   do
      read -p "Proceed? (Y/N) " proceedWithUpdate
      proceedWithUpdate=`echo "${proceedWithUpdate}" | tr '[:lower:]' '[:upper:]'`
   done

   if [ "${proceedWithUpdate}" = "Y" ]
   then
      echo "\nSetting permissions..."

      sudo chmod 644 "${launcherFullPath}"
      rc=${?}

      if [ ${rc} != 0 ]
      then
         echo "Permission set failed with exit code ${rc}"
         exit ${EXIT_CODE_CHMOD_FAILED}
      fi

      sudo chown root "${launcherFullPath}"
      rc=${?}

      if [ ${rc} != 0 ]
      then
         echo "chown failed with exit code ${rc}"
         exit ${EXIT_CODE_CHOWN_FAILED}
      fi

      sudo chgrp root "${launcherFullPath}"
      rc=${?}

      if [ ${rc} != 0 ]
      then
         echo "chgrp failed with exit code ${rc}"
         exit ${EXIT_CODE_CHGRP_FAILED}
      fi

      echo "\nMoving file..."

      sudo mv "${launcherFullPath}" ${DEST_DIR}
      rc=${?}

      if [ ${rc} != 0 ]
      then
         echo "\nFile move failed with exit code ${rc}"
         exit ${EXIT_CODE_FILE_MOVE_FAILED}
      fi

      echo "\nUpdating gsettings database..."

      gsettings set org.gnome.shell favorite-apps "${newFaves}"
      rc=${?}

      if [ ${rc} != 0 ]
      then
         echo "gsettings failed with exit code ${rc}"
         exit ${EXIT_CODE_GSETTINGS_FAILED}
      else
         echo "\nFavorite added successfully."
         exit ${EXIT_CODE_SUCCESS}
      fi
   else
      exit ${EXIT_CODE_USER_ABORT}
   fi
else
   echo "File '${launcherFullPath}' doesn't exist"
   exit ${EXIT_CODE_FILE_NOT_FOUND}
fi

