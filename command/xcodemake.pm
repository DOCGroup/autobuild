#

package XcodeMake;

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

    my $command = "xcodebuild $options";

    print "Running: $command\n";

    my $ret = system ($command);

    if ($ret != 0) {
      print "[BUILD ERROR detected in ", getcwd(), "]\n";
    }

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("xcodemake", new XcodeMake ('xcodemake'));
