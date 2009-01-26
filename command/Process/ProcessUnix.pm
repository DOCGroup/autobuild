# $Id$

package command::Process::Process;

use strict;
use POSIX "sys_wait_h";
use Cwd;
use File::Basename;
use Config;

### Constructor and Destructor

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {};

    bless ($self, $class);
    return $self;
}

sub Spawn ()
{
    my $self = shift;
    my ($options) = @_;
    my $pid = 0;

    # attempt to run 
    FORK:
    {
        my $id;
        if ($id = fork) {
            #parent here
            $pid = $id;
        }
        elsif (defined $id) {
            #child here
            exec $options;
            die "ERROR: exec failed for <" . $options . ">";
        }
        elsif ($! =~ /No more process/) {
            #EAGAIN, supposedly recoverable fork error
            sleep 5;
            redo FORK;
        }
        else {
            # weird fork error
            print STDERR "ERROR: Can't fork <" . $options . ">: $!\n";
        }
    }    
    $pid;
}

sub Kill ()
{
    my $self = shift;    
    my ($pid) = @_;

    kill 9, $pid;
}

1;
