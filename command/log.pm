#
# $Id$
#

package Log;

use strict;
use warnings;

use Cwd;
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
    my $logfile = main::GetVariable ('log_file');

    if (!defined $root) {
        print STDERR __FILE__, ": Requires \"root\" variable\n";
        return 0;
    }

    if (!-r $root || !-d $root) {
        print STDERR __FILE__, ": Cannot access \"root\" directory: $root\n";
        return 0;
    }

    if (!defined $logfile) {
        print STDERR __FILE__, ": Requires \"log_file\" variable\n";
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
    my $logfile = main::GetVariable ('log_file');

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    # Force file paths to always be relative....
    my $logpath = $root . '/' . $logfile;

    if (uc $options eq "ON") {
        # Make copies of current handles

        open (OLDOUT, ">&STDOUT");
        open (OLDERR, ">&STDERR");

        # Redirect to the logfile

        if (!open (STDOUT, "> $logpath")) {
            print STDERR __FILE__, ": Can't redirect stdout: $!\n";
            return 0;
        }
        if (!open (STDERR, ">&STDOUT")) {
            print STDERR __FILE__, ": Can't dup stdout: $!\n";
            return 0;
        }

        print "\n#################### Begin [" . (scalar gmtime(time())) . " UTC]\n";
    }
    elsif (uc $options eq "OFF") {
        print "\n#################### End [" . (scalar gmtime(time())) . " UTC]\n";

        # Close the logging filehandles

        if (!close (STDOUT)) {
            print OLDERR __FILE__, ": Error closing logging stdout: $!\n";
            return 0;
        }
        if (!close (STDERR)) {
            print OLDERR __FILE__, ": Error closing logging stderr: $!\n";
            return 0;
        }

        # Restore the old handles

        if (!open (STDERR, ">&OLDERR")) {
            print OLDERR __FILE__, ": Error restoring stderr: $!\n";
            return 0;
        }
        if (!open (STDOUT, ">&OLDOUT")) {
            print OLDERR __FILE__, ": Error restoring stdout: $!\n";
            return 0;
        }

        # Close the duplicate handles
        if (!close (OLDOUT)) {
            print STDERR __FILE__, ": Error closing OLDOUT: $!\n";
            return 0;
        }
        if (!close (OLDERR)) {
            print STDERR __FILE__, ": Error closing OLDERR: $!\n";
            return 0;
        }
    }

    return 1;
}

##############################################################################

main::RegisterCommand ("log", new Log ());
