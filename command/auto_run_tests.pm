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
    my $configs = main::GetVariable ('configs');
    my $sandbox = main::GetVariable ('sandbox');
    my $project_root = main::GetVariable ('project_root');

    # replace all '\x22' with '"'
    $options =~ s/\\x22/"/g;

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

    my $dir;
 
    if ($options =~ m/dir='([^']*)'/) {
        $dir = $1;
        $options =~ s/dir='$dir'//;
    }
    elsif ($options =~ m/dir=([^\s]*)/) {
        $dir = $1;
        $options =~ s/dir=$dir//;
    }

    if (defined $sandbox) {
        $options .= " -s $sandbox";
    }

    if (defined $configs) {
        $options .= " -Config " . join (" -Config ", split (' ', $configs));
    }

    if (defined $dir) {
        if (!chdir $dir) {
          print STDERR __FILE__, ": Cannot change to $dir\n";
          return 0; 
        }
    }

    my $command = "perl bin/auto_run_tests.pl $options";

    print "Running: $command\n";
    system ($command);

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("auto_run_tests", new Auto_Run_Tests ());
