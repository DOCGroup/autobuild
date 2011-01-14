#
# $Id$
#

package JBoss_Build;

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
    my $jboss_root = main::GetVariable ('JBOSS_ROOT');
    my $java_home = main::GetVariable ('JAVA_HOME');

    if (!defined $project_root) {
        print STDERR __FILE__, ": Requires \"project_root\" variable\n";
        return 0;
    }
    if (!defined $jboss_root) {
        print STDERR __FILE__, ": Requires \"JBOSS_ROOT\" variable\n";
        return 0;
    }
    if (!defined $java_home) {
        print STDERR __FILE__, ": Requires \"JAVA_HOME\" variable\n";
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
    my $jboss_root = main::GetVariable ('JBOSS_ROOT');

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

    main::PrintStatus ('Compile', 'build');

    my $current_dir = getcwd ();

    my $dir;
    if ($options =~ m/dir='([^']*)'/) {
        $dir = $1;
        $options =~ s/dir='$dir'//;
    }
    elsif ($options =~ m/dir=([^\s]*)/) {
        $dir = $1;
        $options =~ s/dir=$dir//;
    }
    else {
        $dir = $project_root . "/build";
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

    my $script;
    if ($options =~ m/script='([^']*)'/) {
        $script = $1;
        $options =~ s/script='$script'//;
    }
    elsif ($options =~ m/script=([^\s]*)/) {
        $script = $1;
        $options =~ s/script=$script//;
    }

    my $target;
    if ($options =~ m/target='([^']*)'/) {
        $target = $1;
        $options =~ s/target='$target'//;
    }
    elsif ($options =~ m/target=([^\s]*)/) {
        $target = $1;
        $options =~ s/target=$target//;
    }
    
    my $complete_command = $command . " " . $script . " " . $target;
    
    if (!chdir $dir) {
      print STDERR __FILE__, ": Cannot change to $dir\n";
      return 0;
    }
    print "Running: \"$complete_command\" in $dir\n";
    system ($complete_command);
    chdir $current_dir;
    return 1;
}

##############################################################################

main::RegisterCommand ("jboss_build", new JBoss_Build ());