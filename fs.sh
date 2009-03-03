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

# File system functions

function fs_getfilesize
{
  FILESIZE=(`du -hks $1 2> $NULL`)
  eval $2=${FILESIZE[0]}
}

function fs_getdirsize
{
  DIRSIZE=(`du -hks $1 2> $NULL`)
  eval $2=${DIRSIZE[0]}
}

function fs_abspath
{
  unset ABSPATH

  if [ -d "`dirname $1`" ]; then
    ABSPWD=`pwd`
    cd `dirname $1`

    eval ABSPATH=`pwd`/`basename $1`

    cd $ABSPWD
  fi

  [ -z "$ABSPATH" ] && message_warn "path to $1 is invalid"

  eval $2=$ABSPATH
}

function fs_mkdirs
{
  ROOT=$1
  shift
  message_start "making directory structure in $ROOT"

  while [ -n "$1" ]; do
    MKDIR=`echo $1 | sed s/'^\/'//`

    if ! [ -d "$ROOT/$MKDIR" ]; then
      message_start "making directory /$MKDIR"

      execute "mkdir -p $ROOT/$MKDIR"

      message_end
    fi

    shift
  done

  message_end "success, directory structure made"
}

function fs_mkfiles
{
  ROOT=$1
  shift
  message_start "making files in $ROOT"

  while [ -n "$1" ]; do
    MKFILE=`echo $1 | sed s/'^\/'//`

    if ! [ -e "$ROOT/$MKFILE" ]; then
      message_start "making file /$MKFILE"

      execute "touch $ROOT/$MKFILE"

      message_end
    fi

    shift
  done

  message_end "success, files made"
}

function fs_rmdirs
{
  ROOT=$1
  shift
  message_start "removing directories in $ROOT"

  while [ -n "$1" ]; do
    RMDIR=`echo $1 | sed s/'^\/'//`

    if ! [ -d "$ROOT/$RMDIR" ]; then
      message_start "removing directory /$1"

      execute "rm -rf $ROOT/$1"

      message_end
    fi

    shift
  done

  message_end "success, directories removed"
}

function fs_rmfiles
{
  ROOT=$1
  shift
  message_start "removing files in $ROOT"

  RMPWD=`pwd`
  execute "cd $ROOT"

  while [ -n "$1" ]; do
    message_start "removing file(s) $1"

    execute "find -wholename .$1 -exec rm -rf {} \;"

    message_end
    shift
  done

  execute "cd $RMPWD"

  message_end "success, files removed"
}

function fs_rmbrokenlinks
{
  message_start "removing broken links from $1"

  LINKS=`find $1 -type l`
  for LINK in $LINKS; do
    ! [ -e $LINK ] && execute "rm -rf $LINK"
  done

  message_end
}

function fs_chowndirs
{
  ROOT=$1
  shift
  message_start "changing directory ownerships in $ROOT"

  while [ -n "$1" ]; do
    keyval "$1" CHOWNDIR CHOWNOWNER
    message_start "changing ownership of $CHOWNDIR to $CHOWNOWNER"

    execute "chown -R $CHOWNOWNER $ROOT$CHOWNDIR"

    message_end
    shift
  done

  message_end "success, directory ownerships changed"
}

function fs_chmoddirs
{
  ROOT=$1
  shift
  message_start "changing directory permissions in $ROOT"

  while [ -n "$1" ]; do
    keyval "$1" CHMODDIR CHMODPERM
    message_start "changing permissions of $CHMODDIR to $CHMODPERM"

    execute "find $ROOT$CHMODDIR -type d -exec chmod $CHMODPERM {} \;"

    message_end
    shift
  done

  message_end "success, directory permissions changed"
}

function fs_cpdirs
{
  CPOPTS="-dR --preserve=mode,timestamps --remove-destination --parents"

  ROOT=$1
  shift
  message_start "copying directories to $ROOT"

  while [ -n "$1" ]; do
    keyval "$1" CPDIR CPDIROPTS
    CPDIRS="`find $CPDIR -maxdepth 0 2> $NULL`"

    for CPDIR in $CPDIRS; do
      message_start "copying directory $CPDIR"

      execute "cp $CPOPTS $CPDIROPTS $CPDIR $ROOT"

      message_end
    done

    shift
  done

  message_end "success, directories copied"
}

function fs_cpfiles
{
  CPOPTS=""

  ROOT=$1
  shift
  message_start "copying files to $ROOT"

  while [ -n "$1" ]; do
    keyval "$1" CPFILE CPFILEOPTS
    message_start "copying file(s) $CPFILE"

    CPROOT=`echo $CPFILE | sed s/'[/?][^/]*$'// | sed s/'^\/'//`
    ! [ -d "$ROOT/$CPROOT" ] && fs_mkdirs $ROOT /$CPROOT

    execute "cp $CPOPTS $CPFILEOPTS $CPFILE $ROOT/$CPFILE"

    message_end
    shift
  done

  message_end "success, files copied"
}

function fs_cpdevices
{
  ROOT=$1
  shift
  message_start "copying devices to $ROOT/dev"

  ! [ -d "$ROOT/dev" ] && fs_mkdirs $ROOT /dev
  
  while [ -n "$1" ]; do
    if [ -e "/dev/$1" ]; then
      message_start "copying device(s) $1"

      execute "cp -a --remove-destination /dev/$1 $ROOT/dev/$1"

      message_end
    else
      message_warn "no such device(s) $1"
    fi

    shift
  done

  message_end "success, devices copied"
}

function fs_wrfiles
{
  ROOT=$1
  shift
  message_start "writing files in $ROOT"

  while [ -n "$1" ]; do
    WRFILE=`echo $1 | sed s/'^\/'//`
    message_start "writing file /$1"

    execute "echo -e $2 >> $ROOT/$1"

    message_end
    shift
    shift
  done

  message_end "success, files written"
}
