#
# $Id$
#

package PrintAutobuildConfig;

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
    my $project_root = main::GetVariable ('project_root');
    my $config_path = main::GetVariable ('BUILD_CONFIG_PATH');
    my $config_file = main::GetVariable ('BUILD_CONFIG_FILE');

    my $url = undef;
    main::PrintStatus ('Config', 'PrintAutobuildConfig');

    print "================ Autobuild file $config_path/$config_file ================\n";

    my $current_dir = getcwd ();

    print_file ("$config_path/$config_file", 1);

    chdir $current_dir;

    return 1;
}

##############################################################################

sub print_file ($$)
{
    my $filename = shift;
    my $printall = shift;

    my $filehandle = new FileHandle ($filename, "r");

    while (<$filehandle>) {
        print $_;

        last if ($printall == 0);
    }
}

##############################################################################

main::RegisterCommand ("print_autobuild_config", new PrintAutobuildConfig ());
