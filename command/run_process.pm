#
# $Id$
#

package RUN_PROCESS;

use strict;
use warnings;

use Cwd;
use FileHandle;
use File::Path;
use command::Process::Process;

# global variable - hash of all running processes
my %running_processes = ();

###############################################################################
# Constructor

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {'substitute_vars_in_options' => 1};

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
    my $root = main::GetVariable ('root');

    my $mode = "run";
    my $index = 0;

    # Check do we need to start or stop the process
    if ($options=~ m/run=(\'[^\']*\'|[^\s]*)/) {
        $index= $1;
        $options=~ s/run=$index//;    # Remove what was found from options
        $mode = "run"
    } elsif ($options=~ m/kill=(\'[^\']*\'|[^\s]*)/) {
        $index= $1;
        $options=~ s/kill=$index//;    # Remove what was found from options
        $mode = "kill";        
    }

    my $process = new command::Process::Process;

    if ($mode eq "run") {
        # chop off trailing    slash
        if ($root =~ m/^(.*)\/$/) {
                $root = $1;
        }

        my $current_dir = getcwd ();

        if (!chdir $root) {
            print STDERR __FILE__, ": Cannot change    to $root\n";
            return 0;
        }

        # See if we should change directory before the doing the run_process itself
        if ($options=~ m/cd=(\'[^\']*\'|[^\s]*)/) {
            my $dir= $1;
            $options=~ s/cd=$dir//;            # Remove what was found    from options
            $dir=~ s/\'([^\']*)\'/$1/;        # Remove quotes    if given
            if (!chdir $dir) {
                print STDERR __FILE__, ": Cannot change    to $dir\n";
                return 0;
            }
        }

        my $pid = $process->Spawn($options);
        if (0 == $pid) {
          print "Failed to start process \"$index\", Command \"$options\"\n";
        }
        else {
          # wait until process starts
          sleep (5);

          # Save running process ID in the global hash table
          $running_processes{$index} = $pid;

          print "Started process \"$index\", Command \"$options\" (PID=$pid)\n";
        }

        # Restore current directory.
        chdir $current_dir;

    } elsif ($mode eq "kill") {
        # Need to kill running process
        my $pid = 0;

        if (exists $running_processes{$index}) {
            $pid = $running_processes{$index};

            print "Killing process \"$index\" (PID=$pid)\n";

            $process->Kill($pid);
        }
    } else {
        print "Unknown run_process \"$options\"\n";
    }

    return 1;
}

##############################################################################

main::RegisterCommand ("run_process", new RUN_PROCESS ());
