#
# $Id$
#

package rem_sems;

use strict;
use warnings;

use Cwd;
use File::Path;

sub create ($);
sub sam ($);
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
    my $self = shift;
    my $root = main::GetVariable ('root');

    if (!defined $root) {
        print STDERR __FILE__, ": Requires \"root\" variable\n";
        return 0;
    }
    
    return 1;
}

##############################################################################
sub Run ($)
{
    my $root = main::GetVariable ('root');
    
    if (!-r $root || !-d $root) {
        print STDERR __FILE__, ": Cannot access \"root\" directory: $root\n";
        return 0;
    }

    my $current_dir = getcwd ();

    if (!chdir $root) {
      print STDERR __FILE__, ": Cannot change to $root\n";
      return 0;
    }

    my $location = "ACE_wrappers/bin/";
    if (!chdir $location) {
      print STDERR __FILE__, ": Cannot change to $location\n";
      return 0;
    }

    my $status = system ("./clean_sems.sh");

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("rem_sems", new rem_sems ());
