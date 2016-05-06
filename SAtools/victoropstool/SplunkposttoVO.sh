#!/bin/bash
# http://docs.splunk.com/Documentation/Splunk/6.0/alert/ConfiguringScriptedAlerts
# inspired by http://victorops.force.com/knowledgebase/articles/Integration/Splunk-Integration
unset LD_LIBRARY_PATH
mycurl=`which curl`
VOAPIKEY='YOURAPIKEY'
ROUTING_KEY=splunk
level='critical'
splunkscriptname=$0
splunkNumberEventsReturned=$1
splunkSearchTerms=$2
splunkFullyQualifiedQueryString=$3
splunkReportName=$4
splunkTriggerReason=$5
splunkUrlToReport=$6
$mycurl -s --data-binary "{\"message_type\":\"$level\",\"monitoring_tool\":\"Splunk\",\"state_message\":\"Splunk Alert: $splunkReportName View report:$splunkUrlToReport\",\"entity_id\":\"$splunkReportName:$splunkTriggerReason\", \"hostname\":\"$(hostname)\"}" "https://alert.victorops.com/integrations/generic/20131114/alert/$VOAPIKEY/$ROUTING_KEY" >> /tmp/posttovo.log
