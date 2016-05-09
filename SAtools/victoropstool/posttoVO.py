#!/bin/env python2.7


import requests
import argparse
import json
import syslog

parser = argparse.ArgumentParser(
                                 description=" seek help. ")
parser.add_argument('--apikey', action='store', dest='apikey', required=True,
                    help="the Victorops API key")
parser.add_argument('--routekey', action='store', dest='routekey', required=True,
                    help="the Victorops routing key")
parser.add_argument('--mtype', action='store', dest='message_type', required=True,
                    help="maps to message_type in the dictionary. Correct values include INFO, WARNING, ACKNOWLEDGEMENT, CRITICAL, RECOVERY")
parser.add_argument('--entityId', action='store', dest='entity_id', required=False,
                    help="maps to entity_id in the dictionary. This is the key to move through alert lifecycle.")
parser.add_argument('-m', action='store', dest='state_message', required=True,
                    help="actual log error or status")
parser.add_argument('--tool', action='store', dest='monitoring_tool', required=False,
                    help="tool generating the alert")
parser.add_argument('--hostname', action='store', dest='hostname', required=False,
                    help="hostname of log")
parser.add_argument('--swatchId', action='store', dest='swatchId', required=False,
                    help="swatch code")
args = vars(parser.parse_args())
opts = parser.parse_args()


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

if __name__ == "__main__":
        try:
            if args['entity_id'] == None:
                args['entity_id'] = "%s::%s" % (opts.hostname, opts.swatchId)
            myjson = json.dumps(args, sort_keys=True, indent=4)
#            print myjson
# uncomment the above line to print json payload to console to validate it is doing what you want.
            myIncident = postToVO()
            thisurl = myIncident.gen_url(opts.apikey, opts.routekey)
            httpResponseText, httpResponseCode = myIncident.post_message(thisurl, myjson)
            jsonResponse = json.loads(httpResponseText)
            mylog = "IGNORE posted to VictorOps for entityId {0} Result was {1} LOG: {2} {3}".format(jsonResponse['entity_id'], jsonResponse['result'],httpResponseCode,opts.state_message) 
            if httpResponseCode == 200:
                syslog.syslog(syslog.LOG_INFO, mylog)
            else:
                syslog.syslog(syslog.LOG_WARNING, mylog)
        except Exception, err:
            error = 'Failed to make a magical unicorn rainbows error was %s ' % (err)
            raise SystemExit(error)
