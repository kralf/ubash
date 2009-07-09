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

# Install functions

function regexp_matchfile
{
  [ -r "$1" ] && [ -n "`grep \"$2\" $1`" ]
}

function regexp_substfile
{
  EXPSEP="/"
  [ -n "$4" ] && EXPSEP="$4"

  message_start "subsituting content in $1"

  execute "sed -i s$EXPSEP\"$2\"$EXPSEP\"$3\"$EXPSEP $1"

  message_end "success, content substituted"
}
