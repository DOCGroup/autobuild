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
    my $project_root = main::GetVariable ('project_root');
    my $base = main::GetVariable ('base') || 'ACE_wrappers';
    my $custom_mwcdir = main::GetVariable ('mwcdir');

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

    if (!defined $project_root) {
        $project_root = $base;
    }

    if (!-r $project_root || !-d $project_root) {
        mkpath($project_root);
    }

    if (!chdir $project_root )
    {
        if (!chdir $ENV{'ACE_ROOT'}) {
            print STDERR __FILE__, ": Cannot change to $project_root or $ENV{'ACE_ROOT'}\n";
            return 0;
        }
    }

    my $this_dir = getcwd ();

    # If dirs=a[,b...] given, extract the dirs, then remove them from
    # the options string. If no dirs given, just run the command with
    # specified options in $root.
    my $dirs;
    if ($options =~ m/dirs=([^\s]*)/) {
        $dirs = $1;
        $options =~ s/\Qdirs=$dirs\E//;
    }

    ## Get the location of the mwc.pl script
    my $mwc = undef;
    if (defined $custom_mwcdir && -r "$custom_mwcdir/mwc.pl") {
      $mwc = "$custom_mwcdir/mwc.pl";
    } else {
      my @mwcdirs = ("$this_dir/bin", $ENV{MPC_ROOT});
      splice @mwcdirs, 1, 0, "$ENV{ACE_ROOT}/bin" if defined $ENV{ACE_ROOT};
      foreach my $mwcdir (@mwcdirs) {
        if (defined $mwcdir && -r "$mwcdir/mwc.pl") {
          $mwc = "$mwcdir/mwc.pl";
          last;
        }
      }
    }
    if (!defined $mwc) {
      print STDERR __FILE__, ": Cannot find mwc.pl\n";
      return 0;
    }

    ## Create the MPC command line
    my $command = "perl \"$mwc\" $options";

    if ($dirs) {
        my $dir;
        my @dirlist = split(/,/, $dirs);
        foreach $dir (@dirlist) {
            if (!chdir $dir) {
                print STDERR __FILE__, ": Cannot change to $this_dir/$dir\n";
                return 0;
            }
            print "Running: $command in $this_dir/$dir\n";
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

main::RegisterCommand ("generate_workspace", new Generate_Workspace ());
