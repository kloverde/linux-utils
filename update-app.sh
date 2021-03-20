#!/bin/bash

# update-app.sh
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


. require bash dirname basename printf wget tar chmod chown sudo tr

declare -r EXIT_CODE_REQUIRED_SOFTWARE_NOT_INSTALLED=1
declare -r EXIT_CODE_TMP_DIR_NOT_FOUND=2
declare -r EXIT_CODE_DOWNLOAD_FAILED=3
declare -r EXIT_CODE_EXTRACT_FAILED=4
declare -r EXIT_CODE_CHOWN_FAILED=5
declare -r EXIT_CODE_CHGRP_FAILED=6
declare -r EXIT_CODE_CHMOD_FAILED=7
declare -r EXIT_CODE_BACKUP_FAILED=8
declare -r EXIT_CODE_DIRECTORY_MOVE_FAILED=9
declare -r EXIT_CODE_DEST_DIR_NOT_EXIST=10
declare -r EXIT_CODE_USAGE=11
declare -r EXIT_CODE_COULD_NOT_CREATE_TEMP_DIR=12


main() {
   abort ${REQUIRE_ERR} ${EXIT_CODE_REQUIRED_SOFTWARE_NOT_INSTALLED}

   parseArgs "${@}"

   declare -r URL="${1}"

   declare -r LOCAL_DIR=`basename "${2}"`
   declare -r FILE=${LOCAL_DIR}.tar.bz2

   declare -r TEMP_DIR=/tmp
   declare -r TEMP_EXTRACT_PATH=${TEMP_DIR}/${LOCAL_DIR}

   declare -r DEST_DIR=`dirname "${2}"`
   declare -r DEST_PATH=${DEST_DIR}/${LOCAL_DIR}
   declare -r BACKUP_PATH=${DEST_DIR}/_${LOCAL_DIR}

   pushd ${TEMP_DIR} > /dev/null
   abort ${?} ${EXIT_CODE_TMP_DIR_NOT_FOUND} "{TEMP_DIR} doesn't exist"

   wget --no-verbose --show-progress -O ${FILE} --content-disposition ${URL}
   abort ${?} ${EXIT_CODE_DOWNLOAD_FAILED} "Download failed"

   mkdir -p ${TEMP_EXTRACT_PATH} > /dev/null
   abort ${?} ${EXIT_CODE_COULD_NOT_CREATE_TEMP_DIR} "Could not create temp directory ${TEMP_EXTRACT_PATH}"

   echo "Extracting..."

   tar -xf ${FILE} -C ${TEMP_EXTRACT_PATH}
   abort ${?} ${EXIT_CODE_EXTRACT_FAILED} "Extract failed.  Temp file `pwd`/${FILE} not removed."

   # Did the archive put everything in a container directory?

   contentListing=`ls -l ${TEMP_EXTRACT_PATH} | tail -n +2`

   if [[ `echo "${contentListing}" | wc -l` = 1 ]] && [[ `echo "${contentListing}" | cut -c 1` = "d" ]]
   then
      # Now we know that ${contentListing} is actually just the name of a parent directory we want to get rid of
      unwantedDir=`ls ${TEMP_EXTRACT_PATH}`

      pushd ${TEMP_EXTRACT_PATH}/${unwantedDir} > /dev/null
      mv * ..
      popd > /dev/null
      rmdir ${TEMP_EXTRACT_PATH}/${unwantedDir}
   fi

   echo "Cleaning up temp file..."

   rm ${FILE}
   warn ${?} "Warn:  Unable to delete temp file ${TEMP_DIR}/${FILE}"

   echo "Setting permissions..."

   sudo chown -R root ${LOCAL_DIR}
   abort ${?} ${EXIT_CODE_CHOWN_FAILED} "Chown failed.  Temp directory ${TEMP_EXTRACT_PATH} not removed."

   sudo chgrp -R root ${LOCAL_DIR}
   abort ${?} ${EXIT_CODE_CHGRP_FAILED} "Chgrp failed.  Temp directory ${TEMP_EXTRACT_PATH} not removed."

   sudo chmod 775 ${LOCAL_DIR}
   abort ${?} ${EXIT_CODE_CHMOD_FAILED} "Chmod failed.  Temp directory ${TEMP_EXTRACT_PATH} not removed."

   echo "Backing up current installation ${DEST_PATH} to ${BACKUP_PATH}..."

   sudo mv ${DEST_PATH} ${BACKUP_PATH}
   abort ${?} ${EXIT_CODE_BACKUP_FAILED} "Backup failed.  Temp directory ${TEMP_EXTRACT_PATH} not removed."

   echo "Moving ${TEMP_EXTRACT_PATH} to ${DEST_DIR}..."

   sudo mv ${LOCAL_DIR} ${DEST_DIR}
   abort ${?} ${EXIT_CODE_DIRECTORY_MOVE_FAILED} "Could not install to ${TEMP_EXTRACT_PATH}.  Temp directory ${TEMP_EXTRACT_PATH} not removed."

   printf "\nInstallation completed.\n\n"
   printf "Launch the application to confirm that everything's OK before proceeding.\n\n"

   . yesno "Remove backed-up installation?"

   if [ ${YESNO} = "Y" ]
   then
      sudo rm -rf ${BACKUP_PATH}
      warn ${?} "Warn:  Unable to remove backed-up installation ${BACKUP_PATH}"
   fi
}

# $1 exit code from executed command
# $2 exit code to return to the shell
# $3 error message to print
abort() {
   if [ ${1} -ne 0 ]
   then
      popd &> /dev/null
      echo ${3}
      exit ${2}
   fi
}

# $1 exit code from executed command
# $2 warning message to print
warn() {
   if [ ${1} -ne 0 ]
   then
      echo ${2}
   fi
}

parseArgs() {
   if [ ${#} != 2 ]
   then
      usage
      exit ${EXIT_CODE_USAGE}
   fi

   if [ ! -d "${2}" ]
   then
      echo "Directory ${2} not found"
      exit ${EXIT_CODE_DEST_DIR_NOT_EXIST}
   fi
}

usage() {
   echo "Usage:  `basename ${0}` [URL] [destination directory]"
}


main "${@}"
