#!/usr/bin/env python2.7


import sys, os
from datetime import datetime

now = datetime.now()
today = now.strftime("%m%d%Y")
reportfiles = [ '/prd_reports/REPORTS/PROD/IT/DishTransactions/DISH_Reconciliation/Archived/VIASAT_SB2_' + today + '.csv', '/prd_reports/REPORTS/PROD/IT/DishTransactions/DISH_Reconciliation/Archived/VIASAT_SB1_' + today + '.csv' ]
latehour = 11

def isittimeyet(h):
	if now.hour > h:
		return True
	else:
		return False

def checkfile(f):
	if os.path.isfile(f) and os.path.getsize(f) > 0: 
		return True
	else:
		nagAlert("CRITICAL", "The Report is not there yet, PANIC!")
		return False


def nagAlert(state, extinfo):
        print state, extinfo
        if state.upper() == "CRITICAL":
                sys.exit(2)
        elif state.upper() == "WARNING":
                sys.exit(1)
        else:
                sys.exit(0)

if __name__ == "__main__":
	if isittimeyet(latehour):
		for fn in reportfiles:
			checkfile(fn)
		if len([for fn in reportfiles]) == len(reportfiles):
			nagAlert("OK", "All is well, carryon")
	else:
		print "something wong!"
