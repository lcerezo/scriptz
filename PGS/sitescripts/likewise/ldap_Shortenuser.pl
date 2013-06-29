#!/usr/bin/perl -w

#use strict;
use Net::LDAP;
#$biglist = '$ARGV[0]';
open (USERLIST,"/tmp/list") || warn "Can't open ";
open (LOGFILE, ">/tmp/log.hopethisshitworks");
	$ldap = Net::LDAP->new( 'houdc27.onshore.pgs.com' ) or die "$@";
	$mesg = $ldap->bind ( ' CN=hou-likewise_dirsvc,OU=Service accounts,OU=Houston,DC=onshore,DC=pgs,DC=com' ,
				password => 'Aq5BadEihO4ApaK'
				);
while (<USERLIST>) {
		chomp ($_);
		$mesg = $ldap->search (
				base => "dc=onshore,dc=pgs,dc=com",
				filter => "(&(objectclass=person)(userPrincipalName=$_*))",
				attrs => ['userPrincipalName', 'givenName', 'sn', 'samAccountName' ] 
				);
		$mesg->code && die $mesg->error;
			foreach $entry ($mesg->entries) { 
						#$entry->dump; 
						$upn = $entry->get_value( 'userPrincipalName' );
						$first = lc($entry->get_value( 'givenName' ) );
						$last  = lc($entry->get_value( 'sn'	   ) );
						$samAccountName  = lc($entry->get_value( 'samAccountName'   ) );
						$loginLength	= length($samAccountName);
					#	print "$samAccountName is $loginLength\n";
					#	print "$loginLength";
						if ( ($loginLength < 9) && ($samAccountName !~ /\./) ){
							print "sammy $loginLength, not shortening $samAccountName\n";
							$shortlogin = $samAccountName;
							}
						else 	{
							$shortlogin = substr($first, 0, 1) . substr($last, 0, 7);
							print "shortlogin for user $upn is $shortlogin\n";
							}	
						#print LOGFILE "$upn,$first,$last,$samAccountName,$loginLength,$shortlogin\n";
						print LOGFILE "$samAccountName\t$shortlogin\n";
						}
			}
$mesg = $ldap->unbind;
#close ( USERLIST );
