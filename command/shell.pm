#
# $Id$
#

package Shell;

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
    
    # No requirements

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;
    my $options = shift;

    print "\n#################### Setup (Shell) \n\n";

    my $output = `$options`;

    print $output;

    return 1;
}

##############################################################################

main::RegisterCommand ("shell", new Shell ());
