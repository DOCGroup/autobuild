#
# $Id$
#

package SetEnv;

use strict;
use warnings;

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

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;
    my $options = shift;

    main::PrintStatus ('Setup', 'setenv');

    print "Running setenv: ${options}\n";

    if ($options =~ /(\w+)=(.*)/) {
      $ENV{$1} = $2
    }

    return 1;
}

##############################################################################

main::RegisterCommand ("setenv", new SetEnv ());
