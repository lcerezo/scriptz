#!/usr/bin/perl -w
#
# Copyright 2008 Likewise Software
#
#    This is a substitute for the ypcat command.
#

use strict;
#use warnings;

use Getopt::Long;
use File::Basename;
my $debug=0;
my $alias=0;
my $stripDomain=1;
my $scriptName = fileparse($0);

sub main();
main();
exit(0);

sub usage($)
{
    my $opt=shift;
    my $aliasing=getOnOff($opt->{alias});
    my $debugging=getOnOff($debug);
    my $domainstripping=getOnOff($opt->{stripdomain});
    my $cmdline = "usage: $scriptName <database> <key>";
    $cmdline = "usage: $scriptName <key> <database>" if $scriptName=~/match/;

    return <<DATA;
$cmdline

    This is a substitute for the ypcat and ypmatch commands.  Supports most ex-NIS databases
    under Likewise, including "hosts" "autofs" "services", if they are set up in GPO properly.
    
  Full help available via "perldoc $scriptName"
  
  Setup:
    ln -s ypcat $scriptName
    ln -s ypmatch $scriptName
    ln -s niscat $scriptName
    ln -s nisgrep $scriptName
    ln -s nismatch $scriptName

  Examples:

    ypcat hosts
    ypcat -k auto.home
    ypmatch <name> group
    ypgrep -k passwd <user>

DATA
}

sub isKeyNumeric($) {
    my $key=shift;
    my $isKeyNumeric=0;
    if ($key =~ /^\d+$/)
    {
        $isKeyNumeric = 1;
    }
    return $isKeyNumeric;
}

sub getOnOff($) {
    my $value=shift;
    if (defined($value) && $value) {
        return "On";
    } else {
        return "Off";
    }
    die "Error getting status of flag $value";
}

sub splitline($$) {
    my $line=shift;
    chomp $line;
    return if ($line=~/^\s*$/);
    my $result=shift;
    my ($name, $data) = split(/\s+/, $line, 2);
    $debug && print "Split '$name' and '$data' from line.";
    $result->{$name} = $line;
}

sub groupLookup($$)
{
    my $key=shift;
    my $result=shift;
    if (isKeyNumeric($key)) {
        my $line="";
        open(LG, "/opt/likewise/bin/lw-find-group-by-id --level 1 $key 2>&1|");
        while (<LG>) {
        $debug && print "GROUP BY ID: Reading line $_";
            chomp;
            $line=$line.$_.",";
        }
        close LG;
        $debug && print "GROUP BY ID: full data is: $line\n";
        while ($line=~/=======,Name:\s+([^,]+),Gid:\s+([^,]+),SID:\s+[^,]+,Members:\s*,([^=]*),$/gi) {
            $debug && print "GROUP BY ID: looking at line $_\n";
            my ($name, $gid, $members)=($1, $2, $3);
            $result->{$name}="$name:x:$gid:$members";
        }
    } else {
        my $line="";
        open(LG, "/opt/likewise/bin/lw-find-group-by-name --level 1 $key 2>&1|");
        while (<LG>) {
            $debug && print "GROUP BY NAME: reading line: $_";
            chomp;
            $line=$line.$_.",";
        }
        close LG;
        $debug && print "GROUP BY NAME: full data is : $line\n";
        while ($line=~/=======,Name:\s+([^,]+),Gid:\s+([^,]+),SID:\s+[^,]+,Members:\s*,([^=]*),$/gi) {
            $debug && print "GROUP BY NAME: looking at line $_\n";
            my ($name, $gid, $members)=($1, $2, $3);
            $result->{$name}="$name:x:$gid:$members";
        }
    }
    return $result;
}

