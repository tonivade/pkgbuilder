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

rsync -azvC --delete $RSYNC_MIRROR $PKGBUILDER_HOME && pkg_createdb.sh

