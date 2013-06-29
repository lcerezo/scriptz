#!/usr/bin/perl

# Copyright 2011 BeyondTrust Software
# use the BeyondTrust PowerBroker IdentityServices hashing algorithm
# to turn a Windows SID into a Unix UID

use strict;
use warnings;

use Getopt::Long;
use File::Basename;
use Carp;
use FindBin;

sub sid2uid($) {
    my $SID=shift;

    my @authorities=split(/-/, $SID);
    if ($authorities[0] ne "S") {
        die "invalid SID format $SID, invalid start sequence";
    }
    if ($authorities[7]!~/^\d+$/) {
        die "invalid SID format $SID - Domain SID, no RID?";
    }

    my $dwHash=0;

    $dwHash^=$authorities[4];
    $dwHash^=$authorities[5];
    $dwHash^=$authorities[6];

    my $dwHashTemp=$dwHash;

    $dwHash = ($dwHashTemp & 0xFFF00000) >> 20;
    $dwHash += ($dwHashTemp & 0x000FFF00) >> 8;
    $dwHash += ($dwHashTemp & 0x000000FF);
    $dwHash &= 0x0000FFF;

    $dwHash <<= 19;
    $dwHash += ($authorities[7] & 0x0007FFFF);

    return $dwHash;
}

sub uid2sid($) {
    my $uid=shift;
}

if ($ARGV[0]=~/^\d+$/) {
    print uid2sid($ARGV[0]), "\n";
} else {
    print sid2uid($ARGV[0]), "\n";
}