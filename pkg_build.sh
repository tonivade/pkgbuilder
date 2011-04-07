#!/bin/bash
#
# Copyright 2003-2007 Antonio G. Muñoz <antoniogmc (AT) gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
# General script to build and create new packages
#

usage() {
    echo
    echo "usage: pkg_build.sh [script] [action]"
    echo
    echo "    general actions: [info|cleanup]"
    echo "    build actions:   [auto|fetch|verify|unpack|patch|configure|build|install|postinstall]"
    echo "    pkg actions:     [buildpkg|installpkg|upgradepkg]"
    echo
    echo "    example: pkg_build.sh xap/aterm/aterm-0.4.2.build fetch"
}

#load config file
if [ -r build.rc ] ; then
    source build.rc
elif [ -r /etc/pkg/build.rc ] ; then
    source /etc/pkg/build.rc
else
    echo "pkgbuilder: build.rc file not found. You must provide a valid config file"
    exit 1
fi

#global functions
source $PKGBUILDER_LIBS/functions.sh
source $PKGBUILDER_LIBS/pkgfunctions.sh

#print version number
version

#package to build
PKG="$1"

#actions to execute
shift
ACTION="$@"

#verify script to execute
if [ "$PKG" = "" -o "$PKG" = "help" ] ; then
    usage
    exit 1
fi

#verify actions to execute
if [ "$ACTION" = "" ] ; then
    ACTION="auto"
fi

#temporal directory defined?
if [ "$TMP" = "" ]; then
    TMP="/var/tmp"
fi

#create temporal directory if not exist
if [ ! -d $TMP ]; then
    mkdir -p $TMP
fi

if [ ! -f "$PKG" ] ; then
    echo "pkgbuilder: $PKG script not found"
    exit 1
fi

#load base build script
include base

#load build script
source $PKG

#execute action
for i in $ACTION ; do
    execute_action $i
    RETVAL=$?
    
    echo "pkgbuilder: $i action result: `result_msg $RETVAL`"
    
    [ $RETVAL -eq 0 ] || break
done

echo "pkgbuilder: overall result for $PKG: `result_msg $RETVAL`"

exit $RETVAL

