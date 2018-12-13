# Print CMake Version
# Uses same cmake_command variable as the cmake command

package print_cmake_version;

use strict;
use warnings;

use Cwd;

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

    main::PrintStatus ('Config', "print CMake Version" );

    print "<h3>CMake version ($cmake_command)</h3>\n";

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

main::RegisterCommand ("print_cmake_version", new print_cmake_version());