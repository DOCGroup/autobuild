#
# $Id$
#

package Clone_Build_Tree;

use strict;
use warnings;

use Cwd;
use FileHandle;
use File::Path;
use File::Spec;

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
    my $root = main::GetVariable ('root');
    my $wrappers = main::GetVariable ('project_root');
    my $build = main::GetVariable ('build_name');

    # chop off trailing slash
    if ($wrappers =~ m/^(.*)\/$/) {
        $wrappers = $1;
    }

    my $current_dir = getcwd ();

    my $dir = $root;
    # strip off ACE_wrappers if it's there (sometimes it is, sometimes it isn't) and then readd it.
    if ($dir =~ m/^(.*)\/ACE_wrappers/) {
        $dir = $1;
    }
    $dir = $dir."/ACE_wrappers";

    chdir $dir;

    if (!-r $wrappers || !-d $wrappers) {
        mkpath($wrappers);
    }

    ## For convenience we look in several likely places
    my $mpcpath = $ENV{MPC_ROOT};
    if (! defined $mpcpath) {
        $mpcpath = File::Spec->canonpath("$dir/MPC");
    }
    if (! -d $mpcpath) {
        $mpcpath = File::Spec->canonpath("$dir/../MPC");
    }
    if (! -d $mpcpath) {
        $mpcpath = File::Spec->canonpath("$dir/../../MPC");
    }
    if (! -d $mpcpath) {
        print STDERR "Cannot find MPC. Either set MPC_ROOT, or put MPC in a known location.\n";
        return 1;
    }
    
    $mpcpath = File::Spec->canonpath("$mpcpath/clone_build_tree.pl");

    my $command = "perl $mpcpath $build";

    print "Running: $command\n";
    system ($command);

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("clone_build_tree", new Clone_Build_Tree());
