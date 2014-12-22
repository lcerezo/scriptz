#!/usr/bin/env python

# This just reads the outout of an xml check from tomcat. (Greg Hightshoe)
# Author: Luis E. Cerezo

import sys
import urllib2
import xml.etree.ElementTree as ET

#global vars go here
appurl = 'http://tcapi01.dev.wdc1.wildblue.net:8080/AAABridge/aaaBridge'

def geturl(url):
    ''' Read url xml output into an object that ET can read'''
    try:
       usock = urllib2.urlopen(url)
    except urllib2.HTTPError, e:
        nagAlert("CRITICAL", e)
    except urllib2.URLError, e:
        nagAlert("CRITICAL", e)
    return usock


def getExtinfo():
	status = ""
	for n in range(3):
		nM = root[n][0].text
		st = root[n][1].text
		status +=  "App" + nM + ":" + st + " "
	return status


#def checkxmlstatus(xmlf):
#	'''parse and check output of the xml aaabridge check'''
#        tree = ET.parse(xmlf)
#        root = tree.getroot()
#        t = root.attrib
#	exTinfo = getExtinfo()
#        if t['applicationCheckStatus'] == 'PASS':
#                nagAlert("OK", exTinfo)
#        else:
#                nagAlert("Critical", exTinfo)
#
def nagAlert(state, extinfo):
	print state, extinfo
	if state.lower() == "critical":
		sys.exit(2)
	elif state.lower() == "warning":
                sys.exit(1)
	else:
                sys.exit(0)

if __name__ == "__main__":
	xstat = geturl(appurl)
	tree = ET.parse(xstat)
        root = tree.getroot()
        t = root.attrib
        exTinfo = getExtinfo()
        if t['applicationCheckStatus'] == 'PASS':
                nagAlert("OK", exTinfo)
        else:
                nagAlert("Critical", exTinfo)

