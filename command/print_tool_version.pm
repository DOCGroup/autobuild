#
# $Id$
#

package print_tool_version;

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

    $self->{tool} = shift;
    $self->{args} = shift;

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

    main::PrintStatus ('Config', "print " . $self->{tool} . " version" );

    print "<h3>", $self->{tool}, " version (", $self->{tool}, " "
, $self->{args}, ")</h3>\n";
    system($self->{tool} . " " . $self->{args});

    return 1;
}

##############################################################################

main::RegisterCommand ("print_purify_version", new print_tool_version("purify", "-version"));
main::RegisterCommand ("print_quantify_version", new print_tool_version("quantify", "-version"));
main::RegisterCommand ("print_valgrind_version", new print_tool_version("valgrind", "--version"));
main::RegisterCommand ("print_perl_version", new print_tool_version("perl", "-V"));
