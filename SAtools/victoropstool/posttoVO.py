#!/bin/env python2.7
""" this posts stuff to victorOps REST API. The doc strings are redundant because of
pylint and pep8.
"""

import argparse
import json
import syslog
import requests

PARSER = argparse.ArgumentParser(description=" seek help. ")
PARSER.add_argument('--apikey', action='store', dest='apikey', required=True,
                    help="the Victorops API key")
PARSER.add_argument('--routekey', action='store', dest='routekey',
                    required=True, help="the Victorops routing key")
PARSER.add_argument('--mtype', action='store', dest='message_type',
                    required=True, help="maps to message_type in the dictionary. \
                            Correct values include. \
                            INFO, WARNING, ACKNOWLEDGEMENT, CRITICAL, RECOVERY")
PARSER.add_argument('--entityId', action='store', dest='entity_id',
                    required=False, help="maps to entity_id in the dictionary. \
                            This is the key to move through alert lifecycle.")
PARSER.add_argument('-m', action='store', dest='state_message', required=True,
                    help="actual log error or status")
PARSER.add_argument('--tool', action='store', dest='monitoring_tool',
                    required=False, help="tool generating the alert")
PARSER.add_argument('--hostname', action='store', dest='hostname',
                    required=False, help="hostname of log")
PARSER.add_argument('--swatchId', action='store', dest='swatchId',
                    required=False, help="swatch code")


def gen_url(myapikey, myroutekey):
    """ Generates the url with api key and route key """
    baseurl = '''https://alert.victorops.com/integrations/generic/20131114/alert'''
    myurl = '''{0}/{1}/{2}/'''.format(baseurl, myapikey, myroutekey)
    return myurl


def post_message(myurl, payload):
    """ Posts the message with json payload to victorops url endpoint"""
    try:
        response = requests.post(myurl, data=payload)
        return response.text, response.status_code
    except requests.exceptions.ConnectionError, err:
        my_vo_error = '''connection error, error was\n{0}'''.format(err)
        raise SystemExit(my_vo_error)
    except Exception, err:
        my_vo_error = '''Error posting to VictorOps {0}
        \n\nresponse was {1}\n HTTP code was {2}\n\n'''.format(
            err,
            response.text,
            response.status_code)
        raise SystemExit(my_vo_error)

if __name__ == "__main__":
    try:
        MY_VO_ARGS = vars(PARSER.parse_args())
        OPTS = PARSER.parse_args()
        if MY_VO_ARGS['entity_id'] is None:
            MY_VO_ARGS['entity_id'] = '''{0}:{1}'''.format(OPTS.hostname, OPTS.swatchId)
        MYJSON = json.dumps(MY_VO_ARGS, sort_keys=True, indent=4)
        # print myjson
        # uncomment the above line to print json payload to console
        # to validate it is doing what you want.
        THIS_URL = gen_url(OPTS.apikey, OPTS.routekey)
        HTTP_RESPONSE_TEXT, HTTP_RESPONSE_CODE = post_message(THIS_URL, MYJSON)
        if HTTP_RESPONSE_CODE == 200:
            JSON_RESPONSE = json.loads(HTTP_RESPONSE_TEXT)
            MY_LOG = '''IGNORE PAGED posted to VictorOps for entityId {0}
            Result was {1} HTTP_RESPONSE: {2} LOG: {3}'''.format(
                JSON_RESPONSE['entity_id'],
                JSON_RESPONSE['result'],
                HTTP_RESPONSE_CODE,
                OPTS.state_message)
            syslog.syslog(syslog.LOG_INFO, MY_LOG)
        else:
            MY_LOG = '''IGNORE Failed to post to VictorOps for  entityId {0}
            HTTP_RESPONSE_CODE: {1} LOG: {2} HTTP_RESPONSE_TEXT: {3}'''.format(
                OPTS.entity_id,
                HTTP_RESPONSE_CODE,
                OPTS.state_message,
                HTTP_RESPONSE_TEXT)
            syslog.syslog(syslog.LOG_WARNING, MY_LOG)
    except Exception, err:
        MAIN_ERROR = '''Failed to make a magical unicorn rainbows error was {0}'''.format(err)
        raise SystemExit(MAIN_ERROR)
