#
# $Id$
#

package SVN;

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

    main::PrintStatus ('Setup', 'GIT');

    my $current_dir = getcwd ();

    if (!chdir $root) {
        print STDERR __FILE__, ": Cannot change to $root\n";
        return 0;
    }

    # If dir= is given, extract the dir name, then remove the option from
    # the options string. If no dir is given, just run the command with
    # specified options in $root.
    my $dir;
    if ($options =~ m/dir=([^\s]*)/) {
        $dir = $1;
        $options =~ s/dir=$dir//;
    }
    else {
        $dir = $root;
    }

    if (!chdir $dir) {
        mkpath($dir);
        if(!chdir $dir) {
            print STDERR __FILE__, ": Cannot change to $dir\n";
            return 0;
        }
    }

    my $git_program = main::GetVariable ('git_program');
    if (! defined $git_program) {
        # The "git_program" variable was not defined in the
        # XML config file.  Default to using a program called "git".
        $git_program = "git";
    }

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("git", new SVN ());
