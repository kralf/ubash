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

  message_start "checking the $TARGET build tools"

  while [ -n "$1" ]; do
    message_start "checking $1"

    execute "$TARGET-linux-$1 --version"

    message_end
    shift
  done

  message_end "success, $TARGET build tools seem to be working"
}

function build_setenv
{
  ROOT=$1
  TARGET=$2
  DEBUG=$3

  message_start "setting up the $TARGET build environment"

  CPP="$ROOT/bin/$TARGET-linux-cpp"
  CC="$ROOT/bin/$TARGET-linux-gcc"
  CXX="$ROOT/bin/$TARGET-linux-g++"
  AR="$ROOT/bin/$TARGET-linux-ar"
  AS="$ROOT/bin/$TARGET-linux-as"
  RANLIB="$ROOT/bin/$TARGET-linux-ranlib"
  LD="$ROOT/bin/$TARGET-linux-ld"
  STRIP="$ROOT/bin/$TARGET-linux-strip"
  export CC CXX AR AS RANLIB LD STRIP

  CFLAGS="-I$ROOT/include -I$ROOT/usr/include"
  LDFLAGS="-L$ROOT/lib -L$ROOT/usr/lib"
  true DEBUG && LDFLAGS="$LDFLAGS -s"
  CMAKEFLAGS="-DCMAKE_SYSTEM_NAME=Linux"
  CMAKEFLAGS="$CMAKEFLAGS -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX"
  export CFLAGS LDFLAGS CMAKEFLAGS

  message_end
}

function build_stripsyms {
  message_start "stripping symbols from all objects in $1"

  execute "find $1 -name '*.so' -exec $STRIP -s {} \;"
  execute "find $1 -perm /111 -exec $STRIP -s {} \;"

  message_end
}

