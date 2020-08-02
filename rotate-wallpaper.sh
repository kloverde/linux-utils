#!/bin/bash

# rotate-wallpaper.sh
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
. require "getopt"
. require "sleep"
. require "gsettings"
. require "head"
. require "tail"
. require "sleep"
. require "identify"
. require "xrandr"
. require "grep"
. require "awk"

shopt -s expand_aliases
alias echo="echo -e"

declare -r EXIT_CODE_USAGE=1
declare -r EXIT_CODE_REQUIRED_SOFTWARE_NOT_INSTALLED=2
declare -r EXIT_CODE_WALLPAPER_DIR_NOT_EXIST=3

main() {
   WALLPAPER_DIR=""
   FILE_TYPES=""
   CHANGE_INTERVAL_MINUTES=0
   SCALING_ENABLED=false

   parseArgs "${@}"

   #echo "directory  = $WALLPAPER_DIR"
   #echo "file types = ${FILE_TYPES}"
   #echo "interval   = ${CHANGE_INTERVAL_MINUTES}"

   currPicNum=0

   if [ ${REQUIRE_ERR} != 0 ]
   then
      exit ${EXIT_CODE_REQUIRED_SOFTWARE_NOT_INSTALLED}
   fi

   if [ ! -d "${WALLPAPER_DIR}" ]
   then
      exit ${EXIT_CODE_WALLPAPER_DIR_NOT_EXIST}
   fi

   cd "${WALLPAPER_DIR}"

   while [ true ]
   do
      pics=`ls ${FILE_TYPES} 2> /dev/null`
      count=0
      newPicNum=${currPicNum}

      if [ "${pics}" != "" ]
      then
         count=`echo "${pics}" | wc -l`
      fi

      if [ ${count} -gt 1 ]
      then
         while [ ${newPicNum} = ${currPicNum} ]
         do
            newPicNum=$((1 + RANDOM % count))
         done
      fi

      chosenPic=`echo "${pics}" | head -${newPicNum} | tail -1`

      if [ "${chosenPic}" != "" ]
      then
         echo "\nusing ${chosenPic}"

         if [ ${SCALING_ENABLED} = true ]
         then
            imgWidth=`identify -format "%w" "${chosenPic}"`
            imgHeight=`identify -format "%h" "${chosenPic}"`
            imgRatio=`awk 'BEGIN { print ARGV[1] / ARGV[2] }' ${imgWidth} ${imgHeight}`

            screenDims=`xrandr --query | grep -A 1 connected | grep -v connected | head -1 | awk '{print $1}'`
            screenWidth=`echo ${screenDims} | awk 'BEGIN { FS="x"} { print $1; }'`
            screenHeight=`echo ${screenDims} | awk 'BEGIN { FS="x"} { print $2; }'`
            screenRatio=`awk 'BEGIN { print ARGV[1] / ARGV[2] }' ${screenWidth} ${screenHeight}`

            if [ ${imgRatio} = ${screenRatio} ]
            then
               scalingMode="scaled"
            else
               scalingMode="zoom"
            fi

            echo "image is ${imgWidth} x ${imgHeight} (${imgRatio})"
            echo "screen is ${screenWidth} x ${screenHeight} (${screenRatio})"
            echo "scaling mode ${scalingMode}"

            gsettings set org.gnome.desktop.background picture-options "${scalingMode}"
         fi

         gsettings set org.gnome.desktop.background picture-uri "'file:///${WALLPAPER_DIR}/${chosenPic}'"
      fi

      currPicNum=${newPicNum}

      sleep ${CHANGE_INTERVAL_MINUTES}s
   done
}

parseArgs() {
   OPTS=$(getopt -o "d:f:i:s" --long "directory:,file-types:,interval:,scale" -n "$(basename $0)" -- "${@}")

   if [[ ${?} != 0 || ( ${#} != 6 && ${#} != 7 ) ]]
   then
      usage
      exit ${EXIT_CODE_USAGE}
   fi

   while [ ${#} -gt 0 ]
   do
      #echo "iteration:  $1 $2"

      case "${1}" in
         -d | --directory )
            WALLPAPER_DIR="${2}"
            shift 2
            ;;

         -f | --file-types )
            FILE_TYPES="${2}"
            shift 2
            ;;

         -i | --interval )
            CHANGE_INTERVAL_MINUTES=${2}
            shift 2
            ;;

         -s | --scale )
            SCALING_ENABLED=true
            shift
            ;;

         -- )  # end-of-input indicator
            shift
            break
            ;;

         * )
            usage
            exit ${EXIT_CODE_USAGE}
      esac
   done
}

usage() {
   echo "Usage:  $(basename $0) [OPTIONS]\n"

   echo "Required arguments:\n"
   echo "-d, --directory [VALUE]   Directory containing images\n"
   echo "-f, --file-types [VALUE]  Space-separated wildcard string, like \"*png *.jpg\"\n"
   echo "-i, --interval [VALUE]    Rotation interval, measured in minutes"

   echo "\nOptional arguments:\n"
   echo "-h, --help   Displays this usage info\n"
   echo "-s, --scale  Fills the entire screen with the image.  If the image's aspect"
   echo "             ratio is the same as the screen, the image is scaled.  If the"
   echo "             aspect ratio is different, the image is scaled and cropped to"
   echo "             preserve its aspect ratio."
}

main "${@}"
