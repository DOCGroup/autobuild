#
# $Id$
#

package PrintACEConfig;

use strict;
use warnings;

use FileHandle;
use Time::Local;

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
    if (!-d $root || !-r $root) {
        print STDERR __FILE__, ": Cannot read root: $root\n";
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

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    $root .= '/ACE_wrappers';

    print "\n#################### Config (PrintACEConfig) [" . (scalar gmtime(time())) . " UTC]\n";

    #
    # last ACE Changelog Entry
    #

    if (-r "$root/ChangeLog") {
        print "================ ACE ChangeLog ================\n";
        print_file ("$root/ChangeLog", 0);
    }

    #
    # last TAO Changelog Entry
    #

    if (-r "$root/TAO/ChangeLog") {
        print "================ TAO ChangeLog ================\n";
        print_file ("$root/TAO/ChangeLog", 0);
    }

    #
    # config.h, if it exists
    #

    if (-r "$root/ace/config.h") {
        print "================ config.h ================\n";
        print_file ("$root/ace/config.h", 1);
    }

    #
    # platform_macros.GNU, if it exists
    #

    if (-r "$root/include/makeinclude/platform_macros.GNU") {
        print "================ platform_macros.GNU ================\n";
        print_file ("$root/include/makeinclude/platform_macros.GNU", 1);
    }

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

main::RegisterCommand ("print_ace_config", new PrintACEConfig ());
