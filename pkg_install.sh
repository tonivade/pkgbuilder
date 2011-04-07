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
# Install a package resolving dependencies
#

usage() {
    echo
    echo "usage: pkg_install.sh [options] [metapkg/pkgname/<script>]"
    echo
    echo "    options:"
    echo "        -v verbose mode"
    echo "        -p from precompiled packages mode"
    echo "        -d dummy mode"
    echo "        -i print package info"
    echo
    echo "    example: pkg_install.sh xap/aterm"
    echo "    example: pkg_install.sh xap/aterm/aterm-0.4.2.build"
}

recursive_install() {
    local METAPKG_BASENAME="`dirname $1`"
    local PKG_BASENAME="`basename $1 .build`"
    local METAPKG="`extract_meta "$METAPKG_BASENAME"`"
    local PKG_NAME="`extract_name "$PKG_BASENAME"`"
    local PKG_VERSION="`extract_version "$PKG_BASENAME"`"

    if [ "$METAPKG" = "" -o "$PKG_NAME" = "" ] ; then
        echo "pkgbuilder: invalid package name \"$1\""
        return 1
    fi

    if [ "$PKG_VERSION" = "" ] ; then
        PKG_VERSION="`latest_version "$METAPKG" "$PKG_NAME"`"
    fi

    local PKG="$PKGBUILDER_HOME/$METAPKG/$PKG_NAME/$PKG_NAME-$PKG_VERSION.build"

    if [ ! -r "$PKG" ] ; then
        echo "pkgbuilder: invalid package file \"$PKG\""
        return 1
    fi

    #add deps from build script
    local PKG_DEPENDS
    local PKG_BUILD_DEPENDS
    source $PKG

    if [ "$VERBOSE" = "Y" ] ; then
        echo
        echo "PKG=\"$PKG\""

        echo "PKG_DEPENDS=\"$PKG_DEPENDS\""
    fi

    if is_installed "$PKG_NAME" "$PKG_VERSION" "$PKG_BUILD" ; then
        echo "pkgbuilder: Package \"$PKG_NAME-$PKG_VERSION-$PKG_BUILD\" allready installed"
        return 0
    fi

    local DEP=""
    local DEP_PKG=""
    local RETVAL=0

    if [ "$MODE" = "frompkg" ] ; then
        DEPS="$PKG_DEPENDS"
    else
        DEPS="$PKG_DEPENDS $PKG_BUILD_DEPENDS"
    fi

    #resolving dependencies
    for DEP in $DEPS ; do
        if [ "$VERBOSE" = "Y" ] ; then
            echo
            echo "DEP=\"$DEP\""
        fi
    
        DEP_METAPKG_BASENAME="`dirname $DEP`"
        DEP_PKG_BASENAME="`basename $DEP`"
    
        if [ "$VERBOSE" = "Y" ] ; then
            echo "DEP_METAPKG_BASENAME=\"$DEP_METAPKG_BASENAME\""
            echo "DEP_PKG_BASENAME=\"$DEP_PKG_BASENAME\""
        fi
    
        #metapkg
        DEP_METAPKG="`extract_meta "$DEP_METAPKG_BASENAME"`"
        DEP_PKG_NAME="`extract_name "$DEP_PKG_BASENAME"`"
        DEP_PKG_VERSION="`extract_version "$DEP_PKG_BASENAME"`"
    
        if [ "$VERBOSE" = "Y" ] ; then
            echo
            echo "DEP_METAPKG=\"$DEP_METAPKG\""
            echo "DEP_PKG_NAME=\"$DEP_PKG_NAME\""
            echo "DEP_PKG_VERSION=\"$DEP_PKG_VERSION\""
        fi
    
        # superhipermega error
        if [ "$DEP_METAPKG" = "" -o "$DEP_PKG_NAME" = "" ] ; then
            echo "pkgbuilder: ERROR invalid values for DEP_METAPKG=\"$DEP_METAPKG\" DEP_PKG_NAME=\"$DEP_PKG_NAME\""
            return 1
        fi
    
        # reset variables
        DEP_PKG_LATEST_VERSION=""
        DEP_PKG_INSTALLED_VERSION=""
    
        if [ "$DEP_PKG_VERSION" != "" ] ; then
            if [ `echo $DEP | grep '^!'` ] ; then
                #pkg must not installed

                is_installed $DEP_PKG_NAME $DEP_PKG_VERSION 
                RESULT=$?

                if [ $RESULT -eq 0 ] ; then 
                    echo "pkgbuilder: ERROR conflict with package $DEP_METAPKG/$DEP_PKG_NAME-$DEP_PKG_VERSION"
                    return 1
                else
                    continue
                fi
            elif [ `echo $DEP | grep '^>='` ] ; then
                #pkg must installed greater or equal version

                DEP_PKG_LATEST_VERSION="`latest_version $DEP_METAPKG $DEP_PKG_NAME`"
            
                if [ "$VERBOSE" = "Y" ] ; then
                    echo "DEP_PKG_LATEST_VERSION=\"$DEP_PKG_LATEST_VERSION\""
                fi

                if is_installed $DEP_PKG_NAME ; then
                    DEP_PKG_INSTALLED_VERSION="`installed_version $DEP_PKG_NAME`"
    
                    if [ "$VERBOSE" = "Y" ] ; then
                        echo "DEP_PKG_INSTALLED_VERSION=\"$DEP_PKG_INSTALLED_VERSION\""
                    fi

                    compare_versions $DEP_PKG_NAME-$DEP_PKG_INSTALLED_VERSION $DEP_PKG_NAME-$DEP_PKG_VERSION
                    RESULT=$?

                    if [ $RESULT -eq 2 ] ; then
                        DEP_PKG_VERSION="$DEP_PKG_LATEST_VERSION"
                    else
                        DEP_PKG_VERSION="$DEP_PKG_INSTALLED_VERSION"
                    fi
                else
                    DEP_PKG_VERSION="$DEP_PKG_LATEST_VERSION"
                fi
            fi
        else 
            if [ `echo $DEP | grep '^!'` ] ; then
                #pkg must not installed

                is_installed $DEP_PKG_NAME
                RESULT=$?

                if [ $RESULT -eq 0 ] ; then 
                    echo "pkgbuilder: ERROR conflict with package $DEP_METAPKG/$DEP_PKG_NAME"
                    return 1
                else
                    continue
                fi
            else
                DEP_PKG_LATEST_VERSION="`latest_version $DEP_METAPKG $DEP_PKG_NAME`"

                if is_installed $DEP_PKG_NAME ; then
                    DEP_PKG_VERSION="`installed_version $DEP_PKG_NAME`"
                else
                    DEP_PKG_VERSION="$DEP_PKG_LATEST_VERSION"
                fi
            fi
        fi
    
        DEP_PKG="$DEP_METAPKG/$DEP_PKG_NAME/$DEP_PKG_NAME-$DEP_PKG_VERSION.build"
    
        if [ "$VERBOSE" = "Y" ] ; then
            echo "DEP_PKG=\"$DEP_PKG\""
        fi

        # if not installed we must install the dependency
        if is_installed $DEP_PKG_NAME $DEP_PKG_VERSION ; then
            if [ "$VERBOSE" = "Y" ] ; then
                echo "pkgbuilder: $DEP allready installed"
            fi
        else
            recursive_install $DEP_PKG
            RETVAL=$?
        
            if [ "$VERBOSE" = "Y"  -o $RETVAL -ne 0 ] ; then
                echo "pkgbuilder: instalation for dependency $DEP_PKG result: `result_msg $RETVAL`"
            fi
                
            if [ $RETVAL -ne 0 ] ; then
                return $RETVAL
            fi
        
            # update environment
            if [ "$MODE" = "install" -o "$MODE" = "frompkg" ] ; then
                source /etc/profile
            fi
        fi
    done

    if is_installed "$PKG_NAME" ; then
        echo "pkgbuilder: upgrading $PKG"
    
        if [ "$MODE" = "install" ] ; then
            ( cd $PKGBUILDER_HOME ; pkg_build.sh $PKG auto cleanup upgradepkg )
            RETVAL=$?
        elif [ "$MODE" = "frompkg" ] ; then
            ( cd $PKGBUILDER_HOME ; pkg_build.sh $PKG upgradepkg )
            RETVAL=$?
        elif [ "$MODE" = "info" ] ; then
            ( cd $PKGBUILDER_HOME ; pkg_build.sh $PKG info )
            RETVAL=$?
        fi
    else
        echo "pkgbuilder: installing $PKG"

        if [ "$MODE" = "install" ] ; then
            ( cd $PKGBUILDER_HOME ; pkg_build.sh $PKG auto cleanup installpkg )
            RETVAL=$?
        elif [ "$MODE" = "frompkg" ] ; then
            ( cd $PKGBUILDER_HOME ; pkg_build.sh $PKG installpkg )
            RETVAL=$?
        elif [ "$MODE" = "info" ] ; then
            ( cd $PKGBUILDER_HOME ; pkg_build.sh $PKG info )
            RETVAL=$?
        fi
    fi

    if [ "$MODE" = "dummy" -o "$MODE" = "info" ] ; then
        PACKAGES_DB="$PACKAGES_DB $PKG_NAME-$PKG_VERSION"
    fi

    if [ "$VERBOSE" = "Y" ] ; then
        echo "pkgbuilder: instalation for $PKG result: `result_msg $RETVAL`"
    fi

    return $RETVAL
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

# Parse options:
OPTIONS=""
MODE="install"

while [ 0 ]; do
    if [ "$1" = "-v" ]; then
        VERBOSE="Y"
        OPTIONS="$OPTIONS -v"
        shift 1
    elif [ "$1" = "-p" ]; then
        MODE="frompkg"
        OPTIONS="$OPTIONS -p"
        shift 1
    elif [ "$1" = "-d" ]; then
        MODE="dummy"
        OPTIONS="$OPTIONS -d"
        shift 1
    elif [ "$1" = "-i" ]; then
        MODE="info"
        OPTIONS="$OPTIONS -i"
        shift 1
    else
        break
    fi
done

#verify script to execute
if [ "$1" = "" -o "$1" = "help" ] ; then
    usage
    exit 1
fi

recursive_install $1

exit $?
