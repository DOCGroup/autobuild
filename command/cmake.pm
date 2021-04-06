# CMake Command Wrapper
#
# Contains the cmake and cmake_cmd commands
#
# Configure and build a CMake project in one command. See docs/autobuild.txt
# for usage.

package Cmake;

use strict;
use warnings;

use common::utility;
use common::change_dir;

###############################################################################
# Constructor

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $args = shift;
    my $self = {
        simple => $args->{simple} || 0,
    };

    return bless ($self, $class);
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
    my $args = shift;

    my $command_name = $self->{simple} ? "cmake_cmd" : "cmake";

    # Get cmake_var_* Autobuild Variables
    my @cmake_vars = ();
    my $autobuild_var_cmake_var_re = qr/^cmake_var_(\w+)$/;
    my $autobuild_var_cmake_vars = main::GetVariablesMatching ($autobuild_var_cmake_var_re);
    for my $i (@{$autobuild_var_cmake_vars}) {
        my ($raw_name, $value) = @{$i};
        $raw_name =~ $autobuild_var_cmake_var_re;
        push (@cmake_vars, [$1, $value]);
    }

    # Get Args
    my $build_dir = "build";
    my $config_args = "..";
    my $build_args = "--build .";
    my $arg_cmake_var_re = qr/^var_(\w+)$/;
    for my $i (@{$args}) {
        my ($name, $value) = @{$i};
        if (!$self->{simple} && $name eq 'build_dir') {
            $build_dir = $value;
        }
        elsif (!$self->{simple} && $name eq 'config_args') {
            $config_args = $value;
        }
        elsif (!$self->{simple} && $name eq 'build_args') {
            $build_args = $value;
        }
        elsif (!$self->{simple} && $name =~ $arg_cmake_var_re) {
            $name =~ $arg_cmake_var_re;
            $name = $1;
            # Override existing value
            @cmake_vars = grep {$_->[0] ne $name} @cmake_vars;
            push (@cmake_vars, [$name, $value]);
        }
        else {
            print STDERR __FILE__,
                ": unexpected arg name \"$name\" in $command_name command\n";
            return 0;
        }
    }

    my $cmake_command = main::GetVariable ('cmake_command');
    my $cmake_generator = main::GetVariable ('cmake_generator');
    if (defined $cmake_generator && $config_args !~ /\W-G\W/) {
        $config_args .= " -G \"$cmake_generator\"";
    }

    # cmake_cmd commmand
    if ($self->{simple}) {
        return utility::run_command ("$cmake_command $options");
    }
    elsif (length ($options)) {
        print STDERR __FILE__,
            ": options attribute not allowed for the cmake command\n";
        return 0;
    }

    # Insert cmake_var_* Autobuild Variables and var_* Arguments
    for my $i (@cmake_vars) {
        my ($name, $value) = @{$i};
        if ($config_args !~ /-D\W*$name/) {
            $config_args .= " -D \"$name=$value\"";
        }
    }

    # Recreate Build Directory
    if (!utility::remove_tree ($build_dir)) {
        return 0;
    }
    if (!mkdir ($build_dir)) {
        print STDERR __FILE__, ": failed to make build directory \"$build_dir\": $!\n";
        return 0;
    }

    {
        # Change to Build Directory
        my $build_cd = ChangeDir->new({dir => $build_dir});
        return 0 unless ($build_cd);

        # Run Configure CMake Command
        if (!utility::run_command ("$cmake_command $config_args")) {
            return 0;
        }

        # Run Build CMake Command
        if (!utility::run_command ("$cmake_command $build_args")) {
            return 0;
        }
    }

    return 1;
}

##############################################################################

main::RegisterCommand ("cmake", new Cmake ());
main::RegisterCommand ("cmake_cmd", new Cmake ({simple => 1}));
