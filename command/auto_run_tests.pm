#
# $Id$
#

package Auto_Run_Tests;

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
    my $self = {'internal_options' => {'-envmod' => \&Handle_Envmod,
                                      },
               };

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
    my $configs = main::GetVariable ('configs');
    my $sandbox = main::GetVariable ('sandbox');
    my $project_root = main::GetVariable ('project_root');
    my $automake_build = main::GetVariable ('automake_build');

    # replace all '\x22' with '"'
    $options =~ s/\\x22/"/g;

    # Pull out options meant for this module
    my($next) = undef;
    my($remainder) = '';
    foreach my $part (grep(!/^\s*$/,
                           split(/(\"[^\"]+\"|\'[^\']+\'|\s+)/, $options))) {
      # This assumes that all internal options will take only
      # one parameter.
      if (defined $self->{'internal_options'}->{$part}) {
        $next = $part;
      }
      else {
        if (defined $next) {
          # Handle the internal option
          my($func) = $self->{'internal_options'}->{$next};
          $self->$func($part);

          # Undef these so they are not added to the options
          # that get passed to the auto_run_test.pl script.
          $part = undef;
          $next = undef;
        }
      }

      # If this wasn't an internal option or option parameter, put
      # it in the remainder string.
      if (defined $part && !defined $next) {
        $remainder .= $part . ' ';
      }
    }
    $options = $remainder;
    $options =~ s/\s+$//;

    if (!-r $root || !-d $root) {
        mkpath($root);
    }

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    main::PrintStatus ('Test', 'auto_run_tests');

    my $current_dir = getcwd ();

    if (!chdir $root) {
        print STDERR __FILE__, ": Cannot change to $root\n";
        return 0;
    }

    if (!defined $project_root) {
        $project_root = 'ACE_wrappers';
    }

    if (!-r $project_root || !-d $project_root) {
        mkpath($project_root);
    }

    if (!chdir $project_root) {
        print STDERR __FILE__, ": Cannot change to $project_root\n";
        return 0;
    }

    my $autorun_dir = getcwd();

    my $dir;
    if ($options =~ m/dir='([^']*)'/) {
        $dir = $1;
        $options =~ s/dir='$dir'//;
    }
    elsif ($options =~ m/dir=([^\s]*)/) {
        $dir = $1;
        $options =~ s/dir=$dir//;
    }

    my $command;
    if (defined $automake_build) {
      $command = "make -k check";
    }
    else {
      if (defined $sandbox) {
          $options .= " -s $sandbox";
      }

      if (defined $configs) {
          $options .= " -Config " . join (" -Config ", split (' ', $configs));
      }

      $command = "perl $autorun_dir/bin/auto_run_tests.pl $options";
    }

    if (defined $dir) {
        if (!chdir $dir) {
          print STDERR __FILE__, ": Cannot change to $dir\n";
          return 0;
        }
        print "Running: $command in $dir\n";
    }
    else {
        print "Running: $command\n";
    }

    system ($command);
    chdir $current_dir;
    return 1;
}

##############################################################################

sub Handle_Envmod {
  my($self)  = shift;
  my($value) = shift;

  if ($value =~ /(\w+)=(.*)/) {
    $ENV{$1} = $2;
  }
}

##############################################################################

main::RegisterCommand ("auto_run_tests", new Auto_Run_Tests ());
