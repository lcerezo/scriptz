#!/bin/env python2.6
"""
setting the named args to more friendly names
http://docs.splunk.com/Documentation/Splunk/6.0/alert/ConfiguringScriptedAlerts
Inspired by http://victorops.force.com/knowledgebase/articles/Integration/Splunk-Integration
"""


import json
import syslog
import sys
import requests
# this next section could be better suited to a external file.
VOAPIKEY = 'YOURAPIKEY'
ROUTING_KEY = 'splunk'
LEVEL = 'critical'


def gen_url(myapikey, myroutekey):
    """ Generates the url with api key and route key """
    baseurl = 'https://alert.victorops.com/integrations/generic/20131114/alert'
    myurl = '{0}/{1}/{2}'.format(
        baseurl,
        myapikey,
        myroutekey)
    return myurl


def post_message(myurl, payload):
    """ Posts the message with json payload to victorops url endpoint"""
    try:
        response = requests.post(myurl, data=payload)
        return response.text, response.status_code
    except requests.exceptions.ConnectionError, err:
        error = '''connection error, error was\n{0}'''.format(err)
        raise SystemExit(error)
    except Exception, err:
        post_error = '''Error posting to VictorOps {0} \n\nresponse was {1}\n
        HTTP code was {2}\n\n'''.format(
            err,
            response.text,
            response.status_code)
        raise SystemExit(post_error)


def build_json_object(**kwargs):
    """ Builds a json object from key value pairs of unkown length """
    if kwargs is not None:
        my_json = json.dumps(kwargs)
    return my_json


if __name__ == "__main__":
    try:
        THIS_URL = gen_url(VOAPIKEY, ROUTING_KEY)
        MY_PAYLOAD = build_json_object(
            splunkscriptname=sys.argv[0],
            splunkNumberEventsReturned=sys.argv[1],
            splunkSearchTerms=sys.argv[2],
            splunkFullyQualifiedQueryString=sys.argv[3],
            splunkReportName=sys.argv[4],
            splunkTriggerReason=sys.argv[5],
            splunkUrlToReport=sys.argv[6],
            entity_id='''{0}::{1}'''.format(sys.argv[4], sys.argv[5]),
            state_message='''Splunk URL to Report: {} '''.format(sys.argv[5]),
            message_type=LEVEL
            )
        HTTP_RESPONSE_TEXT, HTTP_RESPONSE_CODE = post_message(THIS_URL, MY_PAYLOAD)
        if HTTP_RESPONSE_CODE == 200:
            JSON_RESPONSE = json.loads(HTTP_RESPONSE_TEXT)
            MY_LOG = '''IGNORE PAGED posted to VictorOps for entityId {0}
            Result was {1} HTTP_RESPONSE: {2} '''.format(
                JSON_RESPONSE['entity_id'],
                JSON_RESPONSE['result'],
                HTTP_RESPONSE_CODE)
            syslog.syslog(syslog.LOG_INFO, MY_LOG)
        else:
            MY_NOT_JSON_PAYLOAD = json.dumps(MY_PAYLOAD)
            MY_LOG = '''IGNORE Failed to post to VictorOps for  entityId {0}
            HTTP_RESPONSE_CODE: {1} LOG: {2} HTTP_RESPONSE_TEXT: {3}'''.format(
                MY_NOT_JSON_PAYLOAD['entity_id'],
                HTTP_RESPONSE_CODE,
                MY_NOT_JSON_PAYLOAD['state_message'],
                HTTP_RESPONSE_TEXT)
            syslog.syslog(syslog.LOG_WARNING, MY_LOG)
    except Exception, err:
        MAIN_ERROR = '''Failed to make a magical unicorn rainbows error was {0}'''.format(err)
        raise SystemExit(MAIN_ERROR)
