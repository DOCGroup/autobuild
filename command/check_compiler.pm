#

package check_compiler;

use strict;
use warnings;

use Cwd;

use common::utility;

###############################################################################
# Constructor

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {
      'required_by_default' => 1,
    };

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

    if (!defined $compiler || $compiler eq "") {
      $compiler = main::GetVariable ('the_compiler');
    }

    main::PrintStatus ('Config', "check compiler $compiler" );

    print "================ Compiler version ================\n";

    if ($compiler =~ m/^(\w*-)*(gcc|g\+\+|clang|ccsimpc|(cc|c\+\+)(pentium|ppc))/) {
        if (!utility::run_command ("$compiler -v 2>&1")) {
            return 0;
        }
        if ($compiler =~ /^(\w*-)*(gcc|g\+\+|clang)/) {
            my $linker = `$compiler -print-prog-name=ld`;
            chomp $linker;
            if ($linker =~ m/ld$/) {
                return utility::run_command ($linker." -v 2>&1");
            }
            elsif ($linker =~ m/ccs/) {
                return utility::run_command ($linker." -V 2>&1");
            }
            else {
                print STDERR __FILE__, ": ERROR: Unexpected Linker: $linker\n";
            }
        }
    }
    elsif (lc $compiler =~ m/^(sun_cc|studio|suncc)/) {
        return utility::run_command ("CC -V");
    }
    elsif (lc $compiler eq "mingwcygwin") {
        return utility::run_command ("g++ -v -mno-cygwin");
    }
    elsif (lc $compiler =~ m/^(bcc(.*))$/) {
        return utility::run_command ("$1 --version");
    }
    elsif (lc $compiler eq "kylix") {
        return utility::run_command ("bc++ -V");
    }
    elsif ($compiler =~ m/^(dcc|dplus)/) {
        return utility::run_command ($compiler . " -V");
    }
    elsif (lc $compiler eq "dm") {
        return utility::run_command ("scppn");
    }
    elsif (lc $compiler =~ m/^(msvc|vc|cl)/) {
        return utility::run_command ("cl");
    }
    elsif (lc $compiler eq "deccxx") {
        return utility::run_command ("cxx/VERSION");
    }
    elsif (lc $compiler eq "cxx") {
        return utility::run_command ("cxx -V");
    }
    elsif (lc $compiler eq "acc") {
        return utility::run_command ("aCC -V");
    }
    elsif (lc $compiler eq "pgcc") {
        return utility::run_command ("pgCC -V");
    }
    elsif (lc $compiler eq "mipspro") {
        return utility::run_command ("CC -version");
    }
    elsif (lc $compiler eq "doxygen") {
        return utility::run_command ("doxygen --version");
    }
    elsif ($compiler =~ m/^(ecc|icc|icpc)/) {
        return utility::run_command ("$compiler -V 2>&1");
    }
    elsif (lc $compiler eq "icl") {
        return utility::run_command ("icl");
    }
    elsif ($compiler =~ m/^(ibmcxx)/i) {
        if (-x "/usr/bin/lslpp") {
            return utility::run_command ("/usr/bin/lslpp -l ibmcxx.cmp | grep ibmcxx.cmp");
        }
        else {
            print STDERR __FILE__, ": " .
                "ERROR: Could not find /usr/bin/lslpp!!\n";
        }
    }
    elsif ($compiler =~ m/^(vacpp)/i) {
        if (-x "/usr/bin/lslpp") {
            return utility::run_command ("/usr/bin/lslpp -l | grep -i \'C++ Compiler\'");
        }
        else {
            print STDERR __FILE__, ": " .
                "ERROR: Could not find /usr/bin/lslpp!!\n";
        }
    }
    elsif (lc $compiler eq "c89") {
        return utility::run_command ("c89 -Whelp 2>&1 | tail -2");
    }
    else {
        print STDERR __FILE__, ": " . "Invalid Compiler Option: $compiler\n";
    }
    return 0;
}

##############################################################################

main::RegisterCommand ("check_compiler", new check_compiler());
