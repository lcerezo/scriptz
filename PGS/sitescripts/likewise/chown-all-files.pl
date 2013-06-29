#!/usr/bin/env perl
# Copyright 2008 Likewise Software
# by Robert Auch
# find and chown files in a filesystem based on input "old info\tnew info" format
#
# v0.1 2008-09-12 RCA - first version, structures from all of Danilo's work at Delta
# v0.2 2008-11-06 RCA - updates to anonymize for MDA
# v0.4 2008-12-04 RCA - add "root directory" search
# v0.5 2008-12-18 RCA - add log levels
# v0.6 2008-12-18 RCA - add regexp "matching" of files
# v0.7 2009-01-02 RCA - re-order where the "match" vs. file stat happens to lower error rates
# v0.8 2009-01-04 RCA - add "--dry-run" to run all code paths except the actual chown.
# v1.0 2009-06-18 RCA - add error capturing properly and proper return codes
# v1.1 2009-06-18 RCA - add "--exclude-from" option for an "exclude list file"
# v1.2 2009-07-16 RCA - workaround for skipping NFS directories
# v1.3 2009-08-28 RCA - update logging levels for solaris symlinks
# v2.0 2010-05-05 RCA - update to re-include pruning of trees, autoskip nfs mounts, rewrite exclude/skip handling
#
# TODO:
# invert match is broken - fix it
# allow remaps by name instead of id

# these should only be uncommented during development - breaks Solaris 8 usage
use strict;
#use warnings;

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
my $gVer="2.0";
my $debug=0;  #the system-wide log level. Off by default, changable by switch --loglevel

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

sub addExclude($) {
    my $exc = shift;

    # only add new unique paths
    # don't add subpaths of existing exclude paths
    # i.e. don't add /a/b if /a is already excluded
    foreach my $path (@gExclude) {
        if ($exc =~ m/^$path\/|^$path$/) {
#           print "Note: $path already in exclude pathlist - skipping $exc\n";
            LogVerbose("Note: $path already in exclude pathlist - skipping $exc", $debug, $output);
            return;
        }
    }
    push(@gExclude, $exc);
    LogInfo("Added $exc to exclude pathlist", $debug, $output);
}


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

    --rootdir, -r PATH - path to use as base of search
        (default = ".&getOnOff($gOpt->{rootdir}).")

    --exclude-from, -e 'FILE' - File including path globs
         to exclude. FILE should be newline separated,
         with each path on a line, using perl-style regular expressions:
            '/data' will match '/data/file' and '/mnt/data-1/file'
            '^/data/' will only match '/data/file' 
        (default = ".&getOnOff($gOpt->{exclude}).")

    --(no)invert, -i - use the '--exclude-from' list as a match list
        If used, no tree pruning will happen, so all files, including NFS
        mounts, will be searched.
        (default = ".&getOnOff($gOpt->{invert}).")

    --log, --logfile, -l FILENAME - name of log file to write.
        (default = ".&getOnOff($gOpt->{logfile}).")

    --loglevel -v {error|warning|info} - verbosity of logging
        (default = ".&getOnOff($gOpt->{loglevel}).")

    --(no)dryrun -d - Do all logging and processing, but don't
         actually 'chown' the files.
        (default = ".&getOnOff($gOpt->{dryrun}).")

    --(no)nfs -n - Include NFS / AutoFS mount points 
        (default = ".&getOnOff($gOpt->{nfs}).")

  Examples:

    $scriptName -u usermap.tab -l /tmp/changedfiles.log
";
    return $statement;
}

# workhorse subs start here

sub buildExcludeList() {

    if (defined($gOpt->{exclude})) {
        LogDebug("Building Exclude list from $gOpt->{exclude}.", $debug, $output);
        unless (-f $gOpt->{exclude} && -s $gOpt->{exclude} && -r $gOpt->{exclude}) {
            LogError("Exclude-from option passed, but file is not usable, exiting.", $debug, $output);
            $gRetval |= ERR_OPTIONS;
            exit $gRetval;
        } else {
            #my $error = open(FH, "<$gOpt->{exclude}");
            open(FH, "<$gOpt->{exclude}") || die "Error - can't open $gOpt->{exclude} - $!";
            while (<FH>) {
                chomp;
                &addExclude ($_);
            }
            close FH;
        }
    }

    unless (not defined($gOpt->{nfs}) or $gOpt->{nfs}) {
        my $mnttab;
        my ($rmtmnt, $mntpt, $type, $options);

        if ($^O =~ m/HP-UX|Solaris|SunOS/i) {
            $mnttab = "/etc/mnttab";
        } elsif ($^O =~ m/Linux/i) {
            $mnttab = "/proc/mounts";
        } else {
            LogWarning("Can't determine NFS mounts for OS = $^O.");
            return;
        }
        open(NFS, "$mnttab" || die "failed to open $mnttab");
        while (<NFS>) {
            chomp;
            ($rmtmnt, $mntpt, $type, $options) = split (/\s+/, $_);
            if ($type =~ m/^autofs$|^nfs$/) {
                &addExclude ("^$mntpt");
            }
        }
        close NFS;

    }
}

