eval '(exit $?0)' && eval 'exec perl -S $0 ${1+"$@"}'
  & eval 'exec perl -S $0 $argv:q'
  if 0;

use strict;
use warnings;

use FindBin;

use common::utility;
use common::test_utils;

$ENV{'PATH'} = "$ENV{'PATH'}:$FindBin::Bin";

our $exit_status = 0;

if (-e "cmake_runs.txt") {
    unlink ("cmake_runs.txt") or die ("Couldn't unlink \"cmake_runs.txt\": $!");
}

if (!utility::run_command ("autobuild.pl test.xml")) {
    exit (1);
}

expect_file_contents(
    "<<--version>>\n" .
    "<<--cmake-cmd>>\n",
    "cmake_runs.txt");

expect_file_contents(
    "<<..>> <<-G>> <<Fake Generator>>\n" .
    "<<--build>> <<.>>\n",
    "build/cmake_runs.txt");

expect_file_contents(
    "<<..>> <<--extra-config-opt>> <<-G>> <<Extra Fake Generator>>\n" .
    "<<--build>> <<.>> <<--extra-build-opt>>\n",
    "subdir/the_build_dir/cmake_runs.txt");

my $found_version = 0;
my $fh;
if (!open ($fh, '<', "log.txt")) {
    print STDERR ("Couldn't open \"log.txt\": $!");
    $exit_status = 1;
}
while (<$fh>) {
    if (/fake_cmake\.pl version 123\.456\.789/) {
        $found_version = 1;
        last;
    }
}
if (!$found_version) {
    print STDERR ("ERROR: Couldn't find expected version in \"log.txt\"\n");
    $exit_status = 1;
}

if ($exit_status) {
    print STDERR ("=" x 40, " Dumping log.txt:");
    my $fh;
    if (!open ($fh, '<', "log.txt")) {
        print STDERR ("Couldn't open \"log.txt\" for dumping: $!");
        $exit_status = 1;
    }
    while (<$fh>) {
        print $_;
    }
}
exit ($exit_status);
