# Copyright 2003-2007 Antonio G. Muñoz <antoniogmc (AT) gmail.com>
# Distributed under the terms of the GNU General Public License v2

#
# Package specific functions
#

pkg_installdoc() {
    if use_option doc ; then
        mkdir -p $PKG_DOC

        cd $PKG_SRC

        cp -R $PKG_DOC_FILES $PKG_DOC
        find $PKG_DOC -type f -exec chmod 644 {} \;
        find $PKG_DOC -type d -exec chmod 755 {} \;
    fi
}

pkg_stripall() {
	if use_option "strip" ; then 
		strip_all $PKG_DEST || return 1
	fi

	return 0
}

pkg_gzipmaninfo() {
    gzip_man $PKG_DEST$PKG_PREFIX/man

    if [ -f $PKG_DEST$PKG_PREFIX/info/dir ] ; then
        rm -f $PKG_DEST$PKG_PREFIX/info/dir
    fi

    gzip_info $PKG_DEST$PKG_PREFIX/info
}

pkg_configfiles() {
    if [ "$PKG_CONFIG_FILES" != "" ] ; then
        mkdir -p $PKG_DEST/install

        for config in $PKG_CONFIG_FILES ; do
            mv $PKG_DEST/$config $PKG_DEST/$config.new
        done

        cat >> $PKG_DEST/install/doinst.sh << "EOF"
#!/bin/sh
config() {
  NEW="$1"
  OLD="`dirname $NEW`/`basename $NEW .new`"
  # If there's no config file by that name, mv it over:
  if [ ! -r $OLD ]; then
    mv $NEW $OLD
  elif [ "`cat $OLD | md5sum`" = "`cat $NEW | md5sum`" ]; then # toss the redundant copy
    rm $NEW
  fi
  # Otherwise, we leave the .new copy for the admin to consider...
}
EOF

        for config in $PKG_CONFIG_FILES ; do
            echo "config $config.new" >> $PKG_DEST/install/doinst.sh
        done
    fi
}

pkg_installfiles() {
    mkdir -p $PKG_DEST/install

    cat $PKG_HOME/files/slack-desc > $PKG_DEST/install/slack-desc

    if [ "$PACKAGER_NAME" != "" ] ; then
        echo "$PKG_NAME: " >> $PKG_DEST/install/slack-desc
        if [ "$PACKAGER_EMAIL" != "" ] ; then
            echo "$PKG_NAME: Package Created By: $PACKAGER_NAME ($PACKAGER_EMAIL)" >> $PKG_DEST/install/slack-desc
        else
            echo "$PKG_NAME: Package Created By: $PACKAGER_NAME" >> $PKG_DEST/install/slack-desc
        fi
    fi

    if [ -f $PKG_HOME/files/doinst.sh-$PKG_VERSION ] ; then
        cat $PKG_HOME/files/doinst.sh-$PKG_VERSION | grep -v '^#' >> $PKG_DEST/install/doinst.sh
    elif [ -f $PKG_HOME/files/doinst.sh ] ; then
        cat $PKG_HOME/files/doinst.sh | grep -v '^#' >> $PKG_DEST/install/doinst.sh
    fi
}

pkg_installmorefiles() {
    mkdir -p $PKG_DEST/install

    if [ "$PKG_DEPENDS" != "" ] ; then
        local pkg
        for pkg in $PKG_DEPENDS ; do
            dep_basename="`basename $pkg`"
            dep_pkg_name="`extract_name $dep_basename`"
            dep_pkg_version="`extract_version $dep_basename`"
            if [ `echo $pkg | grep '^!'` ] ; then
                echo "$dep_pkg_name" >> $PKG_DEST/install/slack-conflicts
            elif [ `echo $pkg | grep '^='` ] ; then
                echo "$dep_pkg_name = $dep_pkg_version" >> $PKG_DEST/install/slack-required
            elif [ `echo $pkg | grep '^>='` ] ; then
                echo "$dep_pkg_name >= $dep_pkg_version" >> $PKG_DEST/install/slack-required
            else
                echo "$dep_pkg_name" >> $PKG_DEST/install/slack-required
            fi
        done
    fi

    unset dep_basename dep_pkg_name dep_pkg_version
}

pkg_fetchfiles() {
    local pkg
    local file
    for pkg in $PKG_URL ; do
        file="`pkg_filename $pkg`"

        test -f $FETCH_DIR/$file || fetch $pkg $file || return 1
    done

    return 0
}

pkg_filename() {
    if [ "$1" = "" ] ; then
        return 1  
    fi
    
    local file
    if [ "$PKG_FILE_NAME" = "" ] ; then
        file="`basename $1`"
        file="`echo $file | cut -d"?" -f1`"
    else
        file="$PKG_FILE_NAME"
    fi
    echo $file
}

