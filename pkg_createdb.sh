#!/bin/sh
#
# Copyright 2003-2007 Antonio G. Muñoz <antoniogmc (AT) gmail.com>
# Distributed under the terms of the GNU General Public License v2
#

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

PKG_LIST="`cd $PKGBUILDER_HOME ; find ./ -type f -name '*.build' -exec dirname {} \; | grep -v example | grep -v common | grep -v CVS | grep -v test | sort | uniq`"

rm -f $PKGBUILDER_HOME/PACKAGES

for i in $PKG_LIST ; do
    pkg_meta="`echo "$i" | cut -d/ -f2`"
    pkg_name="`echo "$i" | cut -d/ -f3`"

    echo $pkg_meta/$pkg_name-`latest_version $pkg_meta $pkg_name` >> $PKGBUILDER_HOME/PACKAGES
done

