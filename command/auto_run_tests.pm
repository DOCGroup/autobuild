#
# $Id$
#

package Auto_Run_Tests;

use strict;
use warnings;

use Cwd;
use FileHandle;
use Time::Local;

###############################################################################
# Constructor

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {};

    bless ($self, $class);
    return $self;
}

##############################################################################

sub CheckRequirements ()
{
    my $self = shift;
    my $root = main::GetVariable ('root');

    if (!defined $root) {
        print STDERR __FILE__, ": Requires \"root\" variable\n";
        return 0;
    }
    if (!-r $root) {
        print STDERR __FILE__, ": Cannot read root: $root\n";
        return 0;
    }

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;
    my $options = shift;
    my $root = main::GetVariable ('root');
    my $configs = main::GetVariable ('configs');
    my $sandbox = main::GetVariable ('sandbox');
    my $test_ace_only = main::GetVariable ('test_ace_only');

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }
    $root .= '/ACE_wrappers';

    print "\n#################### Test (auto_run_tests) [" . (scalar gmtime(time())) . " UTC]\n";

    my $current_dir = getcwd ();

    if (!chdir $root) {
        print STDERR __FILE__, ": Cannot change to $root\n";
        return 0;
    }

    if (defined $sandbox) {
        $options .= " -s $sandbox";
    }
    if (defined $test_ace_only) {
        $options .= " -a";
    }

    if (defined $configs) {
        $options .= " -Config " . join (" -Config", split (' ', $configs));
    }

    my $command = "perl $root/bin/auto_run_tests.pl $options";

    print "Running: $command\n";
    system ("perl $root/bin/auto_run_tests.pl $options");

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("auto_run_tests", new Auto_Run_Tests ());
