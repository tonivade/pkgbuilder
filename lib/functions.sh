# Copyright 2003-2007 Antonio G. Muñoz <antoniogmc (AT) gmail.com>
# Distributed under the terms of the GNU General Public License v2

#
# Generic functions
#

#
# Print pkgbuilder version number
#
version() {
    echo "pkgbuilder 0.2.8.3"
}

#
# Include a file of the common directory
#
# @param $1 file name to include
#
include() {
    if [ "$1" = "" ] ; then
        return 1  
    fi

    if [ -r $PKGBUILDER_LIBS/common/$1.build ] ; then
        source $PKGBUILDER_LIBS/common/$1.build
    elif [ -r $PKGBUILDER_HOME/common/$1.build ] ; then
        source $PKGBUILDER_HOME/common/$1.build
    fi
    
    return $?
}

#
# Include a build file
#
# @param $1 parent build file
#
inherit() {
    if [ "$1" = "" ] ; then
        return 1  
    fi
    
    include $1
    
    PKG_PARENT="$1 $PKG_PARENT"
    
    #call initializador
    if declare -f $1_init &> /dev/null ; then
        $1_init || return $?
    fi
    
    return $?
}

#
# Returns if in use variable exists use parameter
#
# @param $1 use parameter
#
use() {
    if [ "$1" = "" ] ; then
        return 1  
    fi
    
    ( echo $USE | grep -o "\+$1\b" &> /dev/null ) && return 0
    ( echo $USE | grep -o "\-$1\b" &> /dev/null ) && return 1
    ( echo $USE | grep -o "\b$1\b" &> /dev/null ) && return 0 || return 1
}

#
# Print the dep if use flag is activated
#
# @param $1 use parameter
# @param $2 dependency
# @param $3 other dependency
#
use_dep() {
    if [ "$1" = "" ] ; then
        return 1  
    fi
    
    if [ "$2" = "" ] ; then
        return 1  
    fi
    
    if `use $1` ; then
        echo $2
    elif [ "$3" != "" ] ; then
        echo $3
    fi
}

#
# Print the enable option if use flag is activated
#
# @param $1 use parameter
# @param $2 enable option (optional)
#
use_enable() {
    if [ "$1" = "" ] ; then
        return 1  
    fi
    
    if `use $1` ; then
        if [ "$2" = "" ] ; then
            echo -n "--enable-$1"
        else
            echo -n "--enable-$2"
        fi
    else
        if [ "$2" = "" ] ; then
            echo -n "--disable-$1"
        else
            echo -n "--disable-$2"
        fi
    fi
}

#
# Print the with option if use flag is activated
#
# @param $1 use parameter
# @param $2 with option (optional)
#
use_with() {
    if [ "$1" = "" ] ; then
        return 1  
    fi
    
    if `use $1` ; then
        if [ "$2" = "" ] ; then
            echo -n "--with-$1"
        else
            echo -n "--with-$2"
        fi
    else
        if [ "$2" = "" ] ; then
            echo -n "--without-$1"
        else
            echo -n "--without-$2"
        fi
    fi
}

use_option() {
    if [ "$1" = "" ] ; then
        return 1  
    fi

    ( echo "$PKG_OPTIONS $OPTIONS" | grep -o "\-$1\b" &> /dev/null ) && return 1 || return 0
}


#
# Call the action function if exists
#
# @param $1 action function
#
call_action() {
    if [ "$1" = "" ] ; then
        return 1
    fi
    
    local retval=0

    if declare -f $1 &> /dev/null ; then
        echo "pkgbuilder: function \"$1\" declared in build script"
        $1
        retval=$?
    else
        local found="false"

        local super
        for super in $PKG_PARENT ; do
            if declare -f ${super}_$1 &> /dev/null ; then
                # we found the function declaration
                found="true"
                echo "pkgbuilder: function \"$1\" declared in \"$super\""

                # call the function a remember retval
                ${super}_$1
                retval=$?
                
                break
            fi
        done

        # if we don't found the function declaration
        if [ "$found" = "false" ] ; then
            if declare -f pkg_$1 &> /dev/null ; then
                # call the master implementation if is declared
                echo "pkgbuilder: function \"$1\" declared in base"
                pkg_$1
                retval=$?
            else
                echo "pkgbuilder: $1 function not defined in build script"
                retval=$?
            fi
        fi
    fi

    return $retval
}

