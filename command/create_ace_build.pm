#
# $Id$
#

package Create_ACE_Build;

use strict;
use warnings;

use Cwd;
use FileHandle;
use File::Path;

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
    my $root = main::GetVariable ('project_root');

    if (!defined $root) {
        print STDERR __FILE__, ": Requires \"project_root\" variable\n";
        return 0;
    }
    
    my $build_name = main::GetVariable ('build_name');

    if (!defined $build_name) {
        print STDERR __FILE__, ": Requires \"build_name\" variable\n";
        return 0;
    }

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;
    my $options = shift;
    my $wrappers = main::GetVariable ('project_root');
    my $build = main::GetVariable ('build_name');

    # chop off trailing slash
    if ($wrappers =~ m/^(.*)\/$/) {
        $wrappers = $1;
    }

    if (!-r $wrappers || !-d $wrappers) {
        mkpath($wrappers);
    }

    main::PrintStatus ('Setup', 'Create ACE Build');

    my $current_dir = getcwd ();

    if (!chdir "$wrappers/../..") {
        print STDERR __FILE__, ": Cannot change to $wrappers../..\n";
        return 0;
    }

    my $command = "perl bin/create_ace_build.pl $options $build";

    print "Running: $command\n";
    system ($command);

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("create_ace_build", new Create_ACE_Build ());
