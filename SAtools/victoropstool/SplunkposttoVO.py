#!/bin/env python2.6


import requests
import json
import syslog
import sys
# this next section could be better suited to a external file.
VOAPIKEY = 'YOURAPIKEY'
ROUTING_KEY = 'splunk'
level = 'critical'
# setting the named args to more friendly names
# http://docs.splunk.com/Documentation/Splunk/6.0/alert/ConfiguringScriptedAlerts
# inspired by http://victorops.force.com/knowledgebase/articles/Integration/Splunk-Integration


class postToVO(object):

    def gen_url(self, myapikey, myroutekey):
        baseurl = 'https://alert.victorops.com/integrations/generic/20131114/alert'
        myurl = '%s/%s/%s' % (baseurl, myapikey, myroutekey)
        return myurl

    def post_message(self, myurl, payload):
        try:
            response = requests.post(myurl, data=payload)
            return response.text, response.status_code
        except requests.exceptions.ConnectionError, err:
            error = "connection error, error was\n{0}".format(err)
            raise SystemExit(error)
        except Exception, err:
            error = 'Error posting to VictorOps %s \n\nresponse was %s\n HTTP code was %s\n\n' % (err, response.text, response.status_code)
            raise SystemExit(error)

    def build_json_object(self, **kwargs):
        if kwargs is not None:
            myjson = json.dumps(kwargs)
        return myjson

if __name__ == "__main__":
    try:
        myIncident = postToVO()
        thisurl = myIncident.gen_url(VOAPIKEY, ROUTING_KEY)
        myPayload = myIncident.build_json_object(
                splunkscriptname=sys.argv[0],
                splunkNumberEventsReturned=sys.argv[1],
                splunkSearchTerms=sys.argv[2],
                splunkFullyQualifiedQueryString=sys.argv[3],
                splunkReportName=sys.argv[4],
                splunkTriggerReason=sys.argv[5],
                splunkUrlToReport=sys.argv[6],
                entity_id="{0}::{1}".format(sys.argv[4], sys.argv[5]),
                state_message="Splunk URL to Report: {} ".format(sys.argv[5]),
                message_type=level
                )
        httpResponseText, httpResponseCode = myIncident.post_message(thisurl, myjson)
        if httpResponseCode == 200:
            jsonResponse = json.loads(httpResponseText)
            mylog = "IGNORE PAGED posted to VictorOps for entityId {0} Result was {1} HTTP_RESPONSE: {2} ".format(jsonResponse['entity_id'], jsonResponse['result'], httpResponseCode)
            syslog.syslog(syslog.LOG_INFO, mylog)
        else:
            mylog = "IGNORE Failed to post to VictorOps for  entityId {0} HTTP_RESPONSE_CODE: {1} LOG: {2} HTTP_RESPONSE_TEXT: {3}".format(opts.entity_id, httpResponseCode, opts.state_message, httpResponseText)
            syslog.syslog(syslog.LOG_WARNING, mylog)
        except Exception, err:
            error = 'Failed to make a magical unicorn rainbows error was %s ' % (err)
            raise SystemExit(error)
