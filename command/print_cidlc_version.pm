#
# $Id$
#

package print_cidlc_version;

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

    my $cidlc_program = "ACE_wrappers/TAO/CIAO/bin/cidlc";

    main::PrintStatus ('Config', "print cidlc version" );

    print "<h3>cidlc version (";
    print $cidlc_program;
    print " --version)</h3>\n";

    my $command = "$cidlc_program --version";

    system($command);

    return 1;
}

##############################################################################

main::RegisterCommand ("print_cidlc_version", new print_cidlc_version());
