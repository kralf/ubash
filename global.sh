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

# Global functions

function defined {
  [ "${!1-X}" == "${!1-Y}" ]
}

function true {
  [ "${!1}" == "true" ] || [ "${!1}" == "yes" ]
}

function false {
  [ "${!1}" != "true" ] && [ "${!1}" != "yes" ]
}

function keyval
{
  eval $2=`echo $1 | grep -o "^[^=]*"`
  eval $3=`echo $1 | grep -o "=.*$" | sed s/"^="//`
}

function include
{
  while [ -n "$1" ]; do
    INCPWD=`dirname ${BASH_ARGV[0]}`

    if [ -e "$INCPWD/$1" ]; then
      . "$INCPWD/$1"
      INCLUDES=("$INCPWD/$1" ${INCLUDES[*]})
    else
      message_exit "missing include $1"
    fi

    shift
  done
}

include "execute.sh"
include "fs.sh"
include "install.sh"
include "log.sh"
include "math.sh"
include "message.sh"
include "network.sh"
include "script.sh"
include "system.sh"
include "test.sh"