sub userLookup($$)
{
    my $key=shift;
    my $result=shift;
    if (isKeyNumeric($key)) {
        my $line="";
        open(LU, "/opt/likewise/bin/lw-find-user-by-id $key 2>&1|");
        while (<LU>) {
            $debug && print "USER BY ID: Reading line $_";
            chomp;
            $line=$line.$_.",";
        }
        close LU;
        $debug && print "USER BY ID: full data is: $line\n";
        while ($line=~/=======,Name:\s+([^,]+),SID:\s+[^,]+,Uid:\s+([^,]+),Gid:\s+([^,]+),Gecos:\s+([^,]+),Shell:\s+([^,]+),Home dir:\s+([^,]+)/gi) {
            $debug && print "USER BY ID: looking at line $_\n";
            my ($name, $uid, $gid, $gecos, $shell, $homedir)=($1, $2, $3, $4, $5, $6);
            $result->{$name}="$name:x:$uid:$gid:$gecos:$shell:$homedir";
        }
    } else {
        my $line="";
        open(LU, "/opt/likewise/bin/lw-find-user-by-name $key 2>&1|");
        while (<LU>) {
            $debug && print "USER BY NAME: reading line: $_";
            chomp;
            $line=$line.$_.",";
        }
        close LU;
        $debug && print "USER BY NAME: full data is : $line\n";
        while ($line=~/=======,Name:\s+([^,]+),SID:\s+[^,]+,Uid:\s+([^,]+),Gid:\s+([^,]+),Gecos:\s+([^,]+),Shell:\s+([^,]+),Home dir:\s+([^,]+)/gi) {
            $debug && print "USER BY NAME: Reading Line: $_.\n";
            my ($name, $uid, $gid, $gecos, $shell, $homedir)=($1, $2, $3, $4, $5, $6);
            $result->{$name}="$name:x:$uid:$gid:$gecos:$shell:$homedir";
        }
    }
    return $result;
}

sub hostLookup($$$$)
{
    my $key = shift;
    my $database = shift;
    my $opt = shift;
    my $result = shift;
    if (not defined($key)) {
        $debug && print "ypcat $database requested...\n";
        ################################################ Changes from BiffSocko (tm)
        if( -f "$opt->{readfile}"){
            if(!(open(Fp, $opt->{readfile}))){
                print "can't open $opt->{readfile} for ypcat $database .. exiting\n";
                exit(1);
            }else{
                while(<Fp>){
                    splitline($_, $result)
                }
                close(Fp);
                return $result;
            }
        }else{
            print "can't find $opt->{readfile} .. exiting\n";
            exit(1);
        }
        
        ##################################################
        # BiffSocko                                      #
        # done - edits completed here      {
    } else {
        $debug && print "ypmatch $database $key requested...\n";
        ################################################ Changes from BiffSocko (tm)
        if( -f "$opt->{readfile}"){
            if(!(open(Fp, $opt->{readfile}))){
                print "can't open $opt->{readfile} .. exiting\n";
                exit(1);
            }else{
                while(<Fp>){
                    $debug && print "$key and $_";
                    splitline($_, $result) if ($_=~/^$key\s+/);
                }
                close(Fp);
                return $result;
            }
        }else{
            print "can't find $opt->{readfile} .. exiting\n";
            exit(1);
        }
    }
}

