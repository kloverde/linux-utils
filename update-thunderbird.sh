#!/bin/bash

# update-thunderbird.sh
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


. require "bash"
. require "printf"
. require "wget"
. require "tar"
. require "chmod"
. require "chown"
. require "sudo"
. require "tr"    # dependency of yesno


URL="https://download.mozilla.org/?product=thunderbird-latest&os=linux64&lang=en-US"

LOCAL_DIR=thunderbird
FILE=${LOCAL_DIR}.tar.bz2

TEMP_DIR=/tmp
TEMP_EXTRACT_PATH=${TEMP_DIR}/${LOCAL_DIR}

DEST_DIR=/opt
DEST_PATH=${DEST_DIR}/${LOCAL_DIR}
BACKUP_PATH=${DEST_DIR}/_${LOCAL_DIR}

EXIT_CODE_REQUIRED_SOFTWARE_NOT_INSTALLED=1
EXIT_CODE_TMP_DIR_NOT_FOUND=2
EXIT_CODE_DOWNLOAD_FAILED=3
EXIT_CODE_EXTRACT_FAILED=4
EXIT_CODE_CHOWN_FAILED=5
EXIT_CODE_CHGRP_FAILED=6
EXIT_CODE_CHMOD_FAILED=7
EXIT_CODE_BACKUP_FAILED=8
EXIT_CODE_DIRECTORY_MOVE_FAILED=9


main() {
   abort ${REQUIRE_ERR} ${EXIT_CODE_REQUIRED_SOFTWARE_NOT_INSTALLED}

   pushd ${TEMP_DIR} > /dev/null
   abort ${?} ${EXIT_CODE_TMP_DIR_NOT_FOUND} "{TEMP_DIR} doesn't exist"

   wget --no-verbose --show-progress -O ${FILE} --content-disposition ${URL}
   abort ${?} ${EXIT_CODE_DOWNLOAD_FAILED} "Download failed"

   echo "Extracting..."

   tar -xf ${FILE}
   abort ${?} ${EXIT_CODE_EXTRACT_FAILED} "Extract failed.  Temp file `pwd`/${FILE} not removed."

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

main
