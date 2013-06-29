#!/bin/sh

# Editor Settings: expandtabs and use 4 spaces for indentation
# ex: set softtabstop=4 tabstop=8 expandtab shiftwidth=4:

ECHO="echo" # Update in get-ostype.sh to specify different version of echo
AWK="awk" # Update in get-ostype.sh to specify different version of awk
TRUE="/bin/true"

# Because you never know what you're going to get...
BURYOUTPUT=`unalias cp 2>&1`
BURYOUTPUT=`unalias mv 2>&1`

#
# Error usage:
# 
# error `ERR_OPTIONS`
# error `ERR_ACCESS`
# error `ERR_OPTIONS`
# exit_with_error `ERR_LDAP`
# 
# or:
# 
# error `ERR_OPTIONS`
# error `ERR_ACCESS`
# exit_with_status
# 
# or
# 
# error `ERR_OPTIONS`
# error `ERR_ACCESS`
# exit_status
#
# or
# 
# error `ERR_OPTIONS`
# error `ERR_ACCESS`
# exit_if_error
# --- more code
#
ERR_UNKNOWN ()      { echo 1; }
ERR_OPTIONS ()      { echo 2; }
ERR_OS_INFO ()      { echo 2; }
ERR_ACCESS  ()      { echo 4; }
ERR_FILE_ACCESS ()  { echo 4; }
ERR_SYSTEM_CALL ()  { echo 8; }
ERR_DATA_INPUT  ()  { echo 16; }
ERR_LDAP        ()  { echo 32; }
ERR_NETWORK ()      { echo 64; }
ERR_CHOWN   ()      { echo 256; }
ERR_STAT    ()      { echo 512; }
ERR_MAP     ()      { echo 1024; }

gRetVal=0

error()
{
    A=$gRetVal
    B=$1
    while [ $B -ne 0 ] ; do
        SaveA=$A
        A=`expr \$A \/ 2`
        B=`expr \$B \/ 2`
    done
    A=`expr \$A \* 2`
    if [ $SaveA -eq $A ] ; then
        gRetVal=`expr \$gRetVal \+ $1`
    fi
    return $gRetVal
}
exit_with_error()
{
    error $1
    exit $gRetVal
}
exit_if_error()
{
    if [ $gRetVal -ne 0 ]; then
        exit $gRetVal
    fi
}
exit_status()
{
    exit $gRetVal
}

get_on_off()
{
    if [ -z "$1" ]; then
        echo "off"
    else
        echo "on"
    fi
}
pline()
{
    $ECHO "#####################################"
}

pblank()
{
    $ECHO ""
}

# prints the result of adding two numbers
add()
{
    expr $1 + $2
}

cp_verbose()
{
    OPTIONS=""
    while echo "$1" | egrep '^-' >/dev/null && [ "$1" != "-" ]; do
        OPTIONS="$OPTIONS $1"
        shift
    done
    $ECHO "Copying from $1 to $2"
    cp $OPTIONS "$@"
}

# returns the opposite exit code of a program. This is a platform independant
# version of the ! operator
not()
{
    "$@" && return 1
    return 0
}

# exits the program if the command fails (like the assert function in C)
or_abort()
{
    "$@" && return 0
    $ECHO "Error: running '$*' failed with exit code $?"
    error `ERR_UNKNOWN`
}

# escape a string so that it can be used in a sed expression (with / as the
# deliminator charactor )
sed_escape()
{
    echo "$1" | sed -e 's/\([][^$\/]\)/\\\1/g'
}

sed_expr_build()
{
    sedfile=$1
    shift
    $ECHO "adding '$@' to $sedfile"
    #$ECHO `sed_escape $@` >> $sedfile
    $ECHO $@ >> $sedfile
}

sed_inline_run()
{
    sedfile=$1
    editfile=$2
    backupfile=${editfile}.$$
    sed -f $sedfile $editfile > $backupfile
    if [ $? -ne 0 ]; then
        error `ERR_FILE_ACCESS`
    fi
    cp_verbose $backupfile $editfile
}
