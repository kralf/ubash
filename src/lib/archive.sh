#!/bin/bash
############################################################################
#    Copyright (C) 2007 by Ralf 'Decan' Kaestner                           #
#    ralf.kaestner@gmail.com                                               #
#                                                                          #
#    This program is free software; you can redistribute it and#or modify  #
#    it under the terms of the GNU General Public License as published by  #
#    the Free Software Foundation; either version 2 of the License, or     #
#    (at your option) any later version.                                   #
#                                                                          #
#    This program is distributed in the hope that it will be useful,       #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#    GNU General Public License for more details.                          #
#                                                                          #
#    You should have received a copy of the GNU General Public License     #
#    along with this program; if not, write to the                         #
#    Free Software Foundation, Inc.,                                       #
#    59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
############################################################################

# Archive functions

function archive_getfilter
{
  case ${1##*.} in
    tar) FILTER=""
          ;;
    bz2) FILTER="j"
          ;;
    gz)  FILTER="z"
          ;;
    tgz) FILTER="z"
          ;;
      *) message_exit "archive $1 has unsupported format"
          ;;
  esac

  define $2 $FILTER
}

function archive_getcontents
{
  archive_getfilter $1 FILTER
  CONTENTS=(`tar -t${FILTER}f $1`)

  define $2 $CONTENTS
}

function archive_create
{
  ARCHIVE=$1
  shift
  ARCHIVEOPTS=$1
  shift
  message_start "creating archive `basename $ARCHIVE`"

  archive_getfilter $ARCHIVE FILTER
  [ -d "`dirname $ARCHIVE`" ] || execute "mkdir -p \"`dirname $ARCHIVE`\""
  execute "tar $ARCHIVEOPTS -c${FILTER}f $ARCHIVE $*"

  fs_getfilesize $ARCHIVE ARCHIVESIZE
  message_end "success, size of the archive is ${ARCHIVESIZE}kB"
}
