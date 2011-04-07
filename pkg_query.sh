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
    echo "usage: pkg_query.sh <option> <package name| file name>"
    echo
	echo "    -v    print the installed version of package"
	echo "    -i    print information of package"
    echo "    -l    print file list of package"
    echo "    -s    search the package owner of the file"
    echo
    echo "    example: pkg_query.sh -v aterm"
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

OPTION=""

while [ 0 ]; do
    if [ "$1" = "-i" ]; then
        OPTION="info"
        shift 1
    elif [ "$1" = "-v" ]; then
        OPTION="version"
        shift 1
    elif [ "$1" = "-l" ]; then
        OPTION="list"
        shift 1
    elif [ "$1" = "-s" ]; then
        OPTION="search"
        shift 1
    else
        break
    fi
done

if [ "$OPTION" = "" ] ; then
    version
	usage
	exit 1
fi

name=$1

case $OPTION in
    "version")
        if [ "$name" != "" ] ; then
            if is_installed $name ; then
                installed $name
            else
                echo "pkgbuilder: package $name not found in system"
            fi
        else
            ( cd $PACKAGES_LOGDIR ; find -type f | cut -d/ -f2 | sort -u )
        fi
    ;;
     "info")
        if is_installed $name ; then
            ver="`installed_version $name`"
            offset="`grep -n 'FILE LIST:' $PACKAGES_LOGDIR/$name-$ver-* | cut -d: -f1`"
            head -n$offset $PACKAGES_LOGDIR/$name-$ver-* | grep -v 'FILE LIST:'
        else
            echo "pkgbuilder: package $name not found in system"
        fi
    ;;
    "list")
        if is_installed $name ; then
            cat $PACKAGES_LOGDIR/$name-`installed_version $name`-* | grep / | grep -v : | sort -u
        else
            echo "pkgbuilder: package $name not found in system"
        fi
    ;;
    "search")
        ( cd $PACKAGES_LOGDIR ; find -type f | xargs grep $name | cut -d: -f1 | cut -d/ -f2 | sort -u )
    ;;
esac

