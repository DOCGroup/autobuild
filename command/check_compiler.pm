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

    if($compiler =~ m/^(gcc|g\+\+)/){
        system($compiler." -v 2>&1");
    }
    elsif(lc $compiler eq "sun_cc"){
        system("CC -V");
    }
    elsif(lc $compiler eq "borland"){
	system("bcc32 -V"); 
    }
    elsif(lc $compiler eq "msvc"){
        system("cl /V");
    }
    elsif(lc $compiler eq "cxx"){
        system("cxx -V"); 
    }
    elsif(lc $compiler eq "acc"){
        system("aCC -V"); 
    }
    elsif($compiler =~ m/^(ibmcxx)/i ){
        if(-x "/usr/bin/lslpp"){
           system("/usr/bin/lslpp -l ibmcxx.cmp | grep ibmcxx.cmp");
        }else {
           print "ERROR: Could not find /usr/bin/lslpp!!\n";
        }
    }
    elsif($compiler =~ m/^(vacpp)/i ){
        if(-x "/usr/bin/lslpp"){
           system("/usr/bin/lslpp -l vacpp.cmp.core | grep vacpp.cmp.core");
        }else {
           print "ERROR: Could not find /usr/bin/lslpp!!\n";
        }
    }
    else{
        print "ERROR: I cannot figure out what compiler you are ";
        print "using!!\nSee check_compiler.pm for more details.\n"; 
    }
    return 1;
}

##############################################################################

main::RegisterCommand ("check_compiler", new check_compiler());
