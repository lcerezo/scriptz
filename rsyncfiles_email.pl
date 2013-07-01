#!/usr/bin/perl -w
# This script is to push the Flume Opt Out customer list to the flume aggs out in the core nodes.
# 2013-01-15 
#luis cerezo @ viasat|lec@luiscerezo.org
$lt = localtime;
$target="/home/flumeoptout/OptOutPusher/agglist";
$optoutsDir="/prd_reports/REPORTS/PROD/Compliance/";
$optoutRemoteDir="/usr/lib/flume/optoutlist/";
$logfile = $optoutsDir."err.log";
$errcount = 0;
$mailaddrs = 'mail.user@somwhere.com';
#print "$logfile\n";
open LIST, "$target";
open (LOG, "| tee -a /var/tmp/lasterrlog $logfile >/dev/null");
print LOG "START of error logs for $lt\n";
my @goodFiles = ();
#get list of files in the dir
opendir OPTOUTS, $optoutsDir;
	my @allfiles = readdir OPTOUTS;
closedir OPTOUTS;
foreach (@allfiles) {
		 	next unless (/^Full_URL_Opt_Out_List*.?/);
			push (@goodFiles, $_);
			my $filetopush = $optoutsDir . $_;
			}
while (<LIST>) {
		$AGGhost = $_;
		chomp($AGGhost);
                $FQDN = `host $AGGhost |awk '{print \$5}'`;
		chomp $FQDN;
		foreach (@goodFiles) {
			my $file = $_;
			print "syncing $file in $optoutsDir to $AGGhost \n";
				system("/usr/bin/rsync -Pv $optoutsDir$file $AGGhost:$optoutRemoteDir") == 0
				#print "/usr/bin/rsync $optoutsDir$file $host:$optoutRemoteDir"
				or $errcount ++;
				print LOG "process to $AGGhost ($FQDN) on $file exited with status $? failed transfer count is $errcount \n";
		}
	}

print LOG "END of error logs for $lt\n";
close LOG;

if ($errcount == 0) {
		foreach  (@goodFiles) {
                $file = $_;
		system("/bin/mv $optoutsDir$_ $optoutsDir/Archived/ ");
                $attachArgs .= "-a $optoutsDir" . "Archived/$file "; 
		}
		$subject = "Flume OptOut - $lt - Successful Delivery"
} else  {
		foreach (@goodFiles) {
			$attachArgs .= "-a $optoutsDir/$_";
		}
		$subject = "Flume OptOut - $lt - Failed Delivery"
}

system("/bin/sed -i 's/\$/\t/g' /var/tmp/lasterrlog");
system("/usr/bin/mutt $attachArgs -s \"$subject\" $mailaddrs < /var/tmp/lasterrlog");
system("/bin/rm /var/tmp/lasterrlog");

