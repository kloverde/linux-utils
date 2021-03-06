#!/bin/bash

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


. require bash getopt gsettings sudo sed basename readlink ln tr


declare -r EXIT_CODE_SUCCESS=0
declare -r EXIT_CODE_REQUIRED_SOFTWARE_NOT_INSTALLED=1
declare -r EXIT_CODE_INCORRECT_USAGE=2
declare -r EXIT_CODE_USER_ABORT=3
declare -r EXIT_CODE_FILE_NOT_FOUND=4
declare -r EXIT_CODE_FAVORITE_ENTRY_ALREADY_EXISTS=5
declare -r EXIT_CODE_LAUNCHER_ALREADY_INSTALLED=6
declare -r EXIT_CODE_CHMOD_FAILED=7
declare -r EXIT_CODE_CHOWN_FAILED=8
declare -r EXIT_CODE_CHGRP_FAILED=9
declare -r EXIT_CODE_FILE_MOVE_FAILED=10
declare -r EXIT_CODE_GSETTINGS_FAILED=11
declare -r EXIT_CODE_SYMBOLIC_LINK_FAILED=12

declare -r LAUNCHER_HOME_DIR=~/.local/share/applications
declare -r LAUNCHER_LINK_DIR=/usr/share/applications

shopt -s expand_aliases
alias echo="echo -e"


getGnomeSetting() {
   echo `gsettings get org.gnome.shell ${1}`
}

getGnomeFavorites() {
   echo `getGnomeSetting favorite-apps`
}

doesFavoriteExist() {
   faves=`getGnomeFavorites`

   for f in `echo "${faves}" | sed -e "s/[][',]//g"`
   do
      if [ "${f}" = "${1}" ]
      then
         return 1
      fi
   done

   return 0
}

addGnomeFavorite() {
   doesFavoriteExist "${1}"

   if [ ${?} = 0 ]
   then
      faves=`getGnomeFavorites`
      newFaves="`echo "${faves}" | sed 's/\]$//'`, '${1}']"

      echo "\nUpdating gsettings database..."

      gsettings set org.gnome.shell favorite-apps "${newFaves}"
      rc=${?}

      if [ ${rc} != 0 ]
      then
         echo "gsettings failed with exit code ${rc}"
         return ${EXIT_CODE_GSETTINGS_FAILED}
      fi

      echo "Database updated successfully\n\nFavorite added successfully"
   fi

   return ${EXIT_CODE_SUCCESS}
}

main() {
   launcherFullPath=`readlink -e "${2}"`

   if [ ${?} != 0 ]
   then
      echo "File '${2}' doesn't exist.  Aborting."
      return ${EXIT_CODE_FILE_NOT_FOUND}
   fi

   launcherFilename=`basename "${launcherFullPath}"`

   doesFavoriteExist "`basename ${2}`"

   if [ ${?} = 1 ]
   then
      if [ "${1}" = "--install" ]
      then
         echo "Your desktop is already configured with this launcher as a favorite.\n"

         if [ -f "${LAUNCHER_HOME_DIR}/${launcherFilename}" ]
         then
            echo "If you continue, the launcher in your home directory will be replaced.\n"
         fi
      fi

      . yesno "Do you want to continue?"

      if [ "${YESNO}" = "N" ]
      then
         return ${EXIT_CODE_FAVORITE_ENTRY_ALREADY_EXISTS}
      fi
   else
      . yesno "Confirm:  Make ${launcherFilename} a favorite app?"
   fi

   if [ "${YESNO}" = "Y" ]
   then
      if [ "${1}" = "--install" ]
      then
         echo "\nSetting permissions to rw-r--r-- ..."

         chmod 644 "${launcherFullPath}"
         rc=${?}

         if [ ${rc} = 0 ]
         then
            echo "Permissions set successfully"
         else
            echo "Permission set failed with exit code ${rc}"
            return ${EXIT_CODE_CHMOD_FAILED}
         fi

         mkdir -p "${LAUNCHER_HOME_DIR}"

         if [ "${launcherFullPath}" != "${LAUNCHER_HOME_DIR}/${launcherFilename}" ]
         then
            echo "\nMoving ${launcherFullPath} to ${LAUNCHER_HOME_DIR}..."

            mv "${launcherFullPath}" "${LAUNCHER_HOME_DIR}"
            rc=${?}

            if [ ${rc} = 0 ]
            then
               echo "File moved successfully\n"
            else
               echo "File move failed with exit code ${rc}"
               return ${EXIT_CODE_FILE_MOVE_FAILED}
            fi
         fi

         if [ -f "${LAUNCHER_LINK_DIR}/${launcherFilename}" ]
         then
            echo "A global launcher with a matching filename already exists in ${LAUNCHER_LINK_DIR}.\n"

            . yesno "Replace the global launcher with yours?  This could affect other users."
         else
            . yesno "Make this launcher available to others?"
         fi

         if [ "${YESNO}" = "Y" ]
         then
            echo "\nCreating symlink in ${LAUNCHER_LINK_DIR}..."

            if [ -f "${LAUNCHER_LINK_DIR}/${launcherFilename}" ]
            then
               sudo rm "${LAUNCHER_LINK_DIR}/${launcherFilename}"
            fi

            sudo ln -s "${LAUNCHER_HOME_DIR}/${launcherFilename}" --target-directory "${LAUNCHER_LINK_DIR}"
            rc=${?}

            if [ ${rc} = 0 ]
            then
               echo "Symlink created successfully"
            else
               echo "Unable to create symbolic link in ${LAUNCHER_LINK_DIR}.  Aborting."
               return ${EXIT_CODE_SYMBOLIC_LINK_FAILED}
            fi
         fi
      fi

      addGnomeFavorite "${launcherFilename}"
      return ${?}
   else
      return ${EXIT_CODE_USER_ABORT}
   fi
}

usage() {
   echo "Usage:  `basename ${0}` [[--install]] [.desktop file]\n"

   echo "OPTIONS\n"

   echo "--install     Moves the launcher to your home directory"
   echo "              and optionally creates a public symlink."
   echo "              If the file already exists in your home"
   echo "              directory and you just want to set it as"
   echo "              a favorite, omit this flag."
}

if [ ${REQUIRE_ERR} -ne 0 ]
then
   exit ${EXIT_CODE_REQUIRED_SOFTWARE_NOT_INSTALLED}
fi

if [ ${#} = 1 ]
then
   if [ "${1}" = "--usage" -o "${1}" = "--help" ]
   then
      usage
   else
      if [ "`echo ${1} | cut -c1-1`" = "-" ]
      then
         usage
         exit ${EXIT_CODE_INCORRECT_USAGE}
      fi

      main "--no-install" "${1}"
   fi
else
   if [ ${#} = 2 ]
   then
      if [ "${1}" = "--install" ]
      then
         main "${1}" "${2}"
      else
         usage
         exit ${EXIT_CODE_INCORRECT_USAGE}
      fi
   else
      usage
      exit ${EXIT_CODE_INCORRECT_USAGE}
   fi
fi

exit ${?}
