#!/usr/bin/env python26
recipients = "wbint-prodsupportsystems@viasat.com, atgsupport@viasat.com,IT-RFC@viasat.com"
sender = "wbint-prodsupportsystems@viasat.com"
# Name of s3 bucket in the cloud
bucket_name = 'optout'
reportsdir = '/prd_reports/REPORTS/PROD/Compliance/'
#
#Imports
import os
import sys
import time
import boto
import boto.s3
from boto.s3.key import Key
hoy = str(int(time.strftime("%Y%m%d")) -1)

def pushToS3(sdir, filetopush):
    global flumelog
    pushfile = sdir + filetopush
# Connect over the proxy in WDC1 using the AWS keys defined in ~/.boto
    conn = boto.connect_s3(proxy='75.104.236.133',proxy_port='3128',debug=1)
#connect to the bucket.
    bucket = conn.get_bucket(bucket_name)
    k = Key(bucket)
    k.key = filetopush
    k.set_contents_from_filename(pushfile, encrypt_key=True)
    flumelog += 'Uploading %s to Amamzon s3 bucket %s' % (filetopush, bucket_name)
    print 'Uploading %s to Amamzon s3 bucket %s' % (filetopush, bucket_name)

# stolen from internet. not really needed.
def percent_cb(complete, total):
	sys.stdout.write('#')
	sys.stdout.flush()
#gets a list of files that match. should always be len of one, but in case this goes further, I'd like to be ready.
def getfiles(gdir, date):
    fl = []
    for file in os.listdir(gdir):
        if file.endswith(date + '.csv'):
            print(gdir + file)
            fl.append(file)
    return fl

##THe Mail portion of all this silliness
##
import smtplib
from email.mime.text import MIMEText
def mailresults(fwho, twho, runresults, longmsgstatus):
    msg = MIMEText(longmsgstatus)
    msg['Subject'] = '[ALMOSTPRODUCTION] Flume Optout S3 delivery to bucketname: %s, status: %s' % (bucket_name, runresults)
    msg['From'] = fwho
    msg['To'] = twho
    s = smtplib.SMTP('localhost')
    s.sendmail(fwho, twho, msg.as_string())
    s.quit()
# magical unicorn poo.
if __name__ == "__main__":
    flumestatus = " had  "
    files = getfiles(reportsdir, hoy)
    global flumelog
    flumelog = ""
    try:
        if len(files) == 0:
            flumelog += 'Failed to push : file list len is 0: no files found to push'
            flumestatus = 'could not find files: list found contains %s ' % (ifiles)
            mailresults(sender, recipients, flumestatus, flumelog)
        for optout in files:
            pushToS3(reportsdir, optout)
            flumestatus += "succeeded"
            flumelog += 'Successfully pushed %s' % (files)
            mailresults(sender, recipients, flumestatus, flumelog)
    except Exception, err:
        flumestatus += "failed "
        flumelog += 'Failed to push %s with error %s ' % (files, str(err))
        mailresults(sender, recipients, flumestatus, flumelog)
            
