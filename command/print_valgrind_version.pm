#
# $Id$
#

package print_valgrind_version;

use strict;
use warnings;

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

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;

    main::PrintStatus ('Config', "print valgrind version" );

    print "<h3>Valgrind version (valgrind --version)</h3>\n";
    system("valgrind --version");

    return 1;
}

##############################################################################

main::RegisterCommand ("print_valgrind_version", new print_valgrind_version());
