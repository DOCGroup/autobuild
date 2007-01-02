#
# $Id$
#

package rem_sems;

use strict;
use warnings;

use Cwd;
use File::Path;

sub create ($);
sub clean ($);

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
    if (!defined $ENV{ACE_ROOT}) {
        print STDERR __FILE__,
                    ": Requires \"ACE_ROOT\" environment variable\n";
        return 0;
    }
    
    return 1;
}

##############################################################################
sub Run ($)
{
    my $script = "$ENV{ACE_ROOT}/bin/clean_sems.sh";
    if (! -x $script) {
      print STDERR __FILE__, ": Cannot run $script\n";
      return 0;
    }

    my $status = system ($script);

    return 1;
}

##############################################################################

main::RegisterCommand ("rem_sems", new rem_sems ());
