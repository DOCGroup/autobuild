#
# $Id$
#

package Make;

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
        print STDERR "make: Requires \"root\" variable\n";
        return 0;
    }
    if (!-r $root) {
        print STDERR "make: Cannot read root dir: $root\n";
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

    print "\n#################### Compile (make) \n\n";

    my $current_dir = getcwd ();

    if (!chdir $root) {
        print STDERR "make.pm: Cannot change to $root\n";
        return 0;
    }

    my $make_options = "";

    if ($options =~ m/makeopts='(.*?)'/) {
        $make_options = $1;
    }

    my $output = `make $make_options`;

    chdir $current_dir;
    print $output;

    return 1;
}

##############################################################################

main::RegisterCommand ("make", new Make ());
