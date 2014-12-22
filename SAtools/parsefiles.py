

import os
import re
import time
import fnmatch
mobdatadir = '/mobdata'

'''This is to take the inbound files from the gateways and sort them based on date, parsed from the filename. The latest version of this file can be found https://git.viasat.com/exededcinfra/sharedScripts/tree/master/mobftp or contact luis cerezo @luiscerezo'''



#build list of files found in the data dir to parse
def getacufilelist(datadir, pattern):
    mobaculist = []
    for mobfile in os.listdir(datadir):
        if fnmatch.fnmatch(mobfile, pattern):
            mobaculist.append(mobfile)
    return mobaculist
#this processes file of the acuism name format
def processacufiles(acufilelist):
    for acufile in acufilelist:
        acu, mymac, unixtime  = re.split('-', acufile)
        myepochtime, tar = re.split('.tar.gz', unixtime)
#converts unixtime to a tuple where I can make dirs of more human friendly names
        myyear, mymon, myday, myhour, mymin, mysec, mywday, myyday, myisd = time.gmtime(int(myepochtime))
#pads numbers    
        mydateformat = "%s%s%s" % (format(mymon, '02'), format(myday, '02'), myyear)
#####make the hours look like 0300 or 2300
        mytfhdayformat = format(myhour, '02') + "00" 
        filetargetdir = "%s/%s/%s/%s" % (mobdatadir, mydateformat, mytfhdayformat, mymac)
        if os.path.exists(filetargetdir):
            try:
                mysrcfn = "%s/%s" % (mobdatadir, acufile)
                mytrgtfn = "%s/%s" % (filetargetdir, acufile)
                os.rename(mysrcfn, mytrgtfn)
                #print mysrcfn + " " + mytrgtfn
            except OSError as exception:
                    raise
        else:
            try:
                os.makedirs(filetargetdir)
                #print filetargetdir
                mysrcfn = "%s/%s" % (mobdatadir, acufile)
                mytrgtfn = "%s/%s" % (filetargetdir, acufile)
                os.rename(mysrcfn, mytrgtfn)
                #print mysrcfn + " " + mytrgtfn
            except OSError as exception:
                    raise

def processutfiles(utfilelist):
    for utfile in utfilelist:
        u, c, mydate, myfullmac = re.split("_", utfile)
        myfullutmacaddr, tar = re.split('.tar.gz', myfullmac)
        mymacvender, mymac = re.split('00A0BC', myfullutmacaddr)
        myyear, mymon, myday, myhour, mymin, mysec, mywday, myyday, myisd = time.strptime(mydate, "%Y-%m-%dT%H%M%S")
        mydateformat = "%s%s%s" % (format(mymon, '02'), format(myday, '02'), myyear)
#####make the hours look like 0300 or 2300
        mytfhdayformat = format(myhour, '02') + "00" 
        filetargetdir = "%s/%s/%s/%s" % (mobdatadir, mydateformat, mytfhdayformat, mymac)
        if os.path.exists(filetargetdir):
            try:
                mysrcfn = "%s/%s" % (mobdatadir, utfile)
                mytrgtfn = "%s/%s" % (filetargetdir, utfile)
                os.rename(mysrcfn, mytrgtfn)
                #print mysrcfn + " " + mytrgtfn
            except OSError as exception:
                    raise
        else:
            try:
                os.makedirs(filetargetdir)
                #print filetargetdir
                mysrcfn = "%s/%s" % (mobdatadir, utfile)
                mytrgtfn = "%s/%s" % (filetargetdir, utfile)
                os.rename(mysrcfn, mytrgtfn)
                #print mysrcfn + " " + mytrgtfn
            except OSError as exception:
                    raise

# magical unicorn poo.
if __name__ == "__main__":
    mypatterns = ['acuism-*.tar.gz', 'utstat-*.tar.gz', 'ut_*.tar.gz']
    mypats = 'acuism-*.tar.gz'
    myaculist = getacufilelist(mobdatadir, 'acuism-*tar.gz')
    myutstatlist = getacufilelist(mobdatadir, 'utstat-*tar.gz')
    myutdatalist = getacufilelist(mobdatadir, 'ut_*.tar.gz')
    #processutfiles(myaculist)
    if len(myaculist) != 0:
        processacufiles(myaculist)
    if len(myutstatlist) != 0:
        processacufiles(myutstatlist)
    if len(myutdatalist) != 0:
        processutfiles(myutdatalist)