pkg_fetchcvs() {
    cd $PKG_UNPACK

    echo "$PKG_CVSPASSWD" | cvs -d $PKG_CVSROOT login &&
    cvs -d $PKG_CVSROOT co -d $PKG_NAME-$PKG_VERSION $PKG_MODULE

    return $?
}

pkg_verify() {
    if [ "$1" = "" ] ; then
        return 1  
    fi

    local sum="$PKG_HOME/files/$1"
    
    if [ -f $sum ] ; then
        for pkg in $PKG_URL ; do
            verify $pkg $sum || return 1
        done
    else 
        echo "pkgbuilder: WARNING no $1 file found. Continue? (Y/n)"
	read option
	if [ "$option" = "n" ] ; then
	    return 1
	fi
    fi
    
    return $?
}

pkg_unpack() {
    local file
    
    for file in $PKG_URL ; do
        unpack `pkg_filename $file`
    done
    
    return $RETVAL
}

pkg_configure() {
    if [ \! -x ./configure ] ; then
        echo "pkgbuilder: configure script not found in `pwd`"
        return 1
    fi

    local _options="$PKG_CONFIGURE_OPTIONS"
    if [ $# -gt 0 ] ; then
        _options=$@
    fi

    CFLAGS=$CFLAGS \
    CXXFLAGS=$CXXFLAGS \
    CPPFLAGS=$CPPFLAGS \
    LDFLAGS=$LDFLAGS \
    ./configure --prefix=$PKG_PREFIX $_options

    return $?
}

pkg_build() {
    if [ \! -r Makefile ] ; then
        echo "pkgbuilder: Makefile not found in `pwd`"
        return 1
    fi

    local _options="$PKG_BUILD_OPTIONS $PKG_BUILD_TARGET"
    if [ $# -gt 0 ] ; then
        _options=$@
    fi

    if [ "$COMPILATION" = "parallel" ] ; then
        DISTCC_HOSTS="$DISTCC_HOSTS" \
        CCACHE_PREFIX="$CCACHE_PREFIX" \
        make $MAKE_OPTIONS $_options
        RETVAL=$?
    else
        make -j1 $_options
        RETVAL=$?
    fi

    return $RETVAL
}

pkg_install() {
    if [ \! -r Makefile ] ; then
        echo "pkgbuilder: Makefile not found in `pwd`"
        return 1
    fi

    if [ "$PKG_INSTALL_OPTIONS" = "" ] ; then
        PKG_INSTALL_OPTIONS="DESTDIR=$PKG_DEST"
    fi
    
    if [ "$PKG_INSTALL_TARGET" = "" ] ; then
        PKG_INSTALL_TARGET="install"
    fi
    
    local _options="$PKG_INSTALL_OPTIONS $PKG_INSTALL_TARGET"
    if [ $# -gt 0 ] ; then
        _options=$@
    fi

    make $_options

    return $?
}

pkg_virtual() {
    if [ "$PKG_VIRTUAL" != "" ] ; then
        mkdir -p $PKG_DEST/install
        
        cat >> $PKG_DEST/install/doinst.sh << "EOF"
virtual() {
  ( cd var/log/packages ; ln -sf $1 $2-virtual-1 )
}
EOF

        for virtual in $PKG_VIRTUAL ; do
            if [ "$PACKAGER_INITIALS" = "" ] ; then
                echo "virtual $PKG_NAME-$PKG_VERSION-${PKG_ARCH/-/}-$PKG_BUILD $virtual" >> $PKG_DEST/install/doinst.sh
            else
                echo "virtual $PKG_NAME-$PKG_VERSION-${PKG_ARCH/-/}-$PKG_BUILD$PACKAGER_INITIALS $virtual" >> $PKG_DEST/install/doinst.sh
            fi
        done
    fi
}

pkg_localeclean() {
    if [ -f "$PKG_DEST$PKG_PREFIX/share/locale/locale.alias" ] ; then
        rm -f $PKG_DEST$PKG_PREFIX/share/locale/locale.alias
    fi
}

pkg_activedflags() {
    if [ "$PKG_USE" != "" ] ; then
        for u in $PKG_USE ; do
            use $u && echo -n " +$u" || echo -n " -$u"
        done
        echo
    fi
}

pkg_postinstall() {
    pkg_installdoc &&
    pkg_stripall &&
    pkg_gzipmaninfo &&
    pkg_localeclean &&
    pkg_configfiles &&
    pkg_installfiles &&
    pkg_installmorefiles
}
