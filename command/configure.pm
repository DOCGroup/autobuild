#
# $Id$
#

package Configure;

use strict;
use warnings;

use Cwd;
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
    my $root = main::GetVariable ('root');

    if (!defined $root) {
        print STDERR __FILE__, ": Requires \"root\" variable\n";
        return 0;
    }

    my $build_name = main::GetVariable ('build_name');

    if (!defined $build_name) {
        print STDERR __FILE__, ": Requires \"build_name\" variable\n";
        return 0;
    }
    
    if (!-r $root || !-d $root) {
        print STDERR __FILE__, ": Cannot access \"root\" directory: $root\n";
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
    my $project_root = main::GetVariable ('project_root');
    my $build_name = main::GetVariable ('build_name');

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    main::PrintStatus ('Configure', 'configure');

    my $current_dir = getcwd ();

    # If --preclean is given, remember that, then remove it from the options.
    my $preclean = 0;
    if ($options =~ m/--preclean/) {
        $preclean = 1;
        $options =~ s/--preclean//;
    }
    
    if (!chdir $root) {
        print STDERR __FILE__, ": Cannot change to $root\n";
        return 0;
    }

    my $build_path = "build/" . "$build_name";
    if (!-r $build_path || !-d $build_path) {
        if (!mkpath($build_path)) {
            print STDERR __FILE__, ": Cannot create \"build_path\" directory: $build_path\n";
            return 0;
	}
    }
    elsif ($preclean) {
	rmtree($build_path);
        if (!mkpath($build_path)) {
            print STDERR __FILE__, ": Cannot recreate \"build_path\" directory: $build_path\n";
            return 0;
	}
    }
    if (!chdir $build_path) {
        print STDERR __FILE__, ": Cannot change to $build_path\n";
        return 0;
    }

    my $command = File::Spec->abs2rel($root) . "/configure $options";

    print "Running: $command\n";

    my $ret = system ($command);

    if ($ret != 0)
    {
        my $working_dir = getcwd();

        print "[CONFIGURE ERROR detected in $working_dir]\n ";
    } 

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("configure", new Configure ());
