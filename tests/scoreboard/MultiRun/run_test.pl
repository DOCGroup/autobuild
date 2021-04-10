eval '(exit $?0)' && eval 'exec perl -S $0 ${1+"$@"}'
  & eval 'exec perl -S $0 $argv:q'
  if 0;

use strict;
use warnings;

use FindBin;
use constant autobuild_root => "$FindBin::Bin/../../../";
$ENV{'PATH'} = "$ENV{'PATH'}:" . autobuild_root;
use lib autobuild_root;
chdir ($FindBin::Bin);

use common::utility;
use common::test_utils;

use File::Path qw(make_path remove_tree);

sub run_cmd {
  my $cmd = shift;
  print "$cmd\n";
  return system($cmd);
}

sub copy_dir {
  my $src_dir = shift;
  my $des_dir = shift;
  run_cmd("cp -R $src_dir $des_dir");
}

sub run_scoreboard {
  run_cmd("../../../scoreboard.pl -c -f ./test.xml -o test.html -d runs/run");
}

sub diff {
  my $run_a = shift;
  my $run_b = shift;
  my $o = shift;
  my $r = run_cmd("diff runs/$run_a/$o runs/$run_b/$o");
  if ($r) {
    print "$r\n";
    return 1;
  }
  return 0;
}

sub compare_runs {
  my $r = 0;
  $r += diff("run1", "run2", "build1/index.html");
  $r += diff("run1", "run" , "build1/index.html");
  $r += diff("run1", "run2", "build3/2021_03_09_17_33_Totals.html");
  $r += diff("run1", "run" , "build3/2021_03_09_17_33_Totals.html");
  return $r;
}

make_path("runs");
copy_dir("../build_logs", "runs/run");

run_scoreboard();
copy_dir("runs/run", "runs/run1");

run_scoreboard();
copy_dir("runs/run", "runs/run2");

run_scoreboard();
my $exit_status = compare_runs();

remove_tree("runs");

if ($exit_status) {
  print("Test Failed\n");
} else {
  print("Test Passed\n");
}
exit ($exit_status);
