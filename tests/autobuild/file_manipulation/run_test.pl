eval '(exit $?0)' && eval 'exec perl -S $0 ${1+"$@"}'
  & eval 'exec perl -S $0 $argv:q'
  if 0;

use strict;
use warnings;

use common::utility;
use common::test_utils;

our $exit_status = 0;

if (!utility::run_command ("autobuild.pl test.xml")) {
    exit (1);
}

# example*.txt files
my $example_contents = <<"EOF";
if (x > 5)
  print("Greater than 5");
EOF
expect_file_contents ($example_contents,
    'example1.txt', 'example2.txt', 'example3.txt');

expect_file_contents ("123", "multi_output_opts.txt");

expect_file_contents ("OneLine", "oneline_output.txt");

exit ($exit_status);
