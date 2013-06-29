#!/usr/bin/env perl
# Copyright 2008 Likewise Software
# by Robert Auch
# find and chown files in a filesystem based on input "old info\tnew info" format
#
# v0.1 2011-07-16 RCA - Restore from chown-all-files by reading same map, logfile, undoing the chown.
#
# these should only be uncommented during development - breaks Solaris 8 usage
use strict;
use warnings;

use Getopt::Long;
use File::Basename;
#use File::stat;
#use Fcntl ':mode';
use File::Find;
use Carp;
use FindBin;
use lib "$FindBin::Bin/perllib";
#use File::Find 1.15;    # this is a copy of File::Find 1.15 from CPAN with "use warnings" commented out
use LwDeploy 1.6;
my $gVer="0.1";
my $gDebug=0;  #the system-wide log level. Off by default, changable by switch --loglevel

my $gRetval=0; #used to determine exit status of program with bitmasks below:
sub ERR_UNKNOWN ()      { 1; }
sub ERR_OPTIONS ()      { 2; }
sub ERR_OS_INFO ()      { 2; }
sub ERR_ACCESS  ()      { 4; }
sub ERR_FILE_ACCESS ()  { 4; }
sub ERR_SYSTEM_CALL ()  { 8; }
sub ERR_DATA_INPUT  ()  { 16; }
sub ERR_LDAP        ()  { 32; }
sub ERR_NETWORK ()      { 64; }
sub ERR_CHOWN   ()      { 256; }
sub ERR_STAT    ()      { 512; }
sub ERR_MAP     ()      { 1024; }

#These have to be defined globally for the "File::Find"'s "wanted" function (chownfiles()) to work
my ($gUsermap, $gGroupmap, $output, $gOpt, $gSkiplist, $gDryrun, @gExclude);
@gExclude=('^/proc$', '^/dev$');

sub main();
main();
exit $gRetval;

# Helper programs start here

sub usage()
{
    my $scriptName = fileparse($0);

    my $statement="
$scriptName version $gVer
(C)2009, Likewise Software

usage: $scriptName [options]

  This script reads in a tab-separated mapping file of 'oldid/newid' combos
  and finds files on the filesystem matching the 'oldid' and chowns them to 
  'newid'.

  That mapping file needs the fields (order not important):
  oldid\tnewid\toldname\tnewname
    If the group name isn't changing, do not include the newname column

  Options:

    --userfile, -u FILENAME - name of mapping file.
         oldid\tnewid\toldname\tnewname
        (default = ".&getOnOff($gOpt->{userfile}).")

    --groupfile, -g FILENAME - name of group mapping file.
         oldid\tnewid\toldname\tnewname
        (default = ".&getOnOff($gOpt->{groupfile}).")

    --log, --logfile, -l FILENAME - name of log file to write.
        (default = ".&getOnOff($gOpt->{logfile}).")

    --loglevel -v {error|warning|info} - verbosity of logging
        (default = ".&getOnOff($gOpt->{loglevel}).")

    --(no)dryrun -d - Do all logging and processing, but don't
         actually 'chown' the files.
        (default = ".&getOnOff($gOpt->{dryrun}).")

    --input -i - Input file to read (logfile from previous chown-all-files.pl)
        (default = ".&getOnOff($gOpt->{inputfile}).")

  Examples:

    $scriptName -u usermap.tab -l /tmp/restoredfiles.log -i /tmp/changedfiles.log
";
    return $statement;
}

# workhorse subs start here

