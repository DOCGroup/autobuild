eval '(exit $?0)' && eval 'exec perl -S $0 ${1+"$@"}'
    & eval 'exec perl -S $0 $argv:q'
    if 0;

# $Id$
#

use strict;
use warnings;
use diagnostics;
use common::scoreparser;
use FileHandle;
use Getopt::Std;


my %builds;


sub load_build_list ($)
{
    my $file = shift;
    my $parser = new ScoreboardParser;
    $parser->Parse ($file, \%builds);
}


sub print_build_names ()
{
    my @buildlist;

    foreach my $buildname (keys %builds) {
       push @buildlist, $buildname;
    }

    @buildlist = sort(@buildlist);

    foreach my $name (@buildlist) {
       print $name."\n";
    }
}


use vars qw/$opt_h $opt_i/;

if (!getopts ('i:h')
    || !defined $opt_i
    || defined $opt_h) {
    print "test-list-extract.pl -i file -o file [-h]\n";
    print "    -h         display this help\n";
    print "    -i         file for which list should be generated\n";
    exit (1);
}

load_build_list ($opt_i);
print_build_names();


