#!/usr/bin/perl -l


open (FH1, "< $ARGV[0]") or die "error $!";
open (OUT, "> shutdowns\.cfg");
	while (<FH1>) {
		chomp;
			( $hostname, $ipaddress ) = split(/,/);
		open (OUT, "> $hostname\.cfg");
		print OUT "define host\{\n\thost_name\t$hostname\n\taddress\t$ipaddress\n\tuse\tgeneric-host\,linux-server\n\}";
		close OUT;
			}
close FH1;
