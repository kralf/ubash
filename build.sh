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

# Build functions

function build_checktools
{
  TARGET=$1
  shift

  message_start "checking the build tools"

  while [ -n "$1" ]; do
    message_start "checking $1"

    execute "$TARGET-linux-$1 --version"

    message_end
    shift
  done

  message_end "success, build tools seem to be okay"
}

function build_setenv
{
  ROOT=$1
  TARGET=$2
  DEBUG=$3

  message_start "setting up the $TARGET build environment"

  CPP="$TARGET-linux-cpp"
  CC="$TARGET-linux-gcc"
  CXX="$TARGET-linux-g++"
  AR="$TARGET-linux-ar"
  AS="$TARGET-linux-as"
  RANLIB="$TARGET-linux-ranlib"
  LD="$TARGET-linux-ld"
  STRIP="$TARGET-linux-strip"
  export CC CXX AR AS RANLIB LD STRIP

  CFLAGS="-I$ROOT/include -I$ROOT/usr/include"
  LDFLAGS="-L$ROOT/lib -L$ROOT/usr/lib"
  true DEBUG && LDFLAGS="$LDFLAGS -s"
  export CFLAGS LDFLAGS

  message_end
}

function build_stripsyms {
  message_start "stripping symbols from all objects in $1"

  execute "find $1 -name *.so -exec $STRIP -s {} ;"
  execute "find $1 -perm /111 -exec $STRIP -s {} ;"

  message_end
}
