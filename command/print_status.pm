#
# $Id$
#

package print_status;

use strict;
use warnings;

use Cwd;
use File::Path;
use Sys::Hostname;

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
    my $options = shift;

    my $section = $var;
    $section =~ s/:.*$//;
    my $description = $var;
    $description =~ s/^.*://;

    main::PrintStatus ($section, $description);

    return 1;
}

##############################################################################

main::RegisterCommand ("print_status", new print_status());
