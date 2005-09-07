#
# $Id$
#

package WinCEMake;

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

    if (!defined $project_root) {
        $project_root = 'ACE_wrappers';
    }

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

    main::PrintStatus ('Compile', 'wincemake');

    my $current_dir = getcwd ();

    my @dirs;
    my $dir='';
    if ($options =~ m/search='([^']*)'/) {
        $dir = $1;
        @dirs = split(/,/, $1);
    }
    elsif ($options =~ m/search=([^\s]*)/) {
        $dir = $1;
        @dirs = split(/,/, $1);
    }
    $options =~ s/search=$dir//;

    # Allow quoted options to be delimited by ' ' in .xml file; change
    # them back here.
    $options =~ s/'/"/g;

    if (!chdir $root) {
        print STDERR __FILE__, ": Cannot change to $root\n";
        return 0;
    }

    if (!chdir $project_root) {
        print STDERR __FILE__, ": Cannot change to $project_root\n";
        return 0;
    }

    my $basedir = getcwd();
    my $command = "evc $options";

    my $workspace = undef;
    if ($options =~ /"([^"]+\.vcw)"/) {
      $workspace = $1;
    }
    elsif ($options =~ /([\w\\\/]+\.vcw)/) {
      $workspace = $1;
    }

    if (defined $workspace && ! -r $workspace) {
      print "Skipping: $command\n";
    }
    else {
      print "Running: $command\n";

      my $ret = system ($command);

      if ($ret != 0) {
        print "[BUILD ERROR detected in ", getcwd(), "]\n";
      }
    }

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("wincemake", new WinCEMake ());
