#
# $Id$
#

package CVS;

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

    main::PrintStatus ('Setup', 'CVS');

    my $current_dir = getcwd ();

    if (!chdir $root) {
        print STDERR __FILE__, ": Cannot change to $root\n";
        return 0;
    }

    my $cvs_program = main::GetVariable ('cvs_program');
    if (! defined $cvs_program) {
        # The "cvs_program" variable was not defined in the
        # XML config file.  Default to using a program called "cvs".
        $cvs_program = "cvs"
    }

    my $ret = system ("$cvs_program $options");
    if ($ret != 0) {
      print STDERR __FILE__, ": CVS command failed.\n";
      return 0;
    }

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("cvs", new CVS ());
