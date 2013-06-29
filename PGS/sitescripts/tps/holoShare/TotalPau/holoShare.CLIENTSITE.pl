#!/usr/bin/perl -w
# script to setup tunnels with exxon for sharing holoSeis.
# May 17, 2006	| Initial Creation	| Luis E. Cerezo

$dmzbox = "sshdmz";
$helpurl = "http://pinky.onshore.pgs.com/docs/enduser/HoloShare.html";
$holobin = "/data/holoSeis/Linux64/holoSeis";
$holoroot = "/data/holoSeis/Linux64";
$mpconfig = "/data/holoSeis/Linux64/.mpconfig.Remote";
$clientsite = "TotalPau";
print "This will setup the ssh tunnels and run the proper holoSeis command for sharing.\n Full docs avail at $helpurl.\nOr Please send an email to our servicedesk@pgs.com with the subject holoSeis machine at $clientsite please assign to GIT/SERVER-UNIX\n";
#
print "Please enter \"2\" if you will only need a two-way sharing with PGS, Enter \"3\" if a three-way\t>> ";
$tuntype = <STDIN>;
chomp ($tuntype);

#the final word....
	if ($tuntype !~ /^2$|^3$/)	{	#not sure if this is the most efficent way to match.	
				print "that's not a 3 or a 2. do it again. :-)";
					}
	elsif ($tuntype =~ "3")		{
				getinfo ();
				holoshare3();
					}
	elsif ($tuntype =~ "2")		{
				getinfo ();
				holoshare2();
					}
#the subroutines..
sub getinfo	{
		print "What data would you like to load?\n\nPLEASE NOTE: ALL PARTNERS MUST HAVE THE SAME DATASET!!\n path to data:>>>";
		$dataset = <STDIN>;
		chomp ($dataset);
		print "What Server port would you like to use? >>";
		$serverport = <STDIN>;
		chomp ($serverport);
		}
sub holoshare2	{
		system  "ssh -f -N -R 9993:localhost:$serverport -L 9001:localhost:9991 $dmzbox";
		system "$holobin -root $holoroot -mpcfile $mpconfig -server\:$serverport -client\:localhost\:9001 -nosettings -nosession $dataset";
		}	
sub holoshare3	{
		system "ssh -f -N -R 9993:localhost:$serverport -L 9001:localhost:9991 -L 9002:localhost:9992 sshdmz"; 
		system "$holobin -root $holoroot -mpcfile $mpconfig -server:$serverport -client:localhost:9001 -client:localhost:9002 -nosettings -nosession $dataset\n";

		}
