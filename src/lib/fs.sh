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

function fs_checkfilerd
{
  message_start "checking if file $1 is readable"

  if ! [ -f "$1" ] || ! [ -r "$1" ]; then
    message_exit "file $1 is not readable"
  fi

  message_end
}

function fs_checkfilewr
{
  message_start "checking if file $1 is writable"

  if ! [ -f "$1" ] || ! [ -w "$1" ]; then
    message_exit "file $1 is not writable"
  fi

  message_end
}

function fs_checkdirrd
{
  message_start "checking if directory $1 is readable"

  if ! [ -d "$1" ] || ! [ -r "$1" ]; then
    message_exit "directory $1 is not readable"
  fi

  message_end
}

function fs_checkdirwr
{
  message_start "checking if directory $1 is writable"

  if ! [ -d "$1" ] || ! [ -w "$1" ]; then
    message_exit "directory $1 is not writable"
  fi

  message_end
}

function fs_getfiles
{
  unset FILES
  FINDOPTS="-mindepth 1 -maxdepth 1 -xtype f"

  DIRNAME=`dirname "$1"`
  BASENAME=`basename "$1"`

  FOUND=`find "$DIRNAME" $FINDOPTS -name "$BASENAME" 2> $NULL`

  while read FILE; do
    FILES[${#FILES[*]}]="$FILE"
  done <<< "$FOUND"

  array_copy $2 FILES
}

function fs_regexfiles
{
  unset FILES
  FINDOPTS="-mindepth 1 -maxdepth 1 -xtype f"

  DIRNAME=`dirname "$1"`
  BASENAME=`basename "$1"`

  FOUND=`find "$DIRNAME" $FINDOPTS -regex ".*/$BASENAME" 2> $NULL`

  while read FILE; do
    FILES[${#FILES[*]}]="$FILE"
  done <<< "$FOUND"

  array_copy $2 FILES
}

function fs_getfilesize
{
  FILESIZE=(`du -hks "$1" 2> $NULL`)
  [ -z "$FILESIZE" ] && FILESIZE="0"
  define $2 ${FILESIZE[0]}
}

function fs_getdirs
{
  unset DIRS
  FINDOPTS="-mindepth 1 -maxdepth 1 -xtype d"

  DIRNAME=`dirname "$1"`
  BASENAME=`basename "$1"`

  FOUND=`find "$DIRNAME" $FINDOPTS -name "$BASENAME" 2> $NULL`

  while read DIR; do
    DIRS[${#DIRS[*]}]="$DIR"
  done <<< "$FOUND"

  array_copy $2 DIRS
}

function fs_regexdirs
{
  unset DIRS
  FINDOPTS="-mindepth 1 -maxdepth 1 -xtype d"

  DIRNAME=`dirname "$1"`
  BASENAME=`basename "$1"`

  FOUND=`find "$DIRNAME" $FINDOPTS -regex ".*/$BASENAME" 2> $NULL`

  while read DIR; do
    DIRS[${#DIRS[*]}]="$DIR"
  done <<< "$FOUND"

  array_copy $2 DIRS
}

function fs_getdirsize
{
  ROOT=$1
  shift
  VAR=$1
  shift

  unset DUOPTS
  for EXCLUDE in $*; do
    if [[ "$EXCLUDE" =~ ^/ ]]; then
      DUOPTS="$DUOPTS --exclude=\"$ROOT$EXCLUDE\""
    else
      DUOPTS="$DUOPTS --exclude=\"$EXCLUDE\""
    fi
  done

  DIRSIZE=(`du -hks $DUOPTS $ROOT 2> $NULL`)
  [ -z "$DIRSIZE" ] && DIRSIZE="0"
  define $VAR ${DIRSIZE[0]}
}

function fs_abspath
{
  unset ABSPATH

  if [ -d "$1" ]; then
    pushd "$1" > $NULL
    ABSPATH="`pwd`"
    popd > $NULL
  elif [ -d "`dirname \"$1\"`" ]; then
    pushd "`dirname \"$1\"`" > $NULL
    ABSPATH="`pwd`/`basename \"$1\"`"
    popd > $NULL
  fi

  [ -z "$ABSPATH" ] && message_warn "path to $1 is invalid"

  define $2 \"$ABSPATH\"
}

function fs_mkdirs
{
  ROOT="$1"
  shift
  message_start "making directory structure in $ROOT"

  while [ -n "$1" ]; do
    MKDIR="`echo \"$1\" | sed s/'^\/'//`"

    if ! [ -d "$ROOT/$MKDIR" ]; then
      message_start "making directory /$MKDIR"

      execute "mkdir -p \"$ROOT/$MKDIR\""

      message_end
    fi

    shift
  done

  message_end "success, directory structure made"
}

function fs_mkfiles
{
  ROOT="$1"
  shift
  message_start "making files in $ROOT"

  while [ -n "$1" ]; do
    MKFILE="`echo \"$1\" | sed s/'^\/'//`"

    if ! [ -e "$ROOT/$MKFILE" ]; then
      message_start "making file /$MKFILE"

      execute "touch \"$ROOT/$MKFILE\""

      message_end
    fi

    shift
  done

  message_end "success, files made"
}

function fs_rmdirs
{
  ROOT="$1"
  shift
  message_start "removing directories in $ROOT"

  while [ -n "$1" ]; do
    RMDIR="`echo \"$1\" | sed s/'^\/'//`"

    if [ -d "$ROOT/$RMDIR" ]; then
      message_start "removing directory /$RMDIR"

      execute "rm -rf \"$ROOT/$RMDIR\""

      message_end
    fi

    shift
  done

  message_end "success, directories removed"
}

function fs_rmfiles
{
  ROOT="$1"
  shift
  message_start "removing files in $ROOT"

  while [ -n "$1" ]; do
    message_start "removing file(s) $1"

    execute "find \"$ROOT\" -name \"$1\" -xtype f -exec rm -rf {} \;"

    message_end
    shift
  done

  message_end "success, files removed"
}

function fs_rmbrokenlinks
{
  message_start "removing broken links from $1"

  FOUND=`find "$1" -type l 2> $NULL`

  while read LINK; do
    ! [ -e "$LINK" ] && execute "rm -rf \"$LINK\""
  done <<< "$FOUND"

  message_end
}

function fs_chowndirs
{
  ROOT="$1"
  shift
  message_start "changing directory ownerships in $ROOT"

  while [ -n "$1" ]; do
    keyval "$1" CHOWNDIR CHOWNOWNER
    CHOWNDIR="`echo \"$CHOWNDIR\" | sed s/'^\/'//`"
    message_start "changing ownership of /$CHOWNDIR to $CHOWNOWNER"

    execute "chown -R $CHOWNOWNER \"$ROOT/$CHOWNDIR\""

    message_end
    shift
  done

  message_end "success, directory ownerships changed"
}

function fs_chmoddirs
{
  ROOT="$1"
  shift
  message_start "changing directory permissions in $ROOT"

  while [ -n "$1" ]; do
    keyval "$1" CHMODDIR CHMODPERM
    CHMODDIR="`echo \"$CHMODDIR\" | sed s/'^\/'//`"
    message_start "changing permissions of /$CHMODDIR to $CHMODPERM"

    execute "find \"$ROOT/$CHMODDIR\" -xtype d -exec chmod $CHMODPERM {} \;"

    message_end
    shift
  done

  message_end "success, directory permissions changed"
}

function fs_cpdirs
{
  CPOPTS="-dR --preserve=mode,timestamps --remove-destination"

  ROOT="$1"
  shift
  message_start "copying directories to $ROOT"

  while [ -n "$1" ]; do
    keyval "$1" CPDIR CPDIROPTS
    CPDIRS="`find \"$CPDIR\" -maxdepth 0 2> $NULL`"

    for CPDIR in $CPDIRS; do
      message_start "copying directory $CPDIR"

      execute "cp $CPOPTS $CPDIROPTS \"$CPDIR\" \"$ROOT\""

      message_end
    done

    shift
  done

  message_end "success, directories copied"
}

function fs_cpdevices
{
  CPOPTS="-dR --preserve=mode,timestamps --remove-destination"

  ROOT="$1"
  shift
  message_start "copying devices to $ROOT/dev"

  ! [ -d "$ROOT/dev" ] && fs_mkdirs \"$ROOT\" /dev

  while [ -n "$1" ]; do
    for CPDEV in /dev/$1; do
      if [ -e "$CPDEV" ]; then
        message_start "copying device $CPDEV"

        execute "cp $CPOPTS \"$CPDEV\" \"$ROOT$CPDEV\""

        message_end
      else
        message_warn "no such device(s) $CPDEV"
      fi
    done
    shift
  done

  message_end "success, devices copied"
}

function fs_cpfiles
{
  CPOPTS="-dR --preserve=mode,timestamps --remove-destination"

  ROOT="$1"
  shift
  message_start "copying files to $ROOT"

  while [ -n "$1" ]; do
    keyval "$1" CPFILE CPFILEOPTS
    message_start "copying file(s) $CPFILE"

    execute "cp $CPOPTS $CPFILEOPTS \"$CPFILE\" \"$ROOT\""

    message_end
    shift
  done

  message_end "success, files copied"
}

function fs_wrfiles
{
  ROOT="$1"
  shift
  message_start "writing files in $ROOT"

  while [ -n "$1" ]; do
    WRFILE="`echo \"$1\" | sed s/'^\/'//`"
    message_start "writing file /$1"

    execute "echo -e $2 >> \"$ROOT/$1\""

    message_end
    shift
    shift
  done

  message_end "success, files written"
}

function fs_mountimg
{
  MNTIMG="$1"
  MNTPOINT="$2"

  message_start "mounting filesystem image to $MNTPOINT"

  execute "mkdir -p \"$MNTPOINT\""
  execute "mount -o loop \"$MNTIMG\" \"$MNTPOINT\""

  message_end
}

function fs_umountimg
{
  UMNTIMG="$1"
  UMNTPOINT="$2"

  message_start "unmounting filesystem image from $UMNTPOINT"

  execute "umount \"$UMNTPOINT\""
  execute "rm -rf \"$UMNTPOINT\""

  message_end
}

function fs_mkimg
{
  FSIMAGE="$1"
  shift
  FSROOT="$1"
  shift
  FSMOUNTPOINT="$1"
  shift
  FSTYPE=$1
  shift
  FSBLOCKSIZE=$1
  shift
  FSSPACE=$1
  shift
  FSEXCLUDES=$*

  message_start "making filesystem image $FSIMAGE"

  message_start "evaluating image size"
  fs_getdirsize "$FSROOT" FSSIZE $FSEXCLUDES
  math_calc "$FSSIZE*1.10+$FSSPACE" FSSIZE
  message_end

  message_start "writing zeroed image"
  execute "dd if=/dev/zero of=\"$FSIMAGE\" bs=1k count=$FSSIZE"
  message_end

  message_start "building $FSTYPE filesystem on image device"
  execute "/sbin/mkfs -t $FSTYPE -F \"$FSIMAGE\" -b $FSBLOCKSIZE"
  message_end

  fs_mountimg "$FSIMAGE" "$FSMOUNTPOINT"

  unset FSRSYNCOPTS
  for FSEXCLUDE in $FSEXCLUDES; do
    FSRSYNCOPTS="$FSRSYNCOPTS --exclude=\"$FSEXCLUDE\""
  done

  message_start "copying filesystem content to image"
  execute "rsync -av $FSRSYNCOPTS \"$FSROOT/\" \"$FSMOUNTPOINT\""
  message_end

  fs_umountimg "$FSIMAGE" "$FSMOUNTPOINT"

  message_end "success, size of the filesystem image is ${FSSIZE}kB"
}

function fs_bind
{
  FSOLDDIR="$1"
  FSNEWDIR="$2"

  FSBOUND="`mount | grep \"$FSNEWDIR\"`"
  if [ -z "$FSBOUND" ]; then
    message_start "binding filesystem in $FSOLDDIR to $FSNEWDIR"

    [ -d "$FSNEWDIR" ] || execute "mkdir -p \"$FSNEWDIR\""
    execute "mount -t none -o bind \"$FSOLDDIR\" \"$FSNEWDIR\""

    message_end
  else
    message "filesystem already bound to $FSNEWDIR"
  fi
}
