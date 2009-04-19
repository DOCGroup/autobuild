#
# $Id$
#

package print_purify_version;

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

    main::PrintStatus ('Config', "print purify version" );

    print "<h3>purify version (purify -version)</h3>\n";
    system("purify -version");

    return 1;
}

##############################################################################

main::RegisterCommand ("print_purify_version", new print_purify_version());
