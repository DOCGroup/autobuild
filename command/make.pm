#
# $Id$
#

package Make;

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

    print "\n#################### Compile (make) [" . (scalar gmtime(time())) . " UTC]\n";

    my $current_dir = getcwd ();

    if (!chdir $root) {
        print STDERR __FILE__, ": Cannot change to $root\n";
        return 0;
    }

    my $make_options = "";

    if ($options =~ m/makeopts='(.*?)'/) {
        $make_options = $1;
    }

    system ("make $make_options");

    return 1;
}

##############################################################################

main::RegisterCommand ("make", new Make ());
