#
# $Id$
#

package check_linker;

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
    my $linker = shift;

    main::PrintStatus ('Config', "check linker $linker" );

    print "================ Linker version ================\n";
    if(lc $linker eq "ld"){
        system("ld -v");
    }
    elsif(lc $linker eq "ilink32"){
        system("ilink32 -v");
    }
    elsif(lc $linker eq "ilink"){
        system("ilink -v");
    }
    else{
        print "ERROR: I cannot figure out what linker you are ";
        print "using!!\nSee check_linker.pm for more details.\n"; 
    }
    return 1;
}

##############################################################################

main::RegisterCommand ("check_linker", new check_linker());
