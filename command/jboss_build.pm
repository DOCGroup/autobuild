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

    if (!defined $project_root) {
        print STDERR __FILE__, ": Requires \"project_root\" variable\n";
        return 0;
    }
    if (!defined $ENV{JAVA_HOME}) {
        print STDERR __FILE__, ": Requires \"JAVA_HOME\" environment variable\n";
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

    my $current_dir = getcwd ();

    my $root_dir;
    if ($options =~ m/root_dir='([^']*)'/) {
        $root_dir = $1;
        $options =~ s/root_dir='$root_dir'//;
    }
    elsif ($options =~ m/root_dir=([^\s]*)/) {
        $root_dir = $1;
        $options =~ s/root_dir=$root_dir//;
    }
    else {
        $root_dir = $project_root;
    }
    
    my $dir;
    if ($options =~ m/dir='([^']*)'/) {
        $dir = $root_dir . "/$1";
        $options =~ s/dir='$dir'//;
    }
    elsif ($options =~ m/dir=([^\s]*)/) {
        $dir = $root_dir . "/$1";
        $options =~ s/dir=$dir//;
    }
    else {
        $dir = $root_dir . "/build";
    }
    
    my $script = "";
    if ($options =~ m/script='([^']*)'/) {
        $script = $1;
        $options =~ s/script='$script'//;
    }
    elsif ($options =~ m/script=([^\s]*)/) {
        $script = $1;
        $options =~ s/script=$script//;
    }

    my $target = "";
    if ($options =~ m/target=\s*'([^']*)'/) {
        $target = $1;
        $options =~ s/target='$target'//;
    }
    elsif ($options =~ m/target=([^\s]*)/) {
        $target = $1;
        $options =~ s/target=$target//;
    }

    if (($dir =~ m/testsuite/) &&
        ($target =~ m/test/)) {
      main::PrintStatus ('Test', 'testsuite');
    }
    else {
      main::PrintStatus ('Compile', 'build');
    }
    
    my $complete_command = $script . " " . $target;
    
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
