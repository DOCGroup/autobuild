# CMake Command Wrapper
# Uses same cmake_command variable as print_cmake_version
# Also uses cmake_generator variable which is passed to CMake using the -G
# option as long --build hasn't been passed

package Cmake;

use strict;
use warnings;

use Cwd;
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

    my $cmake_command = main::GetVariable ('cmake_command');
    if (!defined $cmake_command) {
        main::SetVariable ('cmake_command', 'cmake');
    }

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;
    my $options = shift;

    my $cmake_command = main::GetVariable ('cmake_command');
    my $cmake_generator = main::GetVariable ('cmake_generator');
    if (defined $cmake_generator and $options !~ /--build/) {
        $cmake_command .= " -G \"$cmake_generator\"";
    }
    $cmake_command .= " $options";

    my $cwd = getcwd ();
    print "Running: ${cmake_command} in $cwd\n";

    system ($cmake_command);
    if ($?) {
        print STDERR __FILE__, ": " .
            "CMake Command \"$cmake_command\"" . ($? == -1 ?
                "Could not be Run (Missing?)\n" : "Failed with Status $?\n");
        return 0;
    }

    return 1;
}

##############################################################################

main::RegisterCommand ("cmake", new Cmake ());
