#!/usr/bin/perl
#
#   Copyright 2011 Likewise
#   All Rights Reserved.
#   Version 1.00
#
#   Input $userfile, tab or comma separated list of users and aliases.
#   run from a computer in the cell that you want to make changes
#   It will generate a bash script for process review.
#   run the bash script to make the changes
#
use Getopt::Long;
use Carp;
use File::Basename;
my $gVer = "1.0.0";
#
my $ADadmin="dcwills";
my $ADpasswd="Password1";
my $userfile = "logonnames.txt";
my $runfile = "changealias.sh";
sub main();
main();
#
sub getcellbase()
{
	chomp;
	s/CN=\$LikewiseIdentityCell,//;
	return $_;
}
sub WhichCell($)
{
	my ($joinOU) = @_;
    #
    # this does not give what we want:	
    #	$command = "/opt/likewise/bin/lw-adtool -a search-cells --search-base $joinOU --logon-as=$ADadmin --passwd=$ADpasswd";
    #
	my @cells;
	my @candidates;
	$command = "/opt/likewise/bin/lw-adtool -a search-cells --logon-as=$ADadmin --passwd=$ADpasswd";
	@cells = map(getcellbase , grep(/\$LikewiseIdentityCell/, `$command`));
	foreach my $cell (@cells) {
	    print("cell $cell\n");
		if($joinOU =~ /$cell/) {
			push(@candidates, $cell);	
		}
	}
	@candidates = sort { length($b) <=> length($a) } @candidates;
	return $candidates[0];
}

#######################################################
sub usage($)
{
    my $opt = shift || confess "no options hash passed to usage!\n";
    my $scriptName = fileparse($0);
    my $helplines = "
$scriptName version $gVer 
(c) 2011, Likewise Software
All Rights Reserved.

usage: $scriptName [options] files

    Modify a cell for the current cell.
        $scriptName 

    Modify a cell for computers in the base OU 
    (searches AD for the cell above the specified base)

        $scriptName --base=OU=mySecureOU,DC=connable,DC=com

";
    return $helplines;
}

# returns pretty "on/off" status for the default values
sub getOnOff($) 
{
    my $test = shift;
    if ($test) {
        return $test if ($test=~/../ || $test > 1);
        return "on";
    } else {
        return "off";
    }
}

sub main() 
{
    $opt = {
        base => "",
    };
    my $ok = GetOptions($opt,
        'help|h|?',
        'base|b=s',
    );
    if ($opt->{help} or not $ok) {
        print usage($opt);
        exit 0;
    }
    my $joinOU = `/opt/likewise/bin/domainjoin-cli query | grep Disting`;
    if($opt->{base} eq "") {
        $opt->{base} = `/opt/likewise/bin/domainjoin-cli query | grep Disting`;
        $opt->{base} =~ s/^[^,]*,//;
    }
    chomp($opt->{base});
    print("Cell is at or above: $opt->{base}\n");
	$cell = WhichCell($opt->{base});
	print "We are modifying cell $cell\n";
	print("Creating script $runfile\n");
	open(RUNFILE, ">$runfile") or die("can't open output file $runfile\n");
	`chmod +x $runfile`;
	print RUNFILE "#!/bin/bash\n";
	open(FILE,"<$userfile") or die("can't open input file $userfile\n");
	while(<FILE>) {
		chomp();
		/(.*)[\t,](.*)/;
		my $sAMAccountName = $1;
		my $alias = $2;
		@results = `/opt/likewise/bin/lw-adtool -a lookup-cell-user --dn $cell --user $1 --logon-as=$ADadmin --passwd=$ADpasswd --login-name`;
		@login = grep(/login-name/,@results);
		$oldalias = $login[0];
		chomp($oldalias);
		$oldalias =~ s/login-name: //;
		print RUNFILE ("#changing the alias of $sAMAccountName\n");
		print RUNFILE ("echo $sAMAccountName\n");
		print RUNFILE ("echo old alias\n");
		print RUNFILE ("/opt/likewise/bin/lw-adtool -a lookup-cell-user --dn $cell --user $1 --logon-as=$ADadmin --passwd=$ADpasswd --login-name\n");
		print RUNFILE ("/opt/likewise/bin/lw-adtool -a edit-cell-user --dn \"$cell\" --user $sAMAccountName  --logon-as=$ADadmin --passwd=$ADpasswd --login-name $alias\n");
		print RUNFILE ("echo new alias\n");
		print RUNFILE ("/opt/likewise/bin/lw-adtool -a lookup-cell-user --dn $cell --user $1 --logon-as=$ADadmin --passwd=$ADpasswd --login-name\n");
	}
	close(RUNFILE);
}
