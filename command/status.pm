#
# $Id$
#

package Status;

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

    $self->{INIT} = 0;

    bless ($self, $class);
    return $self;
}

##############################################################################

sub CheckRequirements ()
{
    my $self = shift;
    my $log_root = main::GetVariable ('log_root');

    if (!defined $log_root) {
        print STDERR __FILE__, ": Requires \"log_root\" variable\n";
        return 0;
    }

    if (!-r $log_root || !-d $log_root) {
        print STDERR __FILE__, ": Cannot access \"log_root\" directory: $log_root\n";
        return 0;
    }

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;
    my $options = shift;
    my $log_root = main::GetVariable ('log_root');

    # chop off trailing slash
    if ($log_root =~ m/^(.*)\/$/) {
        $log_root = $1;
    }

    if ( $main::verbose == 1 ) {
        main::PrintStatus ('Setup', 'Status');
    }

    if (uc $options eq "ON") {
        main::SetStatusFile ($log_root . "/status.txt");
    }
    elsif (uc $options eq "OFF") {
        main::ChangeStatus ('Inactive', '');
        main::SetStatusFile ('');
    }

    return 1;
}

##############################################################################

main::RegisterCommand ("status", new Status ());
