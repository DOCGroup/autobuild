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

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;
    my $compiler = shift;

    main::PrintStatus ('Config', "check compiler $compiler" );

    print "================ Compiler version ================\n";

    if($compiler =~ m/^(gcc|g\+\+|g\+\+-?[0-9]|ccsimpc)/){
        system($compiler." -v 2>&1");
      if($compiler =~ m/^(gcc|g\+\+|g\+\+-?[0-9])/){
          my $linker = `$compiler -print-prog-name=ld`;
          chomp $linker;
          if($linker eq "ld"){
              system($linker." -v 2>&1");
          }
          elsif($linker =~ m/ccs/){
              system($linker." -V 2>&1");
          }
      }
    }
    elsif(lc $compiler eq "sun_cc"){
        system("CC -V");
    }
    elsif(lc $compiler eq "mingwcygwin"){
        system("g++ -v -mno-cygwin");
    }
    elsif(lc $compiler eq "borland"){
	system("bcc32 -V");
    }
    elsif(lc $compiler eq "cbx"){
	system("bccx --version");
    }
    elsif(lc $compiler eq "kylix"){
	system("bc++ -V");
    }
    elsif($compiler =~ m/^(dcc|dplus)/){
	system($compiler . " -V");
    }
    elsif(lc $compiler eq "dm"){
	system("scppn");
    }
    elsif(lc $compiler eq "msvc"){
        system("cl /V");
    }
    elsif(lc $compiler eq "deccxx"){
        system("cxx/VERSION");
    }
    elsif(lc $compiler eq "cxx"){
        system("cxx -V");
    }
    elsif(lc $compiler eq "acc"){
        system("aCC -V");
    }
    elsif(lc $compiler eq "pgcc"){
        system("pgCC -V");
    }
    elsif(lc $compiler eq "mipspro"){
        system("CC -version");
    }
    elsif(lc $compiler eq "doxygen"){
        system("doxygen --version");
    }
    elsif($compiler =~ m/^(ecc|icc)/){
        system($compiler." -V 2>&1");
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
