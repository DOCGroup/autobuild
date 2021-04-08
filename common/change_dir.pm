# Helper class to change to a new directory and then restore the original
# directory automatically when the object falls out of scope.
package ChangeDir;

use strict;
use warnings;

use Cwd;

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $args = shift;
    my $self = {
        original_dir => $args->{original_dir} || getcwd (),
        dir => $args->{dir} || main::GetVariable ('root')
    };

    if (!chdir ($self->{dir})) {
        print STDERR __FILE__, ": ",
            "Couldn't change to directory $self->{dir}: $!\n";
        return undef;
    }
    print("===== Changed to ", getcwd (), "\n") if ($main::verbose);

    return bless ($self, $class);
}

sub DESTROY
{
    local($., $@, $!, $^E, $?);
    my $self = shift;
    if ($self->{original_dir} && !chdir ($self->{original_dir})) {
        print STDERR __FILE__, ": ",
            "Couldn't change to original directory $self->{original_dir}: $!\n";
    }
    print("===== Changed back to ", getcwd (), "\n") if ($main::verbose);
};

1;
