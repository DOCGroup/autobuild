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

sub copy_dir {
  my $src_dir = shift;
  my $des_dir = shift;
  print "cp -R $src_dir $des_dir\n";
  system("cp -R $src_dir $des_dir");
}

sub run_scoreboard {
  system("../../../scoreboard.pl -c -f ./test.xml -o test.html -d runs/run");
}

sub diff {
  my $d1 = shift;
  my $d2 = shift;
  print "compare $d1 with $d2\n";
  my $diff_index = "diff runs/$d1/build1/index.html runs/$d2/build1/index.html";
  my $r = system($diff_index);
  if ($r) {
    print "$r = $diff_index\n";
    return $r;
  }
  return 0;
}

sub compare_runs {
  return diff("run1", "run2") + diff("run1", "run");
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