sub buildMap($$) {
	my $maptype = shift;
	my $filename = shift;
    if (not defined($maptype)) {
        LogError("No map type given!!", $debug, $output);
        $gRetval |= ERR_MAP;
        exit $gRetval;
    } elsif (not defined ($filename)) {
        LogError("No Filename given for $maptype map!", $debug, $output);
        $gRetval |= ERR_MAP;
        $gRetval |= ERR_OPTIONS;
        exit $gRetval;
    }
	LogVerbose("Reading $maptype map from $filename", $debug, $output);
	my $map=ParseTable($filename);
	LogVerbose("Successfully read $maptype map from $filename.", $debug, $output);
	unless (defined($map->{oldid}) && defined($map->{newid}) && defined($map->{oldname}) ) {
		LogError("Missing an expected column name in $filename\n".usage(), $debug, $output);
        $gRetval |= ERR_MAP;
        exit $gRetval;
	} else {
		LogVerbose("$maptype map correctly contains 'oldid', 'newid', 'oldname' columns.", $debug, $output);
	}
	unless (defined($map->{newname})) {
		LogVerbose("Mapping 'oldname' to 'newname' because 'newname' wasn't defined in $filename", $debug, $output);
		push(@{$map->{_fieldNames}}, "newname");
		$map->{newname}=$map->{oldname};
		foreach my $entry (keys(%{$map->{oldname}})) {
			$map->{newname}->{$entry} = $map->{oldname}->{$entry};
		}
	}
	LogVerbose("Successfully built $maptype map.", $debug, $output);
	return $map;
}