#
# Execute the given action and returns the result of the action
#
# @param $1 action name
#
execute_action() {
    if [ "$1" = "" ] ; then
        return 1  
    fi
    
    local retval=0

    #execution
    case "$1" in
        'info')
            call_action do_info
            retval=$?
        ;;
        'fetch')
            call_action do_fetch
            retval=$?
        ;;
        'verify')
            call_action do_verify
            retval=$?
        ;;
        'unpack')
            call_action do_unpack
            retval=$?
        ;;
        'patch')
            call_action do_patch
            retval=$?
        ;;
        'configure')
            call_action do_configure
            retval=$?
        ;;
        'build')
            call_action do_build
            retval=$?
        ;;
        'install')
            call_action do_install
            retval=$?
        ;;
        'postinstall')
            call_action do_postinstall
            retval=$?
        ;;
        'buildpkg')
            call_action do_buildpkg
            retval=$?
        ;;
        'installpkg')
            call_action do_installpkg
            retval=$?
        ;;
        'upgradepkg')
            call_action do_upgradepkg
            retval=$?
        ;;
        'cleanup')
            call_action do_cleanup
            retval=$?
        ;;
        'auto')
            call_action do_fetch && 
            call_action do_verify &&
            call_action do_unpack &&
            call_action do_patch && 
            call_action do_configure &&
            call_action do_build &&
            call_action do_install &&  
            call_action do_postinstall && 
            call_action do_buildpkg
            retval=$?
        ;;
        *)
            retval=1
    esac
    
    return $retval
}

#
# Fetch a file using wget. Firt try in local mirror, if fail then try with 
# the original URL
#
# @param $1 url
#
fetch() {
    if [ "$1" = "" ] ; then
        return 1  
    fi
    
    if [ "$2" = "" ] ; then
        return 1  
    fi
    
    if [ ! -d $FETCH_DIR ] ; then
        mkdir -p $FETCH_DIR
    fi

    local retval=0
    local file="$2"
    local fetch_options="$FETCH_OPTIONS"
    
    if [ `echo $1 | grep "^ftp"` ] ; then
        fetch_options="$fetch_options $FETCH_FTP_OPTIONS"
    elif [ `echo $1 | grep "^https"` ] ; then
        fetch_options="$fetch_options $FETCH_HTTPS_OPTIONS"
    fi

    fetch_options="`echo $fetch_options | sed -e "s|%o|$file.part|"`"
    
    if [ "$MIRROR_URL" != "" ] ; then
        local mirror_fetch_options="$fetch_options $MIRROR_FETCH_OPTIONS"

        wget -c $mirror_fetch_options $MIRROR_URL/$file || wget -c $fetch_options $1
        retval=$?
    else 
        wget -c $fetch_options $1
        retval=$?
    fi

    if [ $retval -eq 0 ] ; then
        mv $FETCH_DIR/$file.part $FETCH_DIR/$file
    else
        rm $FETCH_DIR/$file.part
    fi

    return $retval
}

#
# find a file in all the posible locations
# 
# @param $1 file name
#
find_file() {
    if [ "$1" = "" ] ; then
        echo $1
        return 1  
    fi
    
    local file
    
    if [ "$CDROM_DIR" != "" -a -r "$CDROM_DIR/$1" ] ; then
        file="$CDROM_DIR/$1"
    elif [ -r "$FETCH_DIR/$1" ] ; then
        file="$FETCH_DIR/$1"
    elif [ -r "$PKG_FILES/$1" ] ; then
        file="$PKG_FILES/$1"
    elif [ -r "$PKG_UNPACK/$1" ] ; then
        file="$PKG_UNPACK/$1"
    else
        file="$1"
    fi

    echo $file
}

#
# Unpack a file
#
# @param $1 file name
#
unpack() {
    if [ "$1" = "" ] ; then
        return 1  
    fi
    
    local retval=0
    local file="`find_file $1`"

    test -r $file || return 1
    
    if echo $1 | grep -q ".tar.gz$" ; then
        tar zxvf $file
        retval=$?
    elif echo $1 | grep -q ".tgz$" ; then
        tar zxvf $file
        retval=$?
    elif echo $1 | grep -q ".tar.bz2$" ; then
        tar jxvf $file
        retval=$?
    elif echo $1 | grep -q ".tar$" ; then
        tar xvf $file
        retval=$?
    elif echo $1 | grep -q ".tbz2$" ; then
        tar jxvf $file
        retval=$?
    elif echo $1 | grep -q ".zip$" ; then
        unzip $file
        retval=$?
    fi
        
    return $retval
}