sub main()
{
    Getopt::Long::Configure('ignore_case', 'no_auto_abbrev') || die;

    my $opt = {};
#    $opt->{readfile}="/etc/hostsmap";
    my $maplist="hosts|services|auto";

    my $ok = GetOptions($opt,
                        'help|h|?',
            'debug',
            'alias|a',
            'stripdomain|sd',
            'key|k',
            'readfile|hostfile|f=s',
            'map|m=s',
                       );
    my ($database, $key, $errors);
    if ($scriptName=~/^(yp|nis)(cat|grep)/) {
        $database = shift @ARGV;
        $key = shift @ARGV;
    } elsif ($scriptName=~/^(nis|yp)match/) {
        $key = shift @ARGV;
        $database = shift @ARGV;
    } else {
        $errors.="Unknown script name passed.  Expecting 'ypcat' or 'ypmatch' or 'nisgrep'. ";
    }
    my $more = shift @ARGV;
    my $result={};
    if (defined($opt->{map}) and $opt->{map} ne '') {
        $opt->{map} = "($maplist|$opt->{map})";
    } else {
        $opt->{map} = "($maplist)";
    }

    if ($opt->{help} or not $ok)
    {
        die usage($opt);
    }
    if (not $database)
    {
        $errors .= "Missing database argument.\n";
    }
    $debug = 1 if ($opt->{debug});
    if ($more)
    {
        $errors .= "Too many arguments.\n";
    }
    if ($errors)
    {
        die $errors.usage($opt);
    }

    $debug && print "Options are all ok\n";
    if ((not defined $key) or ($key eq ''))
    {
#        $errors .= "Missing key argument.\n";
        if ($database=~/$opt->{map}/) {
            if ($database=~/^auto/i) {
                $opt->{readfile} = "/etc/lwi_automount/$database";
            } else {
                $opt->{readfile} = "/etc/$database" if ((-f "/etc/$database") and not defined($opt->{readfile}));
            }
            hostLookup($key, $database, $opt, $result);
        } else {
            $debug && print "running lw-ypcat -k\n";
            open(FH, "/opt/likewise/bin/lw-ypcat -k $database 2>&1|");
            my @list=<FH>;
            close FH;
            foreach my $entry (@list) {
                next if ($entry eq "0");
                chomp $entry;
                splitline($entry, $result);
            }
        }
    } else {

        if ($database=~/$opt->{map}/) {
            if ($database=~/^auto/i) {
                $opt->{readfile} = "/etc/lwi_automount/$database";
            } else {
                $opt->{readfile} = "/etc/$database" if ((-f "/etc/$database") and not defined($opt->{readfile}));
            }
            hostLookup($key, $database, $opt, $result);
        } elsif (isKeyNumeric($key) && $database eq "passwd") {
            userLookup($key, $result);
        } elsif (isKeyNumeric($key) && $database eq "group") {
            groupLookup($key, $result);
        } else {
            $debug && print "running lw-ypmatch\n";
                open(FH, "/opt/likewise/bin/lw-ypmatch $key $database 2>&1|") || die $!;
            my @list=<FH>;
            close FH;
            chomp($list[0]);
            $result->{$key}=$list[0];
        };
    }

    if (scalar (keys(%{$result})) == 0)
    {
        exit(1);
    }

    foreach my $entry (sort(keys(%{$result}))) {
        $result->{$entry}=~s/\<null\>/ /;
        if ($opt->{key}) {
            print "$entry ", $result->{$entry}, "\n";
        } else {
            print $result->{$entry}, "\n";
        }
    }

    exit 0;
}

=head1 Likewise ypcat replacement tool

usage: ypcat.pl <database> <key>

    This is a substitute for the ypcat and ypmatch commands.  Supports most ex-NIS databases
    under Likewise, including "hosts" "autofs" "services", if they are set up in GPO properly.
    
  Full help available via "perldoc ypcat.pl"
  
=head2 Setup

  This tool is designed to be a drop-in replacement for the NIS and NIS+ "ypcat", "ypmatch", 
  "niscat", "nisgrep", and "nismatch" utilities.  To make this drop-in replacement complete,
  perform the following changes as root in a directory in the system path, such as "/usr/bin"

    ln -s ypcat ypcat.pl
    ln -s ypmatch ypcat.pl
    ln -s niscat ypcat.pl
    ln -s nisgrep ypcat.pl
    ln -s nismatch ypcat.pl

=head2 Examples

    ypcat hosts
    ypcat -k auto.home
    ypmatch <name> group
    ypgrep -k passwd <user>

=head2 Options

    ypcat.pl --readfile <filename>
        File to read for matching (defaults to database name in /etc)
        
    ypcat.pl --map <mapname>
        Map names that will use "--readfile" rather than falling back
        to lw-ypcat  Defaults to (hosts|services|auto)

  Some extra flags (all have a --no_ version):
    ypcat.pl --alias <database> (or -a): Turns on alias resolution (slow)
        Aliasing is Off by default.

    ypcat.pl --stripdomain <database> (or -sd): "dirty" alias resolution - 
        Removes the "DOMAIN\\" from the front of non-aliased names
        Domain stripping is Off by default.

    ypcat.pl --debug <database>: Prints lots of extra junk (messy)
        Debugging is Off by default.

=cut