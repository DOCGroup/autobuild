#
# $Id$
#

package print_make_version;

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

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;

    my $make_program = main::GetVariable ('make_program');
    if (! defined $make_program) {
        # The "make_program" variable was not defined in the
        # XML config file.  Default to using a program called "make".
        $make_program = "make"
    }

    main::PrintStatus ('Config', "print make Version" );

    print "<h3>Make version (";
    print $make_program;
    print " -v)</h3>\n";

    my $command = "$make_program -v";

    system($command);

    return 1;
}

##############################################################################

main::RegisterCommand ("print_make_version", new print_make_version());
