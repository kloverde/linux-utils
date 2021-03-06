#!/bin/bash

# create-favorite.sh
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


. require bash getopt basename


declare -r EXIT_CODE_SUCCESS=0
declare -r EXIT_CODE_REQUIRED_SOFTWARE_NOT_INSTALLED=1
declare -r EXIT_CODE_INCORRECT_USAGE=2
declare -r EXIT_CODE_USER_ABORT=3

shopt -s expand_aliases
alias echo="echo -e"

main() {
   if [ ${REQUIRE_ERR} != 0 ]
   then
      exit ${EXIT_CODE_REQUIRED_SOFTWARE_NOT_INSTALLED}
   fi

   INSTALL=false

   parseArgs "${@}"

   declare -r name=`prompt "Enter shortcut name.  This is how the shortcut will appear in the Gnome menu"`

   declare -r comment=`prompt "Enter description"`

   exec=`prompt "Enter the full path to the executable.  Don't enter arguments/flags - that will be done in the next step"`

   while [ ! -f "${exec}" ]
   do
      echo "${exec} not found"
      exec=`prompt "Enter the full path to the executable.  Don't enter arguments/flags - that will be done in the next step)"`
   done

   executableBasename=`basename "${exec}"`
   exec="\"${exec}\""

   read -p "Enter arguments/flags, if any: " args

   if [ "${args}" != "" ]
   then
      exec="${exec} ${args}"
   fi

   declare -r class=`prompt "Enter StartupWMClass.  This is an identifier used for taskbar grouping.  You can find this value by running 'xprop WM_CLASS' then clicking on the application while it's running.  If no value is reported, provide your own.  [${executableBasename}]" "${executableBasename}"`

   icon=`prompt "Enter full icon path"`

   while [ ! -f "${icon}" ]
   do
      icon=`prompt "File '${icon}' not found.  Enter full icon path"`
   done

   declare -r categories=`prompt "Enter categories (semicolon-delimited)"`

   declare -r launcher=`prompt "Enter name to save launcher as [${executableBasename}]" "${executableBasename}"`

   declare -r launcherPath=~/.local/share/applications/${launcher}.desktop

   if [ -f "${launcherPath}" ]
   then
      . yesno "File ${launcherPath} exists.  Do you want to overwrite?"

      if [ "${YESNO}" = "N" ]
      then
         exit ${EXIT_CODE_USER_ABORT}
      fi
   fi

   echo "[Desktop Entry]
Encoding=UTF-8
Name=${name}
Comment=${comment}
Type=Application
Exec=${exec}
StartupWMClass=${class}
Icon=${icon}
Categories=${categories}
" > "${launcherPath}"

   echo "\nLauncher saved to ${launcherPath}"

   if [ ${INSTALL} = true ]
   then
      echo "\n\nInstalling...\n"
      add-favorite.sh --install "${launcherPath}"
   fi
}

# $1:  The prompt to display to the user
# $2:  Optional default value, used if the user doesn't provide a value
prompt() {
   answer=""

   while [ "${answer}" = "" ]
   do
      read -p "${1}: " answer

      if [ "${answer}" = "" -a "${2}" != "" ]
      then
         answer="${2}"
      fi
   done

   echo "${answer/#\~/$HOME}"
}

usage() {
   echo "This application is a wizard that aids you in creating a"
   echo "desktop launcher and setting it as a favorite.\n"

   echo "Usage:  `basename ${0}` [[-i, --install]]\n"

   echo "OPTIONS:\n"
   echo "-i, --install     Moves the launcher to your home directory"
   echo "                  and optionally creates a public symlink."
}

parseArgs() {
   OPTS=$(getopt -o "i" --long "install" -n "$(basename $0)" -- "${@}")

   if [ ${?} != 0  ]
   then
      usage
      exit ${EXIT_CODE_INCORRECT_USAGE}
   fi

   while [ ${#} -gt 0 ]
   do
      #echo "iteration:  $1 $2"

      case "${1}" in
         -i | --install )
            INSTALL=true
            shift
            ;;

         -- )  # end-of-input indicator
            shift
            break
            ;;

         * )
            usage
            exit ${EXIT_CODE_INCORRECT_USAGE}
      esac
   done
}

main "${@}"

