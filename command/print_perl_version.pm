#
# $Id$
#

package print_perl_version;

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

    main::PrintStatus ('Config', "print Perl Version" );

    print "<h3>Perl version (perl -V)</h3>\n";
    system("perl -V");

    return 1;
}

##############################################################################

main::RegisterCommand ("print_perl_version", new print_perl_version());
