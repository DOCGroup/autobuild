#
# $Id$
#

package Win32Make;

use strict;
use warnings;

use Cwd;
use File::Path;

###############################################################################
# Constructor

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = { 'substitute_vars_in_options' => 1 };

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
    my $project_root = main::GetVariable ('project_root');
    my $dir;

    if ($options =~ s/dir='([^']*)'//) {
        $dir = $1;
    }
    elsif ($options =~ s/dir=([^\s]*)//) {
        $dir = $1;
    }

    if (defined $dir) {
        $project_root = $dir;
    }

    if (!-r $root || !-d $root) {
        mkpath($root);
    }

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    main::PrintStatus ('Compile', 'win32make');

    my $current_dir = getcwd ();

    if (!chdir $root) {
        print STDERR __FILE__, ": Cannot change to $root\n";
        return 0;
    }

    if (!defined $project_root) {
        $project_root = $ENV{ACE_ROOT};
    }

    if (!-r $project_root || !-d $project_root) {
        mkpath($project_root);
    }

    if (!chdir $project_root) {
        print STDERR __FILE__, ": Cannot change to $project_root\n";
        if ($options =~ m/(\-clean|REALCLEAN)/) {
          # in the 'clean' step just ignore the $project_root is not there
          # checkout will follow and probably rebuild all
          chdir $current_dir;
          return 1;
        }
        else {
          return 0;
        }
    }

    my $command = "perl bin/pippen.pl $options";

    if ($options =~ m/msvc_mpc_auto_compile(.*)$/) {
        # override with the old file
        $command = "perl bin/msvc_mpc_auto_compile.pl $1";
    } elsif ($options =~ m/msvc_static_compile(.*)$/) {
        # override with the old file
        $command = "perl bin/msvc_static_compile.pl $1";
    } elsif ($options =~ m/msvc_cidlc (.*)$/) {
        # override with the old file
        $command = "perl bin/msvc_cidlc.pl $1";
    }
    else {
        # allow an arbitrary command
        $command = "$options";
    }

    print "Running: $command\n";
    system ($command);

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("win32make", new Win32Make ());
