#

package GIT;

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

    if (!-r $root || !-d $root) {
        mkpath($root);
    }

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    main::PrintStatus ('Setup', 'GIT');

    my $current_dir = getcwd ();

    if (!chdir $root) {
        print STDERR __FILE__, ": Cannot change to $root\n";
        return 0;
    }

    # If dir= is given, extract the dir name, then remove the option from
    # the options string. If no dir is given, just run the command with
    # specified options in $root.
    my $dir;
    if ($options =~ m/(^dir=|\sdir=)([^\s]*)/) {
        $dir = $2;
        $options =~ s/(^dir=|\sdir=)$dir//;
    }
    else {
        $dir = $root;
    }

    if (!chdir $dir) {
        mkpath($dir);
        if(!chdir $dir) {
            print STDERR __FILE__, ": Cannot change to $dir\n";
            return 0;
        }
    }

    my $git_program = main::GetVariable ('git_program');
    if (! defined $git_program) {
        # The "git_program" variable was not defined in the
        # XML config file.  Default to using a program called "git".
        $git_program = "git";
    }

    if ($options =~ m/^clone[\s]+([^\s]+)(.*)$/) {
      # in case of the clone command we attempt to check if the repo
      # has been cloned before (not uncommon for repeatedly executed
      # autobuilds) in which case we turn the clone into a pull
      my $repo_url = $1;
      my $rest_opts = $2;
      my $repo_dir = '';
      my $do_pull = 0;
      # see if repo (sub)dir specified in command
      if ($rest_opts =~ m/\s*([^\s]+)$/) {
        $repo_dir = $1;
      }
      if (-z $repo_dir || !-d "$repo_dir/.git") {
        # check dir name extracted from repo url
        if ($repo_url =~ m/([^\/]+)[\/]?[\.]git$/) {
          $repo_dir = $1;
        } else {
          $repo_url =~ m/(^[\/]+)$/;
          $repo_dir = $1;
        }
        if (-d "$repo_dir/.git") {
          $do_pull = 1;
        }
      } else {
        $do_pull = 1;
      }
      if ($do_pull) {
        if(!chdir $repo_dir) {
            print STDERR __FILE__, ": Cannot change to $repo_dir\n";
            return 0;
        }
        $options = 'pull';
      }
    }

    print "Running: $git_program $options\n";
    my $ret = system ("$git_program $options");
    if ($ret != 0) {
        print STDERR __FILE__, " ERROR: $git_program $options returned $ret\n";
    }

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("git", new GIT ());
