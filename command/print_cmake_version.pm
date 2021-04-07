# Print CMake Version
# Uses same cmake_command variable as the cmake command

package print_cmake_version;

use strict;
use warnings;

use Cwd;

use common::utility;

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

    my $cmake_command = main::GetVariable ('cmake_command');
    $cmake_command .= " --version";

    main::PrintStatus ('Config', "print CMake Version");

    print "<h3>CMake version ($cmake_command)</h3>\n";

    return utility::run_command ($cmake_command);
}

##############################################################################

main::RegisterCommand ("print_cmake_version", new print_cmake_version());
