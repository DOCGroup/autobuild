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

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;
    my $options = shift;
    my $root = main::GetVariable ('root');

    # replace all '\x22' with '"'
    $options =~ s/\\x22/"/g;

    if (!-r $root || !-d $root) {
        mkpath($root);
    }

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    main::PrintStatus ('Setup', 'SVN');

    my $current_dir = getcwd ();

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
        print STDERR __FILE__, ": Cannot change to $dir\n";
        return 0;
    }

    my $svn_program = main::GetVariable ('svn_program');
    if (! defined $svn_program) {
        # The "svn_program" variable was not defined in the
        # XML config file.  Default to using a program called "svn".
        $svn_program = "svn"
    }

    system ("$svn_program $options");

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("svn", new SVN ());