#
# Apply a patch. First search the patch in CDROM_DIR, else in FETCH_DIR, and finally
# in $PKG_HOME files directory.
#
# @param $1 patch file name
# @param $@ patch options
#
apply_patch() {
    if [ "$1" = "" ] ; then
        return 1  
    fi
    
    local file="`find_file $1`"
    
    shift

    if [ \! -r $file ] ; then
        echo "pkgbuilder: $file not exist"
        return 1
    fi

    echo "=> Applying patch $file"

    if echo $file | grep -q ".gz$" ; then
        zcat $file | patch "$@"
    elif echo $file | grep -q ".bz2$" ; then
        bzcat $file | patch "$@"
    else
        cat $file | patch "$@"
    fi
    
    return $?
}

#
# Verify a package file md5sum
#
# @param $1 package file name
# @param $2 md5sum file name
#
verify() {
    if [ "$1" = "" ] ; then
        return 1  
    fi
    
    if [ "$2" = "" -a -r "$2" ] ; then
        return 1  
    fi
    
    local base="`basename "$1"`"

    local sumprogram="md5sum -t"
    if echo `basename $2` | grep -q "^sha1sum" ; then
        sumprogram="sha1sum -t"
    fi
    
    if [ -r "$FETCH_DIR/$base" ] ; then
        if ! grep -q "`$sumprogram $FETCH_DIR/$base | cut -d" " -f1`  `basename "$1"`" $2  ; then
            echo "pkgbuilder: ERROR, $sumprogram verification error at file $FETCH_DIR/$base"
            return 2
        fi
    elif [ -r "$CDROM_DIR/$base" ] ; then
        if ! grep -q "`$sumprogram $CDROM_DIR/$base | cut -d" " -f1`  `basename "$1"`" $2  ; then
            echo "pkgbuilder: ERROR, $sumprogram verification error at file $CDROM_DIR/$base"
            return 2
        fi
    else
        return 1
    fi
}

#
# Gzip all the man pages under the given directory
#
# @param $1 base directory
#
gzip_man() {
    if [ "$1" = "" ] ; then
        return 1
    fi
    
    if [ ! -d $1 ]; then
        return 0
    fi
    
    find $1 -type f | xargs gzip -9 &> /dev/null
        
    return $?
}

#
# Gzip all the info files under the given directory
#
# @param $1 base directory
#
gzip_info() {
    if [ "$1" = "" ] ; then
        return 1
    fi
    
    if [ ! -d $1 ]; then
        return 0
    fi
    
    find $1 -type f -name '*.info-*' | xargs gzip -9 &> /dev/null
    find $1 -type f -name '*.info' | xargs gzip -9 &> /dev/null
        
    return $?
}

#
# fix binary file permisions
#
# @param $1 base directory
#
fix_bin_perms() {
    if [ "$1" = "" ] ; then
        return 1
    fi

    if [ -d "$1" ] ; then
        chgrp bin $1
        local file
        for file in `find $1 -type f -group root` ; do
            if [ -u $file -a -g $file ] ; then
                chgrp bin $file
                chmod +s $file
            elif [ -u $file ] ; then
                chgrp bin $file
                chmod u+s $file
            elif [ -g $file ] ; then
                chgrp bin $file
                chmod g+s $file
            else
                chgrp bin $file
            fi
        done
    fi
}

#
# Strip all the files under the given directory
#
# @param $1 base directory
#
strip_all() {
    if [ "$1" = "" ] ; then
        return 1
    fi

    find $1 -type f | xargs file | grep ELF | cut -f 1 -d : | xargs strip --strip-unneeded

    return $?
}

#
# Returns if a package is installed
#
# @param $1 package name
# @param $2 package version (optional)
# @param $3 package build (optional)
#
is_installed() {
    if [ "$1" = "" ] ; then
        return 1
    fi
    
    local retval=1
    
    if [ "$2" = "" ] ; then
        ls $PACKAGES_LOGDIR/$1-*-*-* 2> /dev/null | grep "$1\-[0-9]" &> /dev/null
        retval=$?
    elif [ "$3" = "" ] ; then
        ls $PACKAGES_LOGDIR/$1-$2-*-* &> /dev/null
        retval=$?
    else
        ls $PACKAGES_LOGDIR/$1-$2-*-*$3* &> /dev/null
        retval=$?
    fi

    if [ $retval -ne 0 ] && [ "$MODE" = "dummy" -o "$MODE" = "info" ] ; then
        if [ "$2" = "" ] ; then
            echo $PACKAGES_DB | grep -q "$1-[0-9]"
            retval=$?
        else
            echo $PACKAGES_DB | grep -q "$1-$2"
            retval=$?
        fi
    fi
    
    return $retval
}

