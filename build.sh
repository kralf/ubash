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

function build_patchdir
{
  ROOT=$1
  shift

  message_start "patching directory $ROOT"

  while [ -n "$1" ]; do
    message_start "applying $1"

    execute "patch -d $ROOT -p0 < $1"

    message_end
    shift
  done

  message_end "success, directory patched"
}

function build_packages
{
  SUFFIX=$1
  shift

  PKGDIR=$1
  shift
  fs_abspath $1 CONFDIR
  shift
  PATCHDIR=$1
  shift

  BUILDROOT=$1
  shift
  fs_abspath $1 EPREFIX
  PREFIX="$EPREFIX/usr"
  shift

  HOST=$1
  shift
  TARGET=$1
  shift
  MAKEOPTS=$1
  shift
  INSTALL=$1
  shift

  message_boldstart "building packages"

  while [ -n "$1" ]; do
    message_boldstart "building package $1"

    ALIAS="$1"
    ADDONS=""
    BUILDDIR="."
    CONFIGURE=("./configure --prefix=$PREFIX --exec-prefix=$EPREFIX")
    MAKEBUILD=("make $MAKEOPTS all")
    MAKEINSTALL=("make $MAKEOPTS install")
    COMMENT="this may take a while"
    PKG=""
    PKGBUILDROOT=$BUILDROOT/$ALIAS

    [ -r "$CONFDIR/$1.$SUFFIX" ] && include "$CONFDIR/$1.$SUFFIX"
    if [ -z "$PKG" ] || [ ! -r "$PKG" ]; then
      fs_getfiles "$PKGDIR/$ALIAS-[0-9]*.{tar,gz,tgz,bz2}" PKG
    fi
    [ -r "$PKG" ] || message_exit "package $1 not found"

    PKGBASENAME=`basename $PKG`
    PKGFULLNAME=${PKGBASENAME%.tar*}
    PKGNAME=${PKGFULLNAME%%-[0-9]*}
    PKGVERSION=${PKGFULLNAME##*-}

    if ! [ -d "$PKGBUILDROOT" ]; then
      if ! [ -d "$PKG" ]; then
        message_start "extracting contents of $PKGBASENAME to $PKGBUILDROOT"
        install_archives $BUILDROOT $PKG
        message_end

        fs_getfiles "$PATCHDIR/$PKGNAME-$PKGVERSION*.patch" PATCHES
        if [ -n "$PATCHES" ]; then
          message_start "patching package sources"
          build_patchdir $BUILDROOT $PATCHES
          message_end
        fi

        if ! [ -d "$PKGBUILDROOT" ]; then
          fs_getdirs "$BUILDROOT/$PKGFULLNAME" PKGEXTRACTROOT
          execute "mv $PKGEXTRACTROOT $PKGBUILDROOT"
        fi
      else
        message_start "linking $PKG to $PKGBUILDROOT"
        execute "ln -sf $PKG $PKGBUILDROOT"
        message_end
      fi
    else
      message_warn "contents of $PKGBASENAME found in $PKGBUILDROOT"
    fi

    message_start "descending into build directory"
    SCRIPTROOT=`pwd`
    execute "cd $PKGBUILDROOT"

    [ -d "$BUILDDIR" ] || execute "mkdir -p $BUILDDIR"
    execute "cd $BUILDDIR"
    if ! true INSTALL; then
      if [ "$CONFIGURE" != "" ]; then
        message "configuring package sources"
        execute "${CONFIGURE[@]}"
      fi

      if [ "$MAKEBUILD" != "" ]; then
        message "compiling package sources ($COMMENT)"
        execute "${MAKEBUILD[@]}"
      fi
    fi

    if [ "$MAKEINSTALL" != "" ]; then
      message "installing built package content"
      execute "${MAKEINSTALL[@]}"
    fi
  
    message_end "ascending from build directory"
    execute "cd $SCRIPTROOT"

    message_boldend "success, package $1 built"
    shift
  done

  message_boldend "success, all packages built"
}
