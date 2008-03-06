# $Id$

package command::Process::Process;

use strict;
use Win32::Process;

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

    # First, try to separate process name and command-line options
    $options=~ /\s*(\\".*\\"|\S*)(.*)/;
    my $cmd= $1;
    my $cmd_options= $2;

    # Create process
    my $ProcessObj;
    Win32::Process::Create($ProcessObj, $cmd, $cmd_options, 0, NORMAL_PRIORITY_CLASS, ".");
    my $pid = $ProcessObj->GetProcessID();
    $pid;
}

sub Kill ()
{
    my $self = shift;    
    my ($pid) = @_;

    Win32::Process::KillProcess($pid, 0);
}

1;