#
# Returns if a package is marcked as unstable
#
# @param $1 package name
#
is_masked() {
    if [ "$1" = "" ] ; then
        return 0
    fi

    use masked && return 1

    eval "`grep "PKG_MASKED=" $PKGBUILDER_HOME/$1`"

    test "$PKG_MASKED" = "Y"
    local result=$?

    unset PKG_MASKED
    return $result
}

#
# Compare version numbers. Returns 0 if equals, 1 if b < a and 2 if b > a
#
# @param $1 package a
# @param $2 package b
#
compare_versions() {
    if [ "$1" = "" -o "$2" = "" ] ; then
        return 1
    fi
    
    local av1="`extract_version $1`"
    local av2="`extract_version $2`"

    local v1="`extract_only_version $av1`"
    local v2="`extract_only_version $av2`"
    
    local tmp1
    local tmp2
    
    for field in 1 2 3 4 5 6 7 8 9 10 ; do
        tmp1="`echo $v1 | cut -d. -f$field`"
        tmp2="`echo $v2 | cut -d. -f$field`"
        
        if [ "$tmp1" = "" -a "$tmp2" = "" ] ; then
            break
        elif [ "$tmp1" = "" -a "$tmp2" != "" ] ; then
            #greater
            return 2
        elif [ "$tmp1" != "" -a "$tmp2" = "" ] ; then
            #lesser
            return 1
        fi

        if echo $tmp1 | grep -q "[a-zA-Z]\+" ||
           echo $tmp2 | grep -q "[a-zA-Z]\+" ; then
            if [[ "$tmp2" < "$tmp1" ]] ; then
                return 1
            elif [[ "$tmp2" > "$tmp1" ]] ; then
                return 2
            else
                continue
            fi
        else  
            if [ "$tmp2" -lt "$tmp1" ] ; then
                return 1
            elif [ "$tmp2" -gt "$tmp1" ] ; then
                return 2
            else
                continue
            fi
        fi
    done
    
    local extra1="`extract_extra_version $av1`"
    local extra2="`extract_extra_version $av2`"
    
    if [ "$extra1" != "" -o "$extra2" != "" ] ; then
        if [ "$extra1" = "" -a "$extra2" != "" ] ; then
            #lesser
            return 1
        elif [ "$extra1" != "" -a "$extra2" = "" ] ; then
            #greater
            return 2
        fi
        
        if echo $extra1 | grep -q "[a-zA-Z]\+" ||
           echo $extra2 | grep -q "[a-zA-Z]\+" ; then
            if [[ "$extra2" < "$extra1" ]] ; then
                return 1
            elif [[ "$extra2" > "$extra1" ]] ; then
                return 2
            fi
        else  
            if [ "$extra2" -lt "$extra1" ] ; then
                return 1
            elif [ "$extra2" -gt "$extra1" ] ; then
                return 2
            fi
        fi
    fi
    
    return 0;
}

#
# Print the latest version of a package
#
# @param $1 meta package
# @param $2 package name
#
latest_version() {
    if [ "$1" = "" -o "$2" = "" ] ; then
        return 1
    fi
    
    if [ ! -d "$PKGBUILDER_HOME/$1/$2" ] ; then
        return 2
    fi
    
    local buildfiles=`cd $PKGBUILDER_HOME/$1/$2 ; ls -v1 *.build`
    
    if [ "$buildfiles" != "" ] ; then
        local latestbuildfile=""
        
        for i in $buildfiles ; do
            if [ "$latestbuildfile" = "" ] ; then
                latestbuildfile="$i"
                continue
            fi
            
            compare_versions `basename $latestbuildfile .build` `basename $i .build`
            local result=$?
            
            if [ $result -eq 2 ] && ! is_masked $1/$2/$i ; then
                latestbuildfile="$i"
            fi
        done
        
        latestbuildfile="`basename $latestbuildfile .build`"

        local pkgversion="`extract_version $latestbuildfile`"
        
        echo "$pkgversion"
    else
        return 1
    fi
}

