#!/usr/bin/perl -w
# script to setup tunnels with exxon for sharing holoSeis.
# May 17, 2006	| Initial Creation	| Luis E. Cerezo
# Apr 28, 2008  | altered holoSeis version to 9.40.19 and removed -nospacemouse | Chris Taylor
# Apr 29, 2008  | changed to .mpconfig.remote.1920x1200 | Chris Taylor

$dmzbox = "192.168.250.29";
$dmzuser = "cairnUK";
$helpurl = "http://pinky.onshore.pgs.com/wiki/index.php/CairnUK";
$clientsite = "CairnUK";
$systype = `uname -p`;
$holobinFile = "holoSeis.Linux64-00:1F:29:05:F3:42-10.63.8";
chomp ($systype);

	if ($systype !~ /x86_64/)	{
					print "system arch not recognized. This version of holoSeis only runs on x86_64 for Linux.  You are running $systype.\n";
					exit;
					}
	elsif ($systype =~ "x86_64")	{
					$holobin = "/tps/holoSeis/Linux64/$holobinFile";
					$holoroot = "/tps/holoSeis/Linux64";
					$mpconfig = "/tps/holoSeis/Linux64/.mpconfig.remote.1920x1200";
					}
print "This will setup the ssh tunnels and run the proper holoSeis command for sharing.\n Full docs avail at $helpurl.\n\nPlease enter \"2\" if you will only need a two-way sharing with $clientsite, Enter \"3\" if a three-way\t>> ";
$tuntype = <STDIN>;
chomp ($tuntype);

#the final word....
	if ($tuntype !~ /^2$|^3$/)	{	#not sure if this is the most efficent way to match.	
				print "that's not a 3 or a 2. do it again. :-)";
					}
	elsif ($tuntype =~ "3")		{
				getinfo ();
				getpgspartner();
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
sub makekeys	{
		open SSHKEY, ">/tmp/key";
		print SSHKEY "";
		}
sub holoshare2	{
		system  "ssh -f -N -R 11221:localhost:$serverport -l $dmzuser $dmzbox";
		system  "ssh -f -N -L 9003:localhost:11200 -l $dmzuser $dmzbox";
		system "$holobin -root $holoroot  -mpcfile $mpconfig -server\:$serverport -client\:localhost\:9003 -nosettings -nosession $dataset";
		}	
sub holoshare3	{
		system "$holobin -root $holoroot  -mpcfile $mpconfig -server:$serverport -client:$pgspart:$pgspartport -client:localhost:9003 -nosettings $dataset\n";
		}	
sub getpgspartner
		{
		print "what is the fully qualified hostname or IP address of the INSIDE PGS partner?>>";
		$pgspart = <STDIN>;
		chomp ($pgspart);
		print "what is the port number they will use for thier server?>>";
		$pgspartport = <STDIN>;
		chomp ($pgspartport);
		print "You will have to decide which partner you want to be. You can be wallace or grommit.\n You must agree on this with the other pgs partner, and you cannot be the same.\n";
		print "Will you be Wallace or Grommit?>> ";
		$whoami = <STDIN>;
		chomp ($whoami);
			if ($whoami !~ /(?i)wallace|grommit/)	{
								print "you must select wallace or grommit.\n";
								exit;
								}
			elsif ($whoami =~ /(?i)wallace/)		{
								print "you will be Wallace. Enjoy the cheese\n";
								$remoteport = "11221";
								}
			elsif ($whoami =~ /(?i)grommit/)		{
								print "you will be Grommit. Make sure Wallace does not get into trouble again.\n";
								$remoteport = "9992";
								}
		system "ssh -f -N -R $remoteport:localhost:$serverport -L 9003\:localhost\:11200 -l $dmzuser $dmzbox";
		}
