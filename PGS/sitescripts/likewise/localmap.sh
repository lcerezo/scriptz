#!/bin/bash
#  process command line options

errordelay=2
helptext="
$0 - (C) 2010 Likewise Software

This script reads users from /etc/passwd and groups from /etc/group, looks them up
in Active Directory via Likewise commands, and creates map files for use by
chown-all-files.pl

at least a passwd output file or a group output file is required, both is preferred.

Options:

-p <file> = passwd map to write
     path to a file which will be then used as input to chown-all-files.pl -p

-g <file> = group map to write
    path to a file which will be then used as input to chown-all-files.pl -g

-? = this help text

"

while getopts ":p:g:?" optn; do
    case $optn in
    p ) passwdmap=$OPTARG
        echo Password Map Output will be $passwdmap
        ;;
    g ) groupmap=$OPTARG
        echo Group Map Output will be $groupmap
        ;;
    \? ) printf "$helptext"
        sleep $errordelay
        exit 1
        ;;
    esac
done

if [ -z "$passwdmap" ] && [ -z "$groupmap" ]; then
        printf "$helptext"
        sleep $errordelay
        exit 1
fi

if [ -n "$passwdmap" ]; then
    echo "oldid	newid	oldname	newname" > $passwdmap
    for i in `awk -F: '{ print $1 }' /etc/passwd`; do 
        data=`/opt/likewise/bin/lw-find-user-by-name $i`
        if [ $? -eq 0 ]; then
            oldid=`awk -F: "/$i/ { print \\$3 }" /etc/passwd`
            newid=`/opt/likewise/bin/lw-find-user-by-name $i | awk '/Uid:/ { print $2 }'`
            if [ $oldid -ne $newid ]; then
                echo "$oldid	$newid	$i	$i" >> $passwdmap
            fi
        fi
    done;
    lines=`wc -l $passwdmap |awk '{ print $1 }'`
    if [ $lines -eq 1 ]; then
        rm $passwdmap
        passwdmap=""
    else
        passwdmap="-u $passwdmap"
    fi
fi

if [ -n "$groupmap" ]; then
    echo "oldid	newid	oldname	newname" > $groupmap
    for i in `awk -F: '{ print $1 }' /etc/group`; do 
        data=`/opt/likewise/bin/lw-find-group-by-name $i`
        if [ $? -eq 0 ]; then
            oldid=`awk -F: "/$i/ { print \\$3 }" /etc/group`
            newid=`/opt/likewise/bin/lw-find-group-by-name $i | awk '/Gid:/ { print $2 }'`
            if [ $oldid -ne $newid ]; then
                echo "$oldid	$newid	$i	$i" >> $groupmap
            fi
        fi
    done;
    lines=`wc -l $groupmap |awk '{ print $1 }'`
    if [ "$lines" -eq "1" ]; then
        rm $groupmap
        groupmap=""
    else
        groupmap="-g $groupmap"
    fi
fi

echo "./chown-all-files.pl $passwdmap $groupmap -v warning"
