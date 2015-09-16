#

package Quickfast_Auto_Run_Tests;

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

    main::PrintStatus ('Test', 'auto_run_tests');

    my $current_dir = getcwd ();

    if (!-r $project_root || !-d $project_root) {
        mkpath($project_root);
    }

    if (!chdir $project_root) {
        print STDERR __FILE__, ": Cannot change to $project_root\n";
        return 0;
    }

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
    if ($options =~ m/command='([^']*)'/) {
        $command = $1;
        $options =~ s/command='$command'//;
    }
    elsif ($options =~ m/command=([^\s]*)/) {
        $command = $1;
        $options =~ s/command=$command//;
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

main::RegisterCommand ("quickfast_auto_run_tests", new Quickfast_Auto_Run_Tests ());
