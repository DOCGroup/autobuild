#
# $Id$
#

###############################################################################
# NOTE this is the same as "shell" as it executes it's options string, but
# the execution is attributed to the "Test" stage instead of the "Setup"
# stage of the build.

package Test;

use strict;
use warnings;

use Cwd;
use FileHandle;

###############################################################################
# Constructor

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {'substitute_vars_in_options' => 1};

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

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;
    my $options = shift;
    my $root = main::GetVariable ('root');

    if (!-r $root || !-d $root) {
        mkpath($root);
    }

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    main::PrintStatus ('Test', 'Shell');

    my $current_dir = getcwd ();

    if (!chdir $root) {
        print STDERR __FILE__, ": Cannot change to $root\n";
        return 0;
    }

    print "Running: ${options}\n";

    system ($options);

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("test", new Test ());