sub buildMap($$) {
	my $maptype = shift;
	my $filename = shift;
    if (not defined($maptype)) {
        LogError("No map type given!!", $gDebug, $output);
        $gRetval |= ERR_MAP;
        exit $gRetval;
    } elsif (not defined ($filename)) {
        LogError("No Filename given for $maptype map!", $gDebug, $output);
        $gRetval |= ERR_MAP;
        $gRetval |= ERR_OPTIONS;
        exit $gRetval;
    }
	LogVerbose("Reading $maptype map from $filename", $gDebug, $output);
	my $map=ParseTable($filename);
	LogVerbose("Successfully read $maptype map from $filename.", $gDebug, $output);
	unless (defined($map->{oldid}) && defined($map->{newid}) && defined($map->{oldname}) ) {
		LogError("Missing an expected column name in $filename\n".usage(), $gDebug, $output);
        $gRetval |= ERR_MAP;
        exit $gRetval;
	} else {
		LogVerbose("$maptype map correctly contains 'oldid', 'newid', 'oldname' columns.", $gDebug, $output);
	}
	unless (defined($map->{newname})) {
		LogVerbose("Mapping 'oldname' to 'newname' because 'newname' wasn't defined in $filename", $gDebug, $output);
		push(@{$map->{_fieldNames}}, "newname");
		$map->{newname}=$map->{oldname};
		foreach my $entry (keys(%{$map->{oldname}})) {
			$map->{newname}->{$entry} = $map->{oldname}->{$entry};
		}
	}
	LogVerbose("Successfully built $maptype map.", $gDebug, $output);
	return $map;
}


sub fixfiles() {
	
    open(FILE, "<$gOpt->{input}") || die "Can't open $gOpt->{input} - $!";
    while (<FILE>) {
        my $line=$_;
        my $chuid="";
        my $chgid="";
        chomp $line;
        if ($line=~/Change:/i) {

            $line=~/Change:\s+(.+)\s+uid (now|still) (\d+), gid (now|still) (\d+)/;
            my ($file, $uidstatus, $ouid, $gidstatus, $ogid) = ($1, $2, $3, $4, $5);
        	if ($uidstatus eq "now") {
        	    $chuid=$gUsermap->{newid}->{$ouid}->{oldid};
        	}
        	if ($gidstatus eq "now") {
        	    $chgid=$gUsermap->{newid}->{$ogid}->{oldid};
        	}
    	    my $error=0;
    #        my @info = lstat($file);
    #        if ($#info<1) {
    #	       LogWarning("Couldn't stat $file!", $gDebug, $output);
    #            $gRetval |= ERR_STAT;
    #    		return;
    #    	}
    #        my $uid=$info[4];
    #        my $gid=$info[5];
    #        my $islink= (-l _) ? 1: 0;
            my $islink=0;
    #        LogDebug("File $file is a symlink", $gDebug, $output) if $islink;
    #        LogVerbose("Read: $file, uid=$uid, gid=$gid", $gDebug, $output);
    #        if ($uid==0 && $gid==0) {
    #            LogVerbose("    Ignore: $file uid=0, gid=0", $gDebug, $output);
    #            return;
    #        }
            if ($ouid==0 && $ogid==0) {
                LogVerbose("    Ignore: $file uid=0, gid=0", $gDebug, $output);
                return;
            }
        
            # Set lower error level for chowns if file is a symbolic link;
        	if ($chuid && not($ouid==0)) {
        		if ($chgid && not($ogid==0)) {
        			LogWarning("    Restore: $file uid now $chuid, gid now $chgid", $gDebug, $output);
        			unless ($gDryrun) {
        				$error=chown($chuid, $chgid, $file);
        				if ($islink and $error) {
                            LogWarning("Failed to Restore link $file uid and gid: $chuid; $chgid", $gDebug, $output);
                            $gRetval |= ERR_CHOWN;
                        } elsif ($error) {
                            LogError("Failed to Restore $file uid and gid: $chuid; $chgid", $gDebug, $output);
                            $gRetval |= ERR_CHOWN;
                        }
        			}
        		} else {
        			LogWarning("    Restore: $file uid now $chuid, gid still $ogid", $gDebug, $output);
        			unless ($gDryrun) {
        				$error=chown($chuid, $ogid, $file);
                        if ($islink and $error) {
        				    LogWarning("Failed to restore link $file uid: $chuid ", $gDebug, $output);
                            $gRetval |= ERR_CHOWN;
                        } elsif ($error) {
        				    LogError("Failed to restore $file uid: $chuid ", $gDebug, $output);
                            $gRetval |= ERR_CHOWN;
                        }
        			}
        		}
        	} elsif ($chgid) {
        		LogWarning("    Restore: $file uid still $ouid, gid now $chgid", $gDebug, $output);
        		unless ($gDryrun) {
        			$error=chown($ouid, $chgid, $file);
                    if($islink and $error) {
            			LogWarning("Failed to restore link $file gid: $chgid ", $gDebug, $output);
                        $gRetval |= ERR_CHOWN;
                    } elsif ($error) {
            			LogError("Failed to restore $file gid: $chgid ", $gDebug, $output);
                        $gRetval |= ERR_CHOWN;
                    }
        		}
        	} else {
        		LogInfo("    Ignore: $file uid $ouid and gid $ogid not found in maps", $gDebug, $output);
        	}
            $_=$file;
        }
    }
}

