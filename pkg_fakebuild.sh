#!/bin/bash
#
# Copyright 2003-2007 Antonio G. Muñoz <antoniogmc (AT) gmail.com>
# Distributed under the terms of the GNU General Public License v2
#

PATH=/sbin:/usr/sbin:$PATH fakeroot pkg_build.sh $@
