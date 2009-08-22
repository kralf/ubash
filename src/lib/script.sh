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

# Functions

CHARWIDTH=30

SCRIPTMAINTAINER="ralf.kaestner@gmail.com"
[ "$0" != "$SHELL" ] && SCRIPT=`basename $0` || unset SCRIPT
unset SCRIPTDOC
unset SCRIPTDSPVAR
unset SCRIPTARGVAR
unset SCRIPTARGDEF
unset SCRIPTARGDOC

SCRIPTOPTTAGS=("--help"
               "--verbose|-v"
               "--quiet|-q"
               "--configfile|-c"
               "--logfile")

SCRIPTOPTVALS=(""
               ""
               ""
               "FILE"
               "FILE")

SCRIPTOPTVARS=(HELP
               VERBOSE
               QUIET
               CONFIGFILE
               LOGFILE)

SCRIPTOPTDEFS=("false"
               "false"
               "false"
               ""
               "`basename $0 .sh`.log")

SCRIPTOPTDOCS=("display usage and exit"
               "generate verbose command output"
               "do not generate any output"
               "optional configuration file"
               "temporary log file")

function script_init
{
  SCRIPTDOC=$1
  shift

  while [ -n "$1" ]; do
    SCRIPTDSPVAR[${#SCRIPTDSPVAR[*]}]=$1
    shift
    SCRIPTARGVAR[${#SCRIPTARGVAR[*]}]=$1
    shift
    SCRIPTARGDEF[${#SCRIPTARGDEF[*]}]=$1
    shift
    SCRIPTARGDOC[${#SCRIPTARGDOC[*]}]=$1
    shift
  done
}

function script_init_array
{
  SCRIPTDOC=$1
  SCRIPTDSPVAR=$2
  SCRIPTARGVAR=$3
  SCRIPTARGDEF=("${*:4:$#-4}")
  SCRIPTARGDOC="${*:$#}"
}

function script_print
{
  NUMCHARS=`echo -n "$1" | wc -m`
  math_calc "$CHARWIDTH-$NUMCHARS" NUMBLANKS

  echo -n "  $1"

  for (( B=0; B < $NUMBLANKS; B++ )); do
    echo -n " "
  done

  echo "$2"
}

function script_usage
{
  echo -n "usage: $SCRIPT [OPT1 [OPT2 [...]]]"

  if array_defined SCRIPTDSPVAR; then
    for (( A=0; A < ${#SCRIPTDSPVAR[*]}; A++ )); do
      if [ -z "${SCRIPTARGDEF[$A]}" ]; then
        echo -n " ${SCRIPTDSPVAR[$A]}"
      else
        echo -n " [${SCRIPTDSPVAR[$A]}]"
      fi
    done
  elif array_defined SCRIPTARGDEF; then
    echo -n " [${SCRIPTDSPVAR}1 [${SCRIPTDSPVAR}2 [...]]]"
  fi
  echo

  [ -n "$SCRIPTDOC" ] && echo -e "\033[1m$SCRIPTDOC\033[0m"

  if array_defined SCRIPTDSPVAR; then
    for (( A=0; A < ${#SCRIPTDSPVAR[*]}; A++ )); do
      if [ -z "${SCRIPTARGDEF[$A]}" ]; then
        script_print "${SCRIPTDSPVAR[$A]}" "${SCRIPTARGDOC[$A]}"
      else
        script_print "${SCRIPTDSPVAR[$A]}" \
          "${SCRIPTARGDOC[$A]} [${SCRIPTARGDEF[$A]}]"
      fi
    done
  elif array_defined SCRIPTARGDEF; then
    script_print "${SCRIPTDSPVAR}1 ${SCRIPTDSPVAR}2 ..." "$SCRIPTARGDOC"
  fi

  script_print "OPT1 OPT2 ..." "list of options as given below [default]"

  for (( A=0; A < ${#SCRIPTOPTTAGS[*]}; A++ )); do
    OPTTAG=${SCRIPTOPTTAGS[A]}
    OPTTAG=${OPTTAG//"|"/", "}
    OPTVAL=${SCRIPTOPTVALS[A]}
    OPTVAR=${SCRIPTOPTVARS[A]}
    OPTDEF=${SCRIPTOPTDEFS[A]}
    OPTDOC=${SCRIPTOPTDOCS[A]}

    if [ -n "${SCRIPTOPTDEFS[A]}" ]; then
      script_print "$OPTTAG $OPTVAL" "$OPTDOC [$OPTDEF]"
    else
      script_print "$OPTTAG $OPTVAL" "$OPTDOC"
    fi
  done

  echo "Report bugs to <$SCRIPTMAINTAINER>, attach error logs"
}

function script_setopt
{
  NUMOPTS=${#SCRIPTOPTTAGS[*]}

  SCRIPTOPTTAGS[$NUMOPTS]=$1
  SCRIPTOPTVALS[$NUMOPTS]=$2
  SCRIPTOPTVARS[$NUMOPTS]=$3
  SCRIPTOPTDEFS[$NUMOPTS]=$4
  SCRIPTOPTDOCS[$NUMOPTS]=$5
}

function script_checkopts
{
  unset SCRIPTARGS

  NUMOPTS=${#SCRIPTOPTTAGS[*]}
  for (( A=0; A < $NUMOPTS; A++ )); do
    define ${SCRIPTOPTVARS[A]} ${SCRIPTOPTDEFS[A]}
  done

  RETVAL=0

  while [ -n "$1" ]; do
    if [[ "$1" =~ ^- ]]; then
      MATCH="false"

      for (( A=0; A < $NUMOPTS; A++ )); do
        OPTTAG=${SCRIPTOPTTAGS[A]}
        OPTVAL=${SCRIPTOPTVALS[A]}
        OPTVAR=${SCRIPTOPTVARS[A]}
        OPTDEF=${SCRIPTOPTDEFS[A]}
        OPTDOC=${SCRIPTOPTDOCS[A]}

        if [[ "$1" =~ ^$OPTTAG$ ]]; then
          if [[ "$OPTDEF" =~ ^true$|^false$|^yes$|^no$ ]]; then
            define $OPTVAR "true"
            MATCH="true"
          else
            define $OPTVAR $2
            MATCH="true"
            shift
          fi
        fi
      done

      if ! true MATCH; then
        echo "unknown argument: $1"
        RETVAL=1
        HELP="true"
      fi
    else
      SCRIPTARGS[${#SCRIPTARGS[*]}]=$1
    fi

    shift
  done

  if array_defined SCRIPTARGDEF; then
    if [ ${#SCRIPTARGS[*]} -gt 0 ]; then
      define $SCRIPTARGVAR ${SCRIPTARGS[*]}
    else
      define $SCRIPTARGVAR ${SCRIPTARGDEF[*]}
    fi
  else
    for (( A=0; A < ${#SCRIPTDSPVAR[*]}; A++ )); do
      if [ $A -lt ${#SCRIPTARGS[*]} ]; then
        define ${SCRIPTARGVAR[$A]} "${SCRIPTARGS[$A]}"
      else
        if [ -n "${SCRIPTARGDEF[$A]}" ]; then
          define ${SCRIPTARGVAR[$A]} "${SCRIPTARGDEF[$A]}"
        else
          echo "missing argument: ${SCRIPTDSPVAR[$A]}"
          RETVAL=1
          HELP="true"
        fi
      fi
    done
  fi

  if true HELP; then
    script_usage
    exit $RETVAL
  fi

  if [ -r "$CONFIGFILE" ]; then
    fs_abspath $CONFIGFILE CONFIGFILE
    include $CONFIGFILE
  fi

  fs_abspath $LOGFILE LOGFILE
  log_clean
}

function script_checkroot
{
  [ "$UID" != "0" ] && message_exit "$SCRIPT must be run as root"
}

function script_run
{
  SCRIPTDIR=$1
  shift
  message_start "running scripts in $SCRIPTDIR"

  SCRIPTPWD=`pwd`
  execute "cd $SCRIPTDIR"

  while [ -n "$1" ]; do
    message_start "executing script $1"

    export STAGE
    "./$1"
    RETVAL=$?
    [ $RETVAL != 0 ] && exit $RETVAL

    message_end "success, script returned zero"
    shift
  done

  execute "cd $SCRIPTPWD"

  message_end "success, all scripts executed"
}
