#
# $Id$
#

package check_compiler;

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
    my $compiler = shift;

    main::PrintStatus ('Config', "check compiler $compiler" );

    print "================ Compiler version ================\n";

    if(lc $compiler eq "gcc"){
        system("gcc -v 2>&1");
    }

    if(lc $compiler eq "sun_cc"){
        system("CC -V");
    }
    return 1;
}

##############################################################################

main::RegisterCommand ("check_compiler", new check_compiler());
