#!/usr/bin/env python2.7
"""
Date: Aug 5 2014
Author: Luis E. Cerezo 
This checks existence of report files for a nagios check. It takes a list (array) reportfiles, checks that they exist, and are not 0 length. If all is well, nrpe return 0. else, PANIC! HUNKER DOWN! RUN FOR THE FLIPPING HILLS!
The somewhat latest version of this script can be found in T4sys svn repository http://10.65.0.69/svn/repo/T4Sys/scripts/ or at @lcerezo github thingie. 
"""

__version__ = "$Revision: 0.10 $"

import sys, os
from datetime import datetime

now = datetime.now()
today = now.strftime("%m%d%Y")
reportfiles = [ '/prd_reports/REPORTS/PROD/IT/DishTransactions/DISH_Reconciliation/Archived/VIASAT_SB2_' + today + '.csv', '/prd_reports/REPORTS/PROD/IT/DishTransactions/DISH_Reconciliation/Archived/VIASAT_SB1_' + today + '.csv' ]
# this is the hour that is considered late, in UTC
latehour = 9
errormsg = "The current time is " + str(now) + " and the report is not yet there"

#simple function to check if it is time yet.
def isittimeyet(h):
	if now.hour > h:
		return True
	else:
		return False
#is the file there and does it have some content?
def checkfile(f):
	if os.path.isfile(f) and os.path.getsize(f) > 0: 
		return True
	else:
		return False

#funciton for yelling at nagios err.. nrpe.
def nagAlert(state, extinfo):
        print state, extinfo
        if state.upper() == "CRITICAL":
                sys.exit(2)
        elif state.upper() == "WARNING":
                sys.exit(1)
        else:
                sys.exit(0)

"""The main shit goes here. Magic ju-ju pooping unicorns live beyond here. 
"""
if __name__ == "__main__":
    if isittimeyet(latehour):
        happycount = 0
        for fn in reportfiles:
            if checkfile(fn):
               happycount += 1
            else: errormsg += "\n missing " + fn
    if happycount == len(reportfiles):
        nagAlert("OK", "All is well, carryon")
    else:
        nagAlert("CRITICAL", errormsg)

else:
    print "something wong!"
