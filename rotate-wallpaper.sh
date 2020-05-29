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
. require "sleep"
. require "gsettings"
. require "head"
. require "tail"


EXIT_CODE_REQUIRED_SOFTWARE_NOT_INSTALLED=1
EXIT_CODE_WALLPAPER_DIR_NOT_EXIST=2

# Settings
WALLPAPER_DIR=~/Pictures/Wallpapers
FILE_TYPES="*.jpg *.png"
CHANGE_INTERVAL_MINUTES=10

main() {
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

   currPicNum=0

   while [ true ]
   do
      pics=`ls ${FILE_TYPES} 2> /dev/null`
      count=0
      newPicNum=0

      if [ "${pics}" != "" ]
      then
         count=`echo "${pics}" | wc -l`
      fi

      if [ ${count} -gt 1 ]
      then
         while [ ${newPicNum} = ${currPicNum} ]
         do
            newPicNum=$((1 + RANDOM % $count))
         done
      fi

      chosenPic=`echo "${pics}" | head -${newPicNum} | tail -1`
      gsettings set org.gnome.desktop.background picture-uri "'file:///${WALLPAPER_DIR}/${chosenPic}'"

      currPicNum=${newPicNum}

      sleep ${CHANGE_INTERVAL_MINUTES}m
   done
}

main
