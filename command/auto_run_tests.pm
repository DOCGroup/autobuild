#
# $Id$
#

package Auto_Run_Tests;

use strict;
use FileHandle;
use Cwd;

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
    my $ace_root = main::GetVariable ('ace_root');

    if (!defined $ace_root) {
        print STDERR __FILE__, ": Requires \"ace_root\" variable\n";
        return 0;
    }
    if (!-r $ace_root) {
        print STDERR __FILE__, ": Cannot read ace_root: $ace_root\n";
        return 0;
    }

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;
    my $options = shift;
    my $ace_root = main::GetVariable ('ace_root');
    my $configs = main::GetVariable ('configs');
    my $sandbox = main::GetVariable ('sandbox');

    # chop off trailing slash
    if ($ace_root =~ m/^(.*)\/$/) {
        $ace_root = $1;
    }

    print "\n#################### Tests (auto_run_tests) \n\n";
    print "Command starting at ", (scalar gmtime(time())), " UTC\n\n";

    my $current_dir = getcwd ();

    if (!chdir $ace_root) {
        print STDERR __FILE__, ": Cannot change to $ace_root\n";
        return 0;
    }

    if (defined $sandbox) {
        $options .= " -s $sandbox";
    }
    
    if (defined $configs) {
        $options .= " -Config " . join (" -Config", split (' ', $configs));
    }

    my $command = "perl $ace_root/bin/auto_run_tests.pl $options";

    print "Running: $command\n";
    system ("perl $ace_root/bin/auto_run_tests.pl $options");

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("auto_run_tests", new Auto_Run_Tests ());
