#!/bin/bash
# For use with main-install.sh ONLY
# expects the following variables
# DO_USERDEL=(1|)
# ECHO=echo -e
# LW_VERSION=(4.1|5.0)

#
# Check system type and set some flags
#
$ECHO "Determining OS type..."
OStype=""
kernel=`uname -s`
case "$kernel" in
    Linux)
        if type rpm >/dev/null 2>&1 ; then
            OStype=linux-rpm
        fi
        if type apt-cache >/dev/null 2>&1; then
            OStype=linux-deb
        fi
        ;;
    HP-UX)
        OStype=hpux
        ;;
    SunOS)
        OStype=solaris
        ;;
    AIX)
        OStype=aix
        ;;
    FreeBSD)
        OStype=freebsd
        ;;
    Darwin)
        OStype=darwin
        ;;
    *)
        $ECHO "ERROR: Unknown kernel: $kernel"
        exit_with_error `ERR_OPTIONS`
        exit 1
        ;;
esac
if [ -z "$OStype" ]; then
    $ECHO "ERROR: Unknown OS type (kernel = $kernel )"
    exit_with_error `ERR_OPTIONS`
    exit 1
fi

host=`hostname`
kernel=`uname -s`

#
# Set some flags for each type of OS
# So that we can refer back
# This will grow for a long time
#

TRUE="/bin/true"
AWK="awk"
#
#Set Echo command for RHEL and CENTOS
#
if [ $OStype = "linux-rpm" ]; then
    ECHO="echo -e"
    initpath="/etc/init.d"
    RCDIR="/etc/rc.d"
    PAM_PATH="/etc/pam.d"
    platform=`uname -i`
    df_cmd="df -kl"
    nsfile="nsswitch.conf"
    LOGPATH="/var/log"
elif [ $OStype = "linux-deb" ]; then
    initpath="/etc/init.d"
    RCDIR="/etc"
    PAM_PATH="/etc/pam.d"
    platform=`uname -i`
    if [ "$platform" = "unknown" ]; then
        platform=`uname -m`
    fi
    df_cmd="df -kl"
    nsfile="nsswitch.conf"
    LOGPATH="/var/log"
elif [ $OStype = "freebsd" ]; then
    TRUE="/usr/bin/true"
    ECHO="echo -e"
    initpath="/etc/rc.d"
    RCDIR=""
    PAM_PATH="/etc/pam.d"
    platform=`uname -m`
    if [ "$platform" = "amd64" ]; then
        platform="x86_64"
    fi
    df_cmd="df -kl"
    nsfile="nsswitch.conf"
    LOGPATH="/var/log"
elif [ $OStype = "solaris" ]; then
    AWK="nawk"
    initpath="/etc/init.d"
    RCDIR="/etc/init.d"
    PAM_PATH="/etc/pam.conf"
    platform=`uname -p`
    df_cmd="df -kl"
    nsfile="nsswitch.conf"
    LOGPATH="/var/adm"
    #If Solaris 10, identify if it is a sparse root zone.
    #This has a bearing on upgrades and installs.  sdendin
    if [ -x /usr/sbin/zoneadm ]; then
        if [ `pkgcond is_sparse_root_nonglobal_zone;echo $?` -eq 0 ]; then
            ZONEtype="sparse"
            ZONEOPTS=""
        elif [ `pkgcond is_whole_root_nonglobal_zone;echo $?` -eq 0 ]; then
            ZONEtype="whole"
            ZONEOPTS="-- --current-zone"
        elif [ `pkgcond is_global_zone;echo $?` -eq 0 ]; then
            ZONEtype="global"
            ZONEOPTS="-- --all-zones"
        fi
    else
        ZONEtype=""
        ZONEOPTS=""
    fi
elif [ $OStype = "aix" ]; then
    initpath="/etc/rc.d/init.d"
    RCDIR="/etc/rc.d"
    PAM_PATH="/etc/pam.d"
    platform=`uname -p`
    df_cmd="df -k"
    nsfile="netsvc.conf"
    LOGPATH="/var/adm"
elif [ $OStype = "hpux" ]; then
    initpath="/etc/init.d"
    RCDIR="/etc/rc.d"
    PAM_PATH="/etc/pam.d"
    platform=`getconf _SC_CPU_VERSION`
    # From /usr/include/unistd.h
    case "$platform" in
        524)
            platform=mc68020
            ;;
        525)
            platform=mc68030
            ;;
        525)
            platform=mc68040
            ;;
        523)
            platform=hppa10
            ;;
        528)
            platform=hppa11
            ;;
        529)
            platform=hppa12
            ;;
        532)
            platform=hppa20
            ;;
        768)
            platform=ia64
            ;;
    esac
    df_cmd="df -kl"
    nsfile="nsswitch.conf"
    LOGPATH="/var/adm"
elif [ $OStype = "darwin" ]; then
    TRUE="/usr/bin/true"
    PAM_PATH="/etc/pam.d"
    initpath="/etc/init.d"
    RCDIR="/etc/rc.d"
    platform=`uname -m`
    df_cmd="df -kl"
    nsfile="nsswitch.conf"
    LOGPATH="/var/log"
fi
#
# Set different path to Likewise tools bin folder
# for Linux it's /usr and others are /opt
#

if [ -z "$LW_VERSION" ]; then
    LW_VERSION=`awk -F= '/VERSION/ { print $2 }' /opt/likewise/data/VERSION |awk -F. ' {print $1 "." $2 }'`
fi
if [ $LW_VERSION = "4.1" ]; then
    if [ $OStype = "linux-rpm" ]; then
        LWPath="/usr/centeris/bin"
    elif [ $OStype = "linux-deb" ]; then
        LWPath="/usr/centeris/bin"
    else
        LWPath="/opt/centeris/bin"
    fi
elif [ "$LW_VERSION" = "5.0" ]; then
    LWPath="/opt/likewise/bin"
elif [ "$LW_VERSION" = "5.1" ]; then
    LWPath="/opt/likewise/bin"
elif [ "$LW_VERSION" = "5.2" ]; then
    LWPath="/opt/likewise/bin"
elif [ "$LW_VERSION" = "5.3" ]; then
    LWPath="/opt/likewise/bin"
elif [ "$LW_VERSION" = "5.4" ]; then
    LWPath="/opt/likewise/bin"
elif [ "$LW_VERSION" = "6.0" ]; then
    LWPath="/opt/likewise/bin"
elif [ "$LW_VERSION" = "6.1" ]; then
    LWPath="/opt/likewise/bin"
else
    $ECHO "ERROR!! Unknown version $LW_VERSION!"
    exit_with_error `ERR_OPTIONS`
fi

$ECHO "OS: $OStype"
$ECHO "Platform: $platform"
$ECHO "Kernel: $kernel"
$ECHO "Likewise: $LW_VERSION"