sub main()
{

        Getopt::Long::Configure('no_ignore_case', 'no_auto_abbrev') || confess;

        $gOpt = {
            rootdir => '/',
            loglevel => 'info',
            nfs => 0,
            logfile => '-',
            userfile => '',
            groupfile => '',
            input => '',
        };
        my $ok = GetOptions($gOpt,
            'help|h|?',
            'userfile|u=s',
            'groupfile|g=s',
            'logfile|log|l=s',
			'rootdir|root|r=s',
			'loglevel|v=s',
            'exclude|exclude-from|e=s',
			'invert|i!',
			'dryrun|d!',
            'nfs|autofs|n!',
            'input|inputfile|i=s',
                       );
        my $more = shift @ARGV;
        my $errors;

        if ($gOpt->{help} or not $ok) {
                $gRetval |= ERR_OPTIONS;
                print usage()
        }

        my @requireOptions = qw(userfile groupfile input);
        if (not $gOpt->{inputfile} or ((not $gOpt->{userfile}) && (not $gOpt->{groupfile}))) {
	        foreach my $gOptName (@requireOptions) {
			if (not $gOpt->{$gOptName}) {
				$errors .= "Missing required --".$gOptName." option.\n";
			}
		}
        }
        if ($more) {
                $errors .= "Too many arguments.\n";
        }
        if ($errors) {
                $gRetval |= ERR_OPTIONS;
                print $errors.usage();
        }

	if (defined($gOpt->{dryrun})) {
		$gDryrun=1;
	} else {
		$gDryrun=0;
	}

    exit $gRetval if $gRetval;

    if (defined($gOpt->{logfile}) && $gOpt->{logfile} ne "-") {
        open(OUTPUT, ">$gOpt->{logfile}") || die "can't open logfile $gOpt->{logfile}\n";
        $output = \*OUTPUT;
        $output = \*OUTPUT;
        Logger("Initializing logfile $gOpt->{logfile}.", 3, $gDebug, $output);
    } else {
        $output = \*STDOUT;
        Logger("Logging to STDOUT.", 3, $gDebug, $output);
    }

    if (defined($gOpt->{loglevel})) {
        $gDebug=5 if ($gOpt->{loglevel}=~/^debug$/i);
        $gDebug=4 if ($gOpt->{loglevel}=~/^verbose$/i);
    	$gDebug=3 if ($gOpt->{loglevel}=~/^info$/i);
    	$gDebug=2 if ($gOpt->{loglevel}=~/^warning$/i);
    	$gDebug=1 if ($gOpt->{loglevel}=~/^error$/i);
	    LogInfo("Logging at $gOpt->{loglevel}, $gDebug, level.", $gDebug, $output);
    }

	if ($gDebug<1 or $gDebug > 5) {
		$gDebug=2;
		$gOpt->{loglevel}="warning";
		LogWarning("Log Level not specified, logging at warning level.", $gDebug, $output);
	}
    exit $gRetval if $gRetval;

	LogWarning("Initialized options, beginning map reading", $gDebug, $output);
	if (defined($gOpt->{userfile}) and $gOpt->{userfile}) {
	        $gUsermap = buildMap("user", $gOpt->{userfile});
		LogInfo("User map created successfully.", $gDebug, $output);
	} else {
		LogWarning("No User map passed, so none built", $gDebug, $output);
	}
	if (defined($gOpt->{groupfile}) and $gOpt->{groupfile}) {
		$gGroupmap = buildMap("group", $gOpt->{groupfile});
		LogInfo("Group map created successfully", $gDebug, $output);
	} else {
		LogWarning("no group map passed, so none built.", $gDebug, $output);
	}


    LogData("Beginning file search inside $gOpt->{input}", $gDebug, $output);
    fixfiles();
	LogData("Finished parsing files on ".`hostname`, $gDebug, $output);
    close OUTPUT;
}
