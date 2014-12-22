

import os
import time

myyear = str(int(time.strftime("%Y")))
myday = str(int(time.strftime("%d")))
mymonth = str(int(time.strftime("%m")))
mydate = str(int(time.strftime("%m%d%Y")))
mobdatadir = "./mobdata/"

def mkdirstructure(date):
    mydirtoday = '%s%s/' % (mobdatadir, mydate)
    if not os.path.exists(mydirtoday):
        try:
            for h in range(0, 24):
                myh = format(h, '02')
                myhourdir = mydirtoday + "/" + str(myh) + "00"
                os.makedirs(myhourdir)
        except OSError as exception:
            if exception.errono != errno.EEXIST:
                raise



mkdirstructure("today")



