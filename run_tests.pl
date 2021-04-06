eval '(exit $?0)' && eval 'exec perl -S $0 ${1+"$@"}'
  & eval 'exec perl -S $0 $argv:q'
  if 0;

use strict;
use warnings;

use File::Find qw/find/;
use File::Basename qw/dirname basename/;
use FindBin;

use lib $FindBin::Bin;
use common::utility;

my $exit_status = 0;

sub run_test
{
    my $full_path = $_;
    my $path = substr ($full_path, length ($FindBin::Bin) + 1);
    my $file = basename ($path);
    return if ($file ne "run_test.pl");
    my $dir = dirname ($path);
    print ("$dir\n");
    if (!utility::run_command ("perl $full_path")) {
        $exit_status = 1;
    }
}

find ({wanted => \&run_test, follow => 0, no_chdir => 1}, "$FindBin::Bin/tests");

exit ($exit_status);
