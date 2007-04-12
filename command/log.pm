#
# $Id$
#

package Log;

use strict;
use warnings;

use Cwd;
use FileHandle;
use Time::Local;
use File::Path;
use File::Spec;

###############################################################################
# Constructor

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {'paused' => 0,
               };

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

    if (uc $options eq "ON") {
        my $root = main::GetVariable ('root');

        if (!-r $root || !-d $root) {
            mkpath($root);
        }

        # chop off trailing slash
        if ($root =~ m/^(.*)\/$/) {
            $root = $1;
        }

        my $logfile = main::GetVariable ('log_file');

        # Force file paths to always be relative....
        my $logpath = $root . '/' . $logfile;

        # Make copies of current handles
        # Type "perlfunc -f open" to see an example of redirecting STDOUT
        open (OLDOUT, ">&STDOUT");
        open (OLDERR, ">&STDERR");

        if($main::verbose == 1) { 
          main::PrintStatus ('Setup', 'Logging: stdout/stderr redirected');
        }

        # Redirect to the logfile

        if (!open (STDOUT, '>', "$logpath")) {
            print STDERR __FILE__, ": Can't redirect stdout: $!\n";
            return 0;
        }
        if (!open (STDERR, ">&STDOUT")) {
            print STDERR __FILE__, ": Can't dup stdout: $!\n";
            return 0;
        }
        select(STDERR); $| = 1;    # make unbuffered
        select(STDOUT); $| = 1;    # make unbuffered

        main::PrintStatus ('Begin', '');
    }
    elsif (uc $options eq "OFF") {
        main::PrintStatus ('End', '');

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

        if( $main::verbose == 1) {
            main::PrintStatus ('Setup', 'Logging: stdout/stderr restored');
        }
    }
    elsif (uc $options eq "PAUSE") {
        if ($self->{'paused'}) {
            ## If we're paused and we get another pause, then we
            ## restore logging.

            # Restore the old handles

            if (!open (STDERR, ">&PAUSEERR")) {
                print OLDERR __FILE__, ": Error restoring ",
                                       "stderr during pause: $!\n";
                return 0;
            }
            if (!open (STDOUT, ">&PAUSEOUT")) {
                print OLDERR __FILE__, ": Error restoring ",
                                       "stdout during pause: $!\n";
                return 0;
            }

            # Close the duplicate handles
            if (!close (PAUSEOUT)) {
                print STDERR __FILE__, ": Error closing PAUSEOUT: $!\n";
                return 0;
            }
            if (!close (PAUSEERR)) {
                print STDERR __FILE__, ": Error closing PAUSEERR: $!\n";
                return 0;
            }

            ## The redirection was successful, now the
            ## logs are no longer paused.
            $self->{'pause'} = 0;
        }
        else {
            open (PAUSEOUT, ">&STDOUT");
            open (PAUSEERR, ">&STDERR");

            # Redirect to the null device

            if (!open (STDOUT, '>', File::Spec->devnull())) {
                print STDERR __FILE__, ": Can't redirect stdout ",
                                       "to null device: $!\n";
                return 0;
            }
            if (!open (STDERR, ">&STDOUT")) {
                print STDERR __FILE__, ": Can't dup stdout ",
                                       "duing pause: $!\n";
                return 0;
            }
            select(STDERR); $| = 1;    # make unbuffered
            select(STDOUT); $| = 1;    # make unbuffered

            ## The redirection was successful, now the logs are paused.
            $self->{'paused'} = 1;
        }
    }

    return 1;
}

##############################################################################

main::RegisterCommand ("log", new Log ());
