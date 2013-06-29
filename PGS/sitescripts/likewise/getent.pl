#!/usr/bin/perl -w
#
# Copyright 2008 Likewise Software
#
# Substitute for getent for systems that do not have getent.
#

use strict;
use warnings;

use Getopt::Long;
use File::Basename;

sub main();
main();
exit(0);

sub usage()
{
    my $scriptName = fileparse($0);

    return <<DATA;
usage: $scriptName <database> <key>

    This is a substitute for the getent command.

  Examples:

    $scriptName passwd USERNAME
    $scriptName passwd GID
    $scriptName group GROUPNAME
    $scriptName group GID

  If you need to run on a system w/o using this cript, here
  are some Perl one-liners that you can use:

    perl -e 'print join(":", getpwnam(\$ARGV[0]))."\\n";' NAME
    perl -e 'print join(":", getpwuid(\$ARGV[0]))."\\n";' UID
    perl -e 'print join(":", getgrnam(\$ARGV[0]))."\\n";' NAME
    perl -e 'print join(":", getgrgid(\$ARGV[0]))."\\n";' GID
    perl -e 'print join("\\n", gethostbyname(\$ARGV[0])), "\\n";' `hostname`
    perl -e 'while (1) {\$line= join(":", getpwent())."\\n"; exit if (\$line=~/^\\s*\$/); print \$line;}'
    perl -e 'while (1) {\$line= join(":", getgrent())."\\n"; exit if (\$line=~/^\\s*\$/); print \$line;}'

DATA
}

sub main()
{
    Getopt::Long::Configure('no_ignore_case', 'no_auto_abbrev') || die;

    my $opt = {};
    my $ok = GetOptions($opt,
                        'help|h|?',
                       );
    my $database = shift @ARGV;
    my $key = shift @ARGV;
    my $more = shift @ARGV;
    my $errors;

    if ($opt->{help} or not $ok)
    {
        die usage();
    }
    if (not $database)
    {
        $errors .= "Missing database argument.\n";
    }
    if ((not defined $key) or ($key eq ''))
    {
        $errors .= "Missing key argument.\n";
    }
    if ($more)
    {
        $errors .= "Too many arguments.\n";
    }
    if ($errors)
    {
        die $errors.usage();
    }

    my $isKeyNumeric;
    if ($key =~ /^\d+$/)
    {
        $isKeyNumeric = 1;
    }

    my @entry;
    if ($database eq 'passwd')
    {
        @entry = $isKeyNumeric ? getpwuid($key) : getpwnam($key);
    }
    elsif ($database eq 'group')
    {
        @entry = $isKeyNumeric ? getgrgid($key) : getgrnam($key);
    }
    else
    {
        die "Unknown database: $database\n";
    }

    if ((scalar @entry) == 0)
    {
        exit(1);
    }

    print join(":", @entry)."\n";

    exit(0);
}
