#
# $Id$
#

package ZIP;

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

    main::PrintStatus ('Setup', 'ZIP');

    my $current_dir = getcwd ();

    if (!chdir $root) {
        print STDERR __FILE__, ": Cannot change to $root\n";
        return 0;
    }

    my $zip_program = main::GetVariable ('zip_program');
    if (! defined $zip_program) {
        # The "zip_program" variable was not defined in the
        # XML config file.  Default to using a program called "zip".
        $zip_program = "zip"
    }

    # See if we should change directory before the doing the zip itself
    if ($options=~ m/cd=(\'[^\']*\'|[^\s]*)/) {
        my $dir= $1;
        $options=~ s/cd=$dir//;         # Remove what was found from options
        $dir=~ s/\'([^\']*)\'/$1/;      # Remove quotes if given
        if (!chdir $dir) {
            print STDERR __FILE__, ": Cannot change to $dir\n";
            return 0;
        }
    }

    system ("$zip_program $options");

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("zip", new ZIP ());
