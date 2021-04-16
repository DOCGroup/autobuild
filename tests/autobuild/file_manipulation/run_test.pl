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

our $exit_status = 0;

if (!utility::run_command ("autobuild.pl test.xml")) {
    exit (1);
}

# example*.txt files
expect_file_contents (
    "if (x > 5)\n" .
    "  print(\"Greater than 5\");\n",
    'example1.txt', 'example2.txt', 'example3.txt');

expect_file_contents ("123", "multi_output_opts.txt");

expect_file_contents ("OneLine", "oneline_output.txt");

if ($exit_status) {
    print("Test Failed\n");
}
else {
    print("Test Passed\n");
}
exit ($exit_status);
