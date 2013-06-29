#!/bin/bash
# For use with main-install.sh ONLY
# expects the following variables
# ECHO=echo -e
# LWPath="$LWPath"
# COLLECTOR_SERVER=""
# COLLECTOR_SPN=""
# source get-ostype.sh
# 2011/02/09 Dean Wills : added code to delete the gconf GPExtension
#
$ECHO "Sleeping for registry to start"
if [ "$OStype" = "solaris" ]; then
    svcadm enable lwsmd
    if [ "$?" -ne "0" ]; then
        $initpath/lwsmd restart
        if [ "$?" -ne "0" ]; then
            $ECHO "ERROR - lwsmd doesn't exist, install probably failed!"
            exit_with_error `ERR_SYSTEM_CALL`
        fi
    fi
else
    $initpath/lwsmd restart
    if [ "$?" -ne "0" ]; then
        $ECHO "Error - lwsmd doesn't exist or can't be restarted."
        $ECHO "ERROR - Install probably failed!!"
        pblank
        exit_with_error `ERR_SYSTEM_CALL`
    fi
fi
status=1

while [ $status -ne 0 ]; do
    $LWPath/lwsm list > /dev/null 2>&1
    status=$?
    sleep 1
done

$LWPath/lwregshell set_value [HKEY_THIS_MACHINE\\Services\\gpagent\\Parameters] "EnableEventlog" 1
$LWPath/lwregshell set_value [HKEY_THIS_MACHINE\\Services\\gpagent\\Parameters] "EnableUserPolicies" 0 
if [ -n "$ALLOWEDREADGROUP" ]; then
    $LWPath/lwconfig AllowReadTo "$ALLOWEDREADGROUP"
fi
$LWPath/lwconfig AssumeDefaultDomain true
$LWPath/lwconfig DomainManagerIgnoreAllTrusts true


$LWPath/lwsm refresh lsass
$LWPath/lwsm refresh eventlog
