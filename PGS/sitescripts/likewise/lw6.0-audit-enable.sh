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

$LWPath/lwregshell add_key [HKEY_THIS_MACHINE\\Policy]
$LWPath/lwregshell add_key [HKEY_THIS_MACHINE\\Policy\\Services]
$LWPath/lwregshell add_key [HKEY_THIS_MACHINE\\Policy\\Services\\lsass]
$LWPath/lwregshell add_key [HKEY_THIS_MACHINE\\Policy\\Services\\gpagent]
$LWPath/lwregshell add_key [HKEY_THIS_MACHINE\\Policy\\Services\\eventlog]
$LWPath/lwregshell add_key [HKEY_THIS_MACHINE\\Policy\\Services\\eventfwd]
$LWPath/lwregshell add_key [HKEY_THIS_MACHINE\\Policy\\Services\\lsass\\Parameters]
$LWPath/lwregshell add_key [HKEY_THIS_MACHINE\\Policy\\Services\\lsass\\Parameters\\Providers]
$LWPath/lwregshell add_key [HKEY_THIS_MACHINE\\Policy\\Services\\lsass\\Parameters\\Providers\\ActiveDirectory]
$LWPath/lwregshell add_key [HKEY_THIS_MACHINE\\Policy\\Services\\gpagent\\Parameters]
$LWPath/lwregshell add_key [HKEY_THIS_MACHINE\\Policy\\Services\\eventlog\\Parameters]
$LWPath/lwregshell add_key [HKEY_THIS_MACHINE\\Policy\\Services\\eventfwd\\Parameters]
$LWPath/lwregshell add_value [HKEY_THIS_MACHINE\\Policy\\Services\\lsass\\Parameters\\Providers\\ActiveDirectory] "AssumeDefaultDomain" REG_DWORD 0x00000001
$LWPath/lwregshell add_value [HKEY_THIS_MACHINE\\Policy\\Services\\lsass\\Parameters\\Providers\\ActiveDirectory] "RefreshUserCredentials" REG_DWORD 0x00000000
$LWPath/lwregshell add_value [HKEY_THIS_MACHINE\\Policy\\Services\\lsass\\Parameters\\Providers\\ActiveDirectory] "EnableEventlog" REG_DWORD 0x00000001
$LWPath/lwregshell add_value [HKEY_THIS_MACHINE\\Policy\\Services\\gpagent\\Parameters] "EnableEventlog" REG_DWORD 0x00000001
$LWPath/lwregshell add_value [HKEY_THIS_MACHINE\\Services\\gpagent\\Parameters] "EnableUserPolicies" REG_DWORD 0x00000000
#$LWPath/lwregshell set_value [HKEY_THIS_MACHINE\\Services\\gpagent\\Parameters] "EnableUserPolicies" REG_DWORD 0x00000000  #Add will fail if it doesn't exist.  TODO: check and fix, so we don't spit errors
$LWPath/lwregshell delete_tree [HKEY_THIS_MACHINE\\Services\\gpagent\\GPExtensions\\{74533AFA-5A94-4fa5-9F88-B78667C1C0B5}]
$LWPath/lwregshell add_value [HKEY_THIS_MACHINE\\Policy\\Services\\eventlog\\Parameters] "MaxDiskUsage" REG_DWORD 0x0493e000
$LWPath/lwregshell add_value [HKEY_THIS_MACHINE\\Policy\\Services\\eventlog\\Parameters] "MaxEventLifespan" REG_DWORD 0x0000005a
$LWPath/lwregshell add_value [HKEY_THIS_MACHINE\\Policy\\Services\\eventlog\\Parameters] "RemoveEventsAsNeeded" REG_DWORD 0x00000001
if [ -n "$COLLECTOR_SERVER" ]; then
    $LWPath/lwregshell add_value [HKEY_THIS_MACHINE\\Policy\\Services\\eventfwd\\Parameters] "Collector" REG_SZ "$COLLECTOR_SERVER"
fi
if [ -n "$COLLECTOR_SPN" ]; then
    $LWPath/lwregshell add_value [HKEY_THIS_MACHINE\\Policy\\Services\\eventfwd\\Parameters] "CollectorPrincipal" REG_SZ "$COLLECTOR_SPN"
fi
if [ -n "$ALLOWEDREADGROUP" ]; then
    $LWPath/lwconfig AllowReadTo "$ALLOWEDREADGROUP"
fi

grep -i "syslog-reaper" /etc/syslog.conf
if [ "$?" -eq "1" ]; then
    #// Add these to the syslog.conf
    $ECHO '*.err			/var/lib/likewise/syslog-reaper/error' >> /etc/syslog.conf
    $ECHO '*.warning			/var/lib/likewise/syslog-reaper/warning' >> /etc/syslog.conf
    $ECHO '*.debug			/var/lib/likewise/syslog-reaper/information' >> /etc/syslog.conf
fi


$LWPath/lwregshell set_value [HKEY_THIS_MACHINE\\Services\\eventlog] "Autostart" 0x00000001
$LWPath/lwregshell set_value [HKEY_THIS_MACHINE\\Services\\eventfwd] "Autostart" 0x00000001
$LWPath/lwregshell set_value [HKEY_THIS_MACHINE\\Services\\reapsysl] "Autostart" 0x00000001

$LWPath/lwsm refresh lsass
$LWPath/lwsm start eventlog
$LWPath/lwsm refresh eventlog
$LWPath/lwsm start eventfwd
$LWPath/lwsm start reapsysl
