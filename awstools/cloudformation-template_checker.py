#!/usr/bin/env python
# parse json cloudformation template and create or update stack
# aws keys are stored in .boto or .aws/credentials,
# see https://boto3.readthedocs.org/en/latest/index.html
# Luis E. Cerezo
"""
This id for ops to generate a file with the cloudformation template
and validate it.
"""

import argparse
import json
import os
from string import Template
try:
    import boto3
except ImportError:
    print "##ERROR##\nboto not installed. please install boto. eg pip install boto\n\n"

parser = argparse.ArgumentParser(
                    description=" seek help. \n -s stackpolicy -e env -p stackname ")
parser.add_argument('-e', action='store', dest='awsEnv', required=True,
                    help="Environment to tag and name the stack. PROD|PAT|ENV etc.")
parser.add_argument('-p', action='store', dest='stackname', required=True,
                    help="Name of the stack.")
parser.add_argument('-s', action='store', dest='stackpolicy', required=True,
                    help="Name of the stack policy file")
parser.add_argument('-r', action='store', dest='release', required=True,
                    help="deployment release number will store in Tags")
parser.add_argument("--nodryrun", action="store_true",
                    help="print what will be done, do not act")
args = vars(parser.parse_args())
opts = parser.parse_args()


def loadpolicyfromfile(json_stack_template, myreplacedatadict):
    try:
        with open(json_stack_template, "r") as myfile:
            outjson = Template(myfile.read())
            for k, v in myreplacedatadict.iteritems():
                    if type(v) is list:
                        myreplacedatadict[k] = json.dumps(v)
            j = outjson.safe_substitute(myreplacedatadict)
        myfile.close()
    except Exception, err:
        print 'ERROR %s' % (err)
    return j


def validateTemplate(stack_template):
    client = boto3.client('cloudformation')
    response = client.validate_template(TemplateBody=stack_template)
    return response

# need to load file into object.
if __name__ == "__main__":
    try:
        t = loadpolicyfromfile(args['stackpolicy'], args)
        diditwork = validateTemplate(t)
        templateName = '%s_%s_%s_.json' % (opts.stackname, opts.awsEnv, opts.release)
        with open(templateName, "w") as outfile:
            outfile.write(t)
            outfile.close()
        print str(diditwork['ResponseMetadata']['HTTPStatusCode']) + " " + str(diditwork['Parameters'])
        print "wrote " + templateName
        if opts.nodryrun:
            print "gonna actually run it"
        else:
            print "Dry run, not executing"
    except Exception, err:
        print 'Failed to do aws magical unicorn rainbows error was %s ' % (err)
