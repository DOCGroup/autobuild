eval '(exit $?0)' && eval 'exec perl -S $0 ${1+"$@"}'
    & eval 'exec perl -S $0 $argv:q'
    if 0;

#
# $Id$
#

use FindBin;
use lib $FindBin::Bin;
use common::simpleparser;

my $verbose = 0;
my @files;
my %data = ();
my %commandtable = ();

#
# Parse the arguments
#

while ($#ARGV >= 0)
{
    if ($ARGV[0] =~ m/^-v/i) {
        $verbose = 1;
	shift;
    }
    elsif ($ARGV[0] =~ m/^-/) {
        print "Error: Unknown option $ARGV[0]\n";
        exit 1;
    }
    else {
        push @files, shift;
    }
}

if (scalar @files == 0) {
    print "No input files\n";
    exit;
}

#
# Callbacks for commands
#

sub GetVariable ($)
{
    my $varname = shift;
    return %data->{VARS}->{$varname};
}

sub RegisterCommand ($$)
{
    my $name = shift;
    my $obj = shift;

    if (defined %commandtable->{$name}) {
        print STDERR "Command \"$name\" already defined\n";
        return 0;
    }

    %commandtable->{$name} = $obj;
    return 1;
}

#
# Load the commands here
#

require command::auto_run_tests;
require command::process_logs;
require command::cvs;
require command::file_manipulation;
require command::log;
require command::make;
require command::printaceconfig;
require command::shell;
require command::sam;

#
# Parse, CheckReqs, and Run
#

my $parser = new SimpleParser;

foreach my $file (@files) {
    print "Parsing file: $file\n" if ($verbose);
    $parser->Parse ($file, \%data);

    print "\nSetting Enviroment variables\n" if ($verbose);
    
    foreach my $variable (@{%data->{ENVIRONMENT}}) {
        print "Variable: ", $variable->{NAME}, "=", $variable->{VALUE}, "\n" if ($verbose);
        $ENV{$variable->{NAME}} = $variable->{VALUE};
    }

    print "\nChecking Requirements\n" if ($verbose);

    foreach my $command (@{%data->{COMMANDS}}) {
        print "Command: ", $command->{NAME}, "\n" if ($verbose);
        if (!defined %commandtable->{$command->{NAME}}) {
            print STDERR "Unknown Command: $command->{NAME}\n";
            exit;
        }
        if (%commandtable->{$command->{NAME}}->CheckRequirements () == 0) {
            exit;
        }
    }

    print "\nRunning Commands\n" if ($verbose);

    foreach my $command (@{%data->{COMMANDS}}) {
        print "Command: ", $command->{NAME}, "\n" if ($verbose);
        if (%commandtable->{$command->{NAME}}->Run ($command->{OPTIONS}) == 0) {
            last;
        }
    }
}