sub chownfiles($) {
	my $file=$_;
    foreach my $skiplist (@gExclude) {
#        LogDebug("Checking ".$skiplist." against $file...", $debug, $output);
    	if ($file=~m[$skiplist]) {
    		LogVerbose("    Match: $file matches skip list:$skiplist!", $debug, $output);
	       	if ($gOpt->{invert}) {
	    		LogWarning("    Match: $file matches '$skiplist', continuing", $debug, $output);
	    	} else {
	    		LogWarning("    Ignore: $file matches '$skiplist', pruning", $debug, $output);
                $File::Find::prune = 1;
		    	return;
    		}
	    } else {
		    LogDebug("    Match: $file DOES NOT match skip list:$skiplist!", $debug, $output);
    		if ($gOpt->{invert}) {
	    		LogWarning("    Ignore: $file doesn't match '$skiplist', pruning", $debug, $output);
                $File::Find::prune = 1;
		    	return;
    		}
	    }
    }
	my @info = lstat($file);
	my $error=0;
	if ($#info<1) {
		LogWarning("Couldn't stat $file!", $debug, $output);
        $gRetval |= ERR_STAT;
		return;
	}
	my $uid=$info[4];
	my $gid=$info[5];
    my $islink= (-l _) ? 1: 0;
    LogDebug("File $file is a symlink", $debug, $output) if $islink;
	LogVerbose("Read: $file, uid=$uid, gid=$gid", $debug, $output);
	if ($uid==0 && $gid==0) {
		LogVerbose("    Ignore: $file uid=0, gid=0", $debug, $output);
		return;
	}
    
    # Set lower error level for chowns if file is a symbolic link;
	if (defined($gUsermap->{oldid}->{$uid}) && not($uid==0)) {
		if (defined($gGroupmap->{oldid}->{$gid}) && not($gid==0)) {
			LogWarning("    Change: $file uid now $gUsermap->{oldid}->{$uid}->{newid}, gid now $gGroupmap->{oldid}->{$gid}->{newid}", $debug, $output);
			unless ($gDryrun) {
				$error=chown($gUsermap->{oldid}->{$uid}->{newid}, $gGroupmap->{oldid}->{$gid}->{newid}, $file);
				if ($islink and $error) {
                    LogWarning("Failed to chown link $file uid and gid: $uid -> $gUsermap->{oldid}->{$uid}->{newid}; $gid -> $gGroupmap->{oldid}->{$gid}->{newid}", $debug, $output);
                    $gRetval |= ERR_CHOWN;
                } elsif ($error) {
                    LogError("Failed to chown $file uid and gid: $uid -> $gUsermap->{oldid}->{$uid}->{newid}; $gid -> $gGroupmap->{oldid}->{$gid}->{newid}", $debug, $output);
                    $gRetval |= ERR_CHOWN;
                }
			}
		} else {
			LogWarning("    Change: $file uid now $gUsermap->{oldid}->{$uid}->{newid}, gid still $gid", $debug, $output);
			unless ($gDryrun) {
				$error=chown($gUsermap->{oldid}->{$uid}->{newid}, $gid, $file);
                if ($islink and $error) {
				    LogWarning("Failed to chown link $file uid: $uid -> $gUsermap->{oldid}->{$uid}->{newid} ", $debug, $output);
                    $gRetval |= ERR_CHOWN;
                } elsif ($error) {
				    LogError("Failed to chown $file uid: $uid -> $gUsermap->{oldid}->{$uid}->{newid} ", $debug, $output);
                    $gRetval |= ERR_CHOWN;
                }
			}
		}
	} elsif (defined($gGroupmap->{oldid}->{$gid})) {
		LogWarning("    Change: $file uid still $uid, gid now $gGroupmap->{oldid}->{$gid}->{newid}", $debug, $output);
		unless ($gDryrun) {
			$error=chown($uid, $gGroupmap->{oldid}->{$gid}->{newid}, $file);
            if($islink and $error) {
    			LogWarning("Failed to chown link $file gid: $gid -> $gGroupmap->{oldid}->{$gid}->{newid} ", $debug, $output);
                $gRetval |= ERR_CHOWN;
            } elsif ($error) {
    			LogError("Failed to chown $file gid: $gid -> $gGroupmap->{oldid}->{$gid}->{newid} ", $debug, $output);
                $gRetval |= ERR_CHOWN;
            }
		}
	} else {
		LogInfo("    Ignore: $file uid $uid and gid $gid not found in maps", $debug, $output);
	}
    $_=$file;
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
                       );
        my $more = shift @ARGV;
        my $errors;

        if ($gOpt->{help} or not $ok) {
                $gRetval |= ERR_OPTIONS;
                print usage()
        }

        my @requireOptions = qw(userfile groupfile);
        if ((not $gOpt->{userfile}) && (not $gOpt->{groupfile})) {
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
        Logger("Initializing logfile $gOpt->{logfile}.", 3, $debug, $output);
    } else {
        $output = \*STDOUT;
        Logger("Logging to STDOUT.", 3, $debug, $output);
    }

    if (defined($gOpt->{loglevel})) {
        $debug=5 if ($gOpt->{loglevel}=~/^debug$/i);
        $debug=4 if ($gOpt->{loglevel}=~/^verbose$/i);
    	$debug=3 if ($gOpt->{loglevel}=~/^info$/i);
    	$debug=2 if ($gOpt->{loglevel}=~/^warning$/i);
    	$debug=1 if ($gOpt->{loglevel}=~/^error$/i);
	    LogInfo("Logging at $gOpt->{loglevel} level.", $debug, $output);
    }

	if ($debug<1 or $debug > 5) {
		$debug=2;
		$gOpt->{loglevel}="warning";
		LogWarning("Log Level not specified, logging at warning level.", $debug, $output);
	}
    exit $gRetval if $gRetval;

    buildExcludeList();


	LogWarning("Initialized options, beginning map reading", $debug, $output);
	if (defined($gOpt->{userfile}) and $gOpt->{userfile}) {
	        $gUsermap = buildMap("user", $gOpt->{userfile});
		LogInfo("User map created successfully.", $debug, $output);
	} else {
		LogWarning("No User map passed, so none built", $debug, $output);
	}
	if (defined($gOpt->{groupfile}) and $gOpt->{groupfile}) {
		$gGroupmap = buildMap("group", $gOpt->{groupfile});
		LogInfo("Group map created successfully", $debug, $output);
	} else {
		LogWarning("no group map passed, so none built.", $debug, $output);
	}


    LogData("Beginning file search with root of $gOpt->{rootdir}", $debug, $output);
    $errors=find({ wanted=>\&chownfiles, no_chdir=>1}, "$gOpt->{rootdir}");
	LogData("Finished parsing files on ".`hostname`, $debug, $output);
    close OUTPUT;
}
