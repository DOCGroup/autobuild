#
# $Id$
#

###############################################################################
# NOTE this is similar to "shell" as it executes it's options string, but
# the execution is attributed to the "Test" stage instead of the "Setup"
# stage of the build and is executed from project_root instead of root.

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
    my $project_root = main::GetVariable ('project_root');

    if (!defined $project_root) {
        print STDERR __FILE__, ": Requires \"project_root\" variable\n";
        return 0;
    }

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;
    my $options = shift;
    my $project_root = main::GetVariable ('project_root');

    if (!-r $project_root || !-d $project_root) {
        mkpath($project_root);
    }

    # chop off trailing slash
    if ($project_root =~ m/^(.*)\/$/) {
        $project_root = $1;
    }

    main::PrintStatus ('Test', 'Shell');

    my $current_dir = getcwd ();

    if (!chdir $project_root) {
        print STDERR __FILE__, ": Cannot change to $project_root\n";
        return 0;
    }

    print "Running: ${options}\n";

    system ($options);

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("test", new Test ());
