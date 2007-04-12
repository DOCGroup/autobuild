#
# $Id$
#

package Process_Listener;

use strict;
use warnings;

use IO::Socket;

#use Cwd;
#use File::Find;
#use File::Path;

###############################################################################
# Constructor

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {'sockets' => []};

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
    my $self = shift;
    my $options = shift;

    if ($main::verbose == 1) {
        main::PrintStatus ('Setup', 'Process_Listener');
    }

    if (defined $options && $options =~ m/^([^:]+):(\d+)/) {
        my $host   = $1;
        my $port   = $2;
        my $socket = IO::Socket::INET->new(LocalAddr => $host,
                                           LocalPort => $port,
                                           Listen    => 10,
                                           Proto     => 'tcp',
                                           Type      => SOCK_STREAM,
                                          );
        if (defined $socket) {
          ## Save the socket so it stays open
          push(@{$self->{'socket'}}, $socket);
        }
        else {
            print STDERR __FILE__, ": $host", ":$port is already in use\n";
            return 0;
        }
    }
    else {
        print STDERR __FILE__, ": No host:port specified in command options\n";
        return 0;
    }

    return 1;
}

##############################################################################

main::RegisterCommand ("process_listener", new Process_Listener ());
