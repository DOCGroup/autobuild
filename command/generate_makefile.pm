#

package Generate_Makefile;

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

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;
    my $options = shift;
    my $root = main::GetVariable ('root');
    my $project_root = main::GetVariable ('project_root');

    if (!-r $root || !-d $root) {
        mkpath($root);
    }

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    main::PrintStatus ('Setup', 'Generate Makefiles');

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
        return 0;
    }

    # If dirs=a[,b...] given, extract the dirs, then remove them from
    # the options string. If no dirs given, just run the command with
    # specified options in $project_root.
    my $dirs;
    if ($options =~ m/dirs=([^\s]*)/) {
        $dirs = $1;
        $options =~ s/dirs=$dirs//;
    }

    my $command = "perl \"$project_root/bin/mpc.pl\" $options";

    if ($dirs) {
        my $dir;
        my @dirlist = split(/,/, $dirs);
        my $this_dir = getcwd ();
        foreach $dir (@dirlist) {
            if (!chdir $dir) {
                print STDERR __FILE__, ": Cannot change to $this_dir/$dir\n";
                return 0;
            }
            print "Running: $command in $dir\n";
            system ($command);
            chdir $this_dir;
        }
    }
    else {
        print "Running: $command\n";
        system ($command);
    }
    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("generate_makefile", new Generate_Makefile ());