#
# Print instaled version of package
#
# @param $1 package name
#
installed_version() {
    if [ "$1" = "" ] ; then
        return 1
    fi
    
    if ls $PACKAGES_LOGDIR/$1-*-*-* &> /dev/null ; then
        local pkgfile=`cd $PACKAGES_LOGDIR ; ls -1 $1-*-*-* | grep "^$1\-[0-9]"`
    else
        return 2
    fi
    
    if [ -r "$PACKAGES_LOGDIR/$pkgfile" ] ; then
        pkgfile="`echo $pkgfile | sed -e 's:\-[a-zA-Z0-9]\+\-[a-z]*[0-9]\+[a-z]*$::'`"
        
        local pkgversion="`extract_version $pkgfile`"
        
        echo "$pkgversion"
    else
        return 1
    fi
}

#
# Print instaled build of package
#
# @param $1 package name
#
installed_build() {
    if [ "$1" = "" ] ; then
        return 1
    fi
    
    if ls $PACKAGES_LOGDIR/$1-*-*-* &> /dev/null ; then
        local pkgfile=`cd $PACKAGES_LOGDIR ; ls -1 $1-*-*-* | grep "^$1\-[0-9]"`
    else
        return 2
    fi
    
    if [ -r "$PACKAGES_LOGDIR/$pkgfile" ] ; then
        local pkgbuild="`expr match "$pkgfile" '.*\-[a-z]*\([0-9]\+\)[a-z]*'`"
        
        echo "$pkgbuild"
    else
        return 1
    fi
}

#
# Print instaled arch of package
#
# @param $1 package name
#
installed_arch() {
    if [ "$1" = "" ] ; then
        return 1
    fi
    
    if ls $PACKAGES_LOGDIR/$1-*-*-* &> /dev/null ; then
        local pkgfile=`cd $PACKAGES_LOGDIR ; ls -1 $1-*-*-* | grep "^$1\-[0-9]"`
    else
        return 2
    fi
    
    if [ -r "$PACKAGES_LOGDIR/$pkgfile" ] ; then
        local pkgarch="`expr match "$pkgfile" '.*\-\(\w\+\)\-[a-z]*[0-9]\+[a-z]*'`"
        
        echo "$pkgarch"
    else
        return 1
    fi
}

installed() {
    if [ "$1" = "" ] ; then
        return 1
    fi

    if is_installed $1 ; then
        echo $1-`installed_version $1`-`installed_arch $1`-`installed_build $1`
    fi
}

#
# Print meta package name
#
# @param $1 package dep in format >=meta/pkgname-1.2
#
extract_meta() {
    if [ "$1" = "" ] ; then
        return 1
    fi
    
    local metapkg="`expr match "$1" '\!\?>\?=\?\([a-z0-9]\+\)/\?'`"
    
    echo "$metapkg"
}

#
# Print name of package
#
# @param $1 pkgfile in format pkgname-1.2
#
extract_name() {
    if [ "$1" = "" ] ; then
        return 1
    fi
    
    local pkgname="`expr match "$1" '\([a-zA-Z0-9_+\-]\+\)\-[0-9]'`"
    
    if [ "$pkgname" != "" ] ; then
        echo "$pkgname"
    else
        echo "$1"
    fi
}

#
# Print version of package
#
# @param $1 pkgfile in format pkgname-1.2
#
extract_version() {
    if [ "$1" = "" ] ; then
        return 1
    fi
    
    local pkgmayorversion="`expr match "$1" '[a-zA-Z0-9_+\-]\+\-\([0-9]\)'`"
    local pkgminorversion="`expr match "$1" '[a-zA-Z0-9_+\-]\+\-[0-9]\([a-zA-Z0-9_\.]\+\)'`"

    echo "$pkgmayorversion$pkgminorversion"
}

#
# Print version of package without extra version. 3.2.2_extraversion
#
# @param $1 version in format 3.2.2_extraversion
#
extract_only_version() {
    if [ "$1" = "" ] ; then
        return 1
    fi

    local extra_index="`expr index $1 '_'`"

    if [ "$extra_index" -gt "0" ] ; then
        echo "`echo $1 | cut -d'_' -f1`"
    else
        echo "$1"
    fi
}

#
# Print extra version of package. 3.2.2_extraversion
#
# @param $1 version in format 3.2.2_extraversion
#
extract_extra_version() {
    if [ "$1" = "" ] ; then
        return 1
    fi

    local extra_index="`expr index $1 '_'`"

    if [ "$extra_index" -gt "0" ] ; then
        echo "`echo $1 | cut -d'_' -f2`"
    fi
}

#
# Print result message
#
# @param $1 result value
#
result_msg() {
    if [ $1 -eq 0 ] ; then
        echo "SUCCESS"
    else    
        echo "ERROR"
    fi
}
