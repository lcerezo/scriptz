#!/bin/bash

OUTPUT=`cat - | /bin/grep -v LocalExec`;

PREV_OUTPUT=`cat /tmp/cfoutput`;
HOSTNAME=`hostname`;
IP=`hostname -i`;

if [[ $OUTPUT != $PREV_OUTPUT ]]; then

echo $OUTPUT > /tmp/cfoutput

mysql -u cfoutput -D cfengine_output -h pinky.onshore.pgs.com -e "replace into outputs values ('', '$HOSTNAME', '$IP', NOW(), '$OUTPUT')";

fi
