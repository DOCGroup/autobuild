eval '(exit $?0)' && eval 'exec perl -S $0 ${1+"$@"}'
  & eval 'exec perl -S $0 $argv:q'
  if 0;

use strict;
use warnings;

my $args = join(" ", map { "<<$_>>" } @ARGV);
if ($args eq "<<--version>>") {
    print ("fake_cmake.pl version 123.456.789\n");
}

if ($args =~ "<<--fail-on-purpose>>") {
    exit (1);
}

my $file = "cmake_runs.txt";
open (my $fd, ">>$file") or die ("Couldn't open $file: $!");
print $fd "$args\n";
