#

package VC7Make;

use strict;
use warnings;

use Cwd;
use File::Path;

use common::utility;

###############################################################################
# Constructor

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {};

    $self->{type} = shift;

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
    my $vctool = main::GetVariable ('vctool');

    if (!-r $root || !-d $root) {
        mkpath($root);
    }

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    main::PrintStatus ('Compile', $self->{type});

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

    if (!chdir $root) {
        print STDERR __FILE__, ": Cannot change to $root\n";
        return 0;
    }

    if (!defined $project_root) {
        $project_root = $ENV{ACE_ROOT};
    }

    if (!-r $project_root || !-d $project_root) {
        mkpath($project_root);
    }

    if (!chdir $project_root) {
        print STDERR __FILE__, ": Cannot change to $project_root\n";
        return 0;
    }

    if (!defined $vctool) {
        $vctool = 'devenv.com';
    }

    my $command = "$vctool $options";

    my $workspace = undef;
    if ($options =~ /"([^"]+\.sln)"/) {
      $workspace = $1;
    }
    elsif ($options =~ /([\w\.\-\\\/]+\.sln)/) {
      $workspace = $1;
    }

    my $ret = 1;
    if (defined $workspace && ! -r $workspace) {
      print "Skipping: $workspace not found\n";
    }
    else {
      print "Running: $command\n";

      my $ret = utility::run_command ($command);

      if (!$ret) {
        print STDERR "[BUILD ERROR detected in ", getcwd(), "]\n";
      }
    }

    chdir $current_dir;

    return $ret;
}

##############################################################################

main::RegisterCommand ("vc7make", new VC7Make ('vc7make'));
main::RegisterCommand ("vc71make", new VC7Make ('vc71make'));
main::RegisterCommand ("vc8make", new VC7Make ('vc8make'));
main::RegisterCommand ("vc9make", new VC7Make ('vc9make'));
main::RegisterCommand ("vc10make", new VC7Make ('vc10make'));