function build_patchdir
{
  ROOT=$1
  shift

  message_start "patching directory $ROOT"

  while [ -n "$1" ]; do
    message_start "applying $1"

    execute "patch -d $ROOT -p1 < $1"

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
  fs_abspath $1 INSTALLROOT
  EPREFIX="$INSTALLROOT"
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
    keyval "$1" ALIAS VERSION
    message_boldstart "building package $ALIAS"

    ADDONS=""
    PKG=""
    PKGCONFFILE="$CONFDIR/$ALIAS.$SUFFIX"
    PKGBUILDROOT="$BUILDROOT/$ALIAS"

    [ -r "$PKGCONFFILE" ] && include "$PKGCONFFILE"
    if [ -z "$PKG" ] || [ ! -r "$PKG" ]; then
      if [ -z "$VERSION" ]; then
        fs_getdirs "$PKGDIR/$ALIAS" PKGUDIR
        fs_regexdirs "$PKGDIR/$ALIAS-[0-9].*" PKGVDIR
        fs_regexfiles "$PKGDIR/$ALIAS\(\.tar\)?\(\.[gb]z[2]?\)" PKGUARCH
        fs_regexfiles "$PKGDIR/$ALIAS-[0-9].*\(\.tar\)?\(\.[gb]z[2]?\)" PKGVARCH
        PKG=($PKGUDIR $PKGVDIR $PKGUARCH $PKGVARCH)
      else
        fs_getdirs "$PKGDIR/$ALIAS-$VERSION" PKGDIR
        fs_regexfiles "$PKGDIR/$ALIAS-$VERSION\(\.tar\)?\(\.[gb]z[2]?\)" PKGARCH
        PKG=($PKGDIR $PKGARCH)
      fi
    fi
    [ ${#PKG[*]} -gt 1 ] && message_exit "package $ALIAS has ambigius versions"
    [ -r "$PKG" ] || message_exit "package $ALIAS not found"

    PKGBASENAME=`basename $PKG`
    PKGFULLNAME=${PKGBASENAME%.tar*}
    PKGNAME=${PKGFULLNAME%%-[0-9]*}
    PKGVERSION=${PKGFULLNAME#$PKGNAME-}

    GLOBALCMAKEFLAGS="$CMAKEFLAGS"
    GLOBALCFLAGS="$CFLAGS"
    GLOBALLDFLAGS="$LDFLAGS"

    CMAKEFLAGS="$CMAKEFLAGS -DCMAKE_FIND_ROOT_PATH=$INSTALLROOT"
    CMAKEFLAGS="$CMAKEFLAGS -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER"
    CMAKEFLAGS="$CMAKEFLAGS -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY"
    CMAKEFLAGS="$CMAKEFLAGS -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY"
    CMAKEFLAGS="$CMAKEFLAGS -DCMAKE_INSTALL_PREFIX=$PREFIX"
    CFLAGS="$CFLAGS -I$EPREFIX/include -I$PREFIX/include"
    LDFLAGS="$LDFLAGS -L$EPREFIX/lib -L$PREFIX/lib"

    BUILDDIR="."
    ARCH="$TARGET"
    [[ "$TARGET" =~ i[3-6]86 ]] && ARCH="i386"
    [ "$TARGET" == "powerpc" ] && ARCH="ppc"
    CONFIGURE=("./configure --prefix=$PREFIX --exec-prefix=$EPREFIX")
    MAKEBUILD=("make $MAKEOPTS all")
    MAKEINSTALL=("make $MAKEOPTS install")
    COMMENT="this may take a while"

    [ -r "$PKGCONFFILE" ] && include "$PKGCONFFILE"

    if ! [ -d "$PKGBUILDROOT" ]; then
      if ! [ -d "$PKG" ]; then
        message_start "extracting contents of $PKGBASENAME to $PKGBUILDROOT"
        install_archives $BUILDROOT $PKG
        message_end

        fs_getfiles "$PATCHDIR/$PKGNAME-$PKGVERSION*.$SUFFIX.patch" PATCHES
        if ! [ -d "$PKGBUILDROOT" ]; then
          fs_getdirs "$BUILDROOT/$PKGFULLNAME" PKGEXTRACTROOT
          execute "mv $PKGEXTRACTROOT $PKGBUILDROOT"
        fi
        
        if [ -n "$PATCHES" ]; then
          message_start "patching package sources"
          build_patchdir $PKGBUILDROOT ${PATCHES[*]}
          message_end
        fi
      else
        message_start "linking $PKG to $PKGBUILDROOT"
        fs_abspath $PKG PKG
        execute "ln -sf $PKG $PKGBUILDROOT"
        message_end
      fi
    else
      message_warn "contents of $PKGBASENAME found in $PKGBUILDROOT"
    fi

    message_start "descending into build directory"
    PKGBUILDDIR="$PKGBUILDROOT/$BUILDDIR"

    [ -d "$PKGBUILDDIR" ] || execute "mkdir -p $PKGBUILDDIR"
    if ! true INSTALL; then
      if [ "$CONFIGURE" != "" ]; then
        message "configuring package sources"
        for (( A=0; A < ${#CONFIGURE[*]}; A++ )); do
          execute "cd $PKGBUILDDIR && ${CONFIGURE[$A]}"
        done
      fi

      if [ "$MAKEBUILD" != "" ]; then
        message "compiling package sources ($COMMENT)"
        for (( A=0; A < ${#MAKEBUILD[*]}; A++ )); do
          execute "cd $PKGBUILDDIR && ${MAKEBUILD[$A]}"
        done
      fi
    fi

    if [ "$MAKEINSTALL" != "" ]; then
      message "installing built package content"
      for (( A=0; A < ${#MAKEINSTALL[*]}; A++ )); do
        execute "cd $PKGBUILDDIR && ${MAKEINSTALL[$A]}"
      done
    fi

    message_end "ascending from build directory"

    CMAKEFLAGS="$GLOBALCMAKEFLAGS"
    CFLAGS="$GLOBALCFLAGS"
    LDFLAGS="$GLOBALLDFLAGS"

    message_boldend "success, package $ALIAS built"
    shift
  done

  message_boldend "success, all packages built"
}
