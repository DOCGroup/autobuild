eval '(exit $?0)' && eval 'exec perl -S $0 ${1+"$@"}'
  & eval 'exec perl -S $0 $argv:q'
  if 0;

use strict;
use warnings;

use File::Path qw(make_path remove_tree);
use FindBin;

use File::Copy::Recursive qw(dircopy fcopy);

use constant autobuild_root => "$FindBin::Bin/../../../";
$ENV{'PATH'} = "$ENV{'PATH'}:" . autobuild_root;
use lib autobuild_root;
chdir ($FindBin::Bin);

use common::utility;
use common::test_utils;

my $runs = "runs";
my $run = "$runs/run";
my $run1 = "$runs/run1";
my $run2 = "$runs/run2";

sub run_cmd {
    my $cmd = shift();
    print("RUN: $cmd\n");
    die() if (!utility::run_command($cmd));
}

sub run_scoreboard {
    run_cmd("scoreboard.pl -c -f ./runs/test.xml -o test.html -d $run");
}

sub compare_runs {
    my $r = 0;
    my $index = "build1/index.html";
    my $total = "build3/2021_03_09_17_33_Totals.html";
    $r += compare_files("$run1/$index", "$run2/$index");
    $r += compare_files("$run1/$index", "$run/$index");
    $r += compare_files("$run1/$total", "$run2/$total");
    $r += compare_files("$run1/$total", "$run/$total");
    return $r;
}

remove_tree($runs);
if (-e $runs) {
    print "failed to delete $runs";
    exit(1);
}

make_path($runs);
fcopy("../build_logs/test.xml", $runs);
dircopy("../build_logs", $run);

run_scoreboard();

dircopy($run, $run1);
run_scoreboard();

dircopy($run, $run2);
run_scoreboard();

my $exit_status = compare_runs();
if ($exit_status) {
    print("Test Failed\n");
}
else {
    print("Test Passed\n");
}
exit ($exit_status);
