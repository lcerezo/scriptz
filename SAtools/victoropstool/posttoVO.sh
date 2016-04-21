#!/bin/bash
unset LD_LIBRARY_PATH
mycurl=`which curl`
logmessage=$4
level=$2
hostnameSource=$1
VOAPIKEY=SOMEAPIKEY
ROUTING_KEY=$3
mylogmessage=`sed 's/\"//g;s/\;//g' $logmessage`
$mycurl --data-binary "{\"message_type\":\"$level\",\"monitoring_tool\":\"Swatch\",\"state_message\":\"$mylogmessage\",\"entity_id\":\"$hostnameSource\"}" "https://alert.victorops.com/integrations/generic/20131114/alert/$VOAPIKEY/$ROUTING_KEY" >> /tmp/posttovo.log
