eval '(exit $?0)' && eval 'exec perl -S $0 ${1+"$@"}'
  & eval 'exec perl -S $0 $argv:q'
  if 0;

use strict;
use warnings;

use File::Path qw(make_path remove_tree);
use FindBin;

use File::Copy::Recursive qw(dircopy);

use constant scoreboard_tests => "$FindBin::Bin/../";
use constant build_logs => scoreboard_tests . "build_logs/";
use constant autobuild_root => scoreboard_tests . "../../";
$ENV{'PATH'} = "$ENV{'PATH'}:" . autobuild_root;
use lib autobuild_root;
chdir ($FindBin::Bin);

use common::utility;
use common::test_utils;

sub run_cmd {
    my $cmd = shift();
    print("RUN: $cmd\n");
    die() if (!utility::run_command($cmd));
}

sub run_scoreboard {
    my $dest = shift() // 'builds';
    my $src = shift() // build_logs;

    my $name = 'test';
    my $xml = "$src/$name.xml";
    my $html = "$name.html";
    remove_tree($dest);
    dircopy($src, $dest);
    run_cmd("scoreboard.pl -c -f $xml -o $html -d $dest");
}

run_scoreboard();
run_cmd("matrix.py builds");
