#
# $Id$
#

package Generate_Workspace;

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
    my $root = main::GetVariable ('root');

    if (!defined $root) {
        print STDERR __FILE__, ": Requires \"root\" variable\n";
        return 0;
    }
    
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
    my $root = main::GetVariable ('root');
    my $project_root = main::GetVariable ('project_root');

    # replace all '\x22' with '"'
    $options =~ s/\\x22/"/g;

    if (!-r $project_root || !-d $project_root) {
        mkpath($project_root);
    }

    if (!-r $root || !-d $root) {
        mkpath($root);
    }

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    main::PrintStatus ('Setup', 'Generate Workspaces');

    my $current_dir = getcwd ();

    if (!chdir $root) {
          print STDERR __FILE__, ": Cannot change to $root\n";
          return 0;
    }

    if (!chdir $ENV{'ACE_ROOT'} )
    {
        if (!defined $project_root) {
            $project_root = 'ACE_wrappers';
        }

        if (!chdir $project_root) {
            print STDERR __FILE__, ": Cannot change to $project_root or $ENV{'ACE_ROOT'}\n";
            return 0;
        }
    }

    # If dirs=a[,b...] given, extract the dirs, then remove them from
    # the options string. If no dirs given, just run the command with
    # specified options in $root.
    my $dirs;
    if ($options =~ m/dirs=([^\s]*)/) {
        $dirs = $1;
        $options =~ s/dirs=$dirs//;
    }

    my $command = "perl bin/mwc.pl $options";

# The idea here is to do a find at the specified dirs looking for .mwc files
# and run mwc on each. For now, all the mwc files have to be specified
# directly in the options.
#    if ($dirs) {
#        my $dir;
#        my @dirlist = split(/,/, $dirs);
#        foreach $dir (@dirlist) {
#            if (!chdir $dir) {
#                print STDERR __FILE__, ": Cannot change to $root/$dir\n";
#                return 0;
#            }
#            print "Running: $command in $dir\n";
#            system ($command);
#            chdir $root;
#        }
#    }
#    else {
        print "Running: $command\n";
        system ($command);
#    }
    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("generate_workspace", new Generate_Workspace ());
