#!/bin/env python27


import requests
import argparse
import json
parser = argparse.ArgumentParser(
                            description=" seek help. ")
parser.add_argument('--apikey', action='store', dest='apikey', required=True,
                            help="the Victorops API key")
parser.add_argument('--routekey', action='store', dest='routekey', required=True,
                            help="the Victorops routing key")
parser.add_argument('--mtype', action='store', dest='message_type', required=True,
                            help="maps to message_type in the dictionary. Correct values include INFO, WARNING, ACKNOWLEDGEMENT, CRITICAL, RECOVERY")
parser.add_argument('--entityId', action='store', dest='entity_id', required=True,
                            help="maps to entity_id in the dictionary this is the key to move through alert lifecycle.")
parser.add_argument('-m', action='store', dest='state_message', required=True,
                            help="actual log error or status")
parser.add_argument('--tool', action='store', dest='monitoring_tool', required=False,
                            help="tool generating the alert")
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
        except PostError, err:
            print 'Error posting to Victoops %s \n\nresponse was %s\n HTTP code was %s\n\n' % (err, response.text, response.status_code)
        else:
             return response.text, response.status_code
    
if __name__ == "__main__":
        try:
            myjson = json.dumps(args)
            print myjson
            myIncident = postToVO()
            thisurl = myIncident.gen_url(opts.apikey, opts.routekey)
            rt, rsc = myIncident.post_message(thisurl, myjson)
            if rsc != 200:
                print 'ERROR : %s %s ' % (rt, rsc)
            else:
                print rt
        except Exception, err:
            print 'Failed to make a magical unicorn rainbows error was %s ' % (err)