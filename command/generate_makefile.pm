#
# $Id$
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

    my $project_root = main::GetVariable ('project_root');

    if (!defined $project_root) {
        print STDERR __FILE__, ": Requires \"project_root\" variable\n";
        return 0;
    }

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;
    my $options = shift;
    my $project_root = main::GetVariable ('project_root');

    # replace all '\x22' with '"'
    $options =~ s/\\x22/"/g;

    if (!-r $project_root || !-d $project_root) {
        mkpath($project_root);
    }

    # chop off trailing slash
    if ($project_root =~ m/^(.*)\/$/) {
        $project_root = $1;
    }

    main::PrintStatus ('Setup', 'Generate Makefiles');

    my $current_dir = getcwd ();

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

    my $command = "perl $project_root/bin/mpc.pl $options";

    if ($dirs) {
        my $dir;
        my @dirlist = split(/,/, $dirs);
        foreach $dir (@dirlist) {
            if (!chdir $dir) {
                print STDERR __FILE__, ": Cannot change to $project_root/$dir\n";
                return 0;
            }
            print "Running: $command in $dir\n";
            system ($command);
            chdir $project_root;
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
