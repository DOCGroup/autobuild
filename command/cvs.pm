#
# $Id$
#

package CVS;

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
    my $root = main::GetVariable ('root');

    if (!defined $root) {
        print STDERR __FILE__, ": Requires \"root\" variable\n";
        return 0;
    }
    if (!-r $root) {
        print STDERR __FILE__, ": Cannot read root dir: $root\n";
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

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    print "\n#################### Setup (CVS)\n\n";
    print "Command starting at ", (scalar gmtime(time())), " UTC\n\n";

    my $current_dir = getcwd ();

    if (!chdir $root) {
        print STDERR __FILE__, ": Cannot change to $root\n";
        return 0;
    }

    system ("cvs up");

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("cvs", new CVS ());
