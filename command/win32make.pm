#
# $Id$
#

package Win32Make;

use strict;
use warnings;

use Cwd;

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
    
    if (!-r $root || !-d $root) {
        print STDERR __FILE__, ": Cannot access \"root\" directory: $root\n";
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

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    main::PrintStatus ('Compile', 'win32make');

    my $current_dir = getcwd ();

    if (!chdir $root) {
        print STDERR __FILE__, ": Cannot change to $root\n";
        return 0;
    }

    if (!defined $project_root) {
        $project_root = 'ACE_wrappers';
    }
    
    if (!chdir $project_root) {
        print STDERR __FILE__, ": Cannot change to $project_root\n";
        return 0;
    }

    my $command = "perl bin/pippen.pl $options";

    if ($options =~ m/msvc_auto_compile(.*)$/) {
        # override with the old file

        $command = "perl bin/msvc_auto_compile.pl $1";
    }

    print "Running: $command\n";
    system ($command);

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("win32make", new Win32Make ());
