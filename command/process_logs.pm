#
# $Id$
#

package Process_Logs;

use strict;
use warnings;

use common::prettify;
use DirHandle;
use File::Copy;
use POSIX;
use Time::Local;

###############################################################################
# Forward Declarations

sub move_log ();
sub clean_logs ($);
sub prettify_log ($);

my $newlogfile;

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
    my $logroot = main::GetVariable ('log_root');

    if (!defined $root) {
        print STDERR __FILE__, ": Requires \"root\" variable\n";
        return 0;
    }
    if (!-d $root || !-r $root) {
        print STDERR __FILE__, ": Cannot read root dir: $root\n";
        return 0;
    }

    if (!defined $logroot) {
        print STDERR __FILE__, ": Requires \"log_root\" variable\n";
        return 0;
    }
    if (!-d $root || !-r $logroot) {
        print STDERR __FILE__, ": Cannot read log_root dir: $logroot\n";
        return 0;
    }

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;
    my $options = shift;
    my $keep = 20;
    my $moved = 0;

    print "\n#################### Processing Logs [" . (scalar gmtime(time())) . " UTC]\n";

    # Move the logs

    if ($options =~ m/move/) {
        $moved = 1;
        my $retval = $self->move_log ();
        return 0 if ($retval == 0);
    }

    # Prettify the logs

    if ($options =~ m/prettify/) {
        my $retval = $self->prettify_log ($moved);
        return 0 if ($retval == 0);
    }

    # Clean the logs

    if ($options =~ m/clean='(.*?)'/ || $options =~ m/clean=([^\s]*)/) {
        my $retval = $self->clean_logs ($1);
        return 0 if ($retval == 0);
    }
    elsif ($options =~ m/clean/) {
        my $retval = $self->clean_logs ($keep);
        return 0 if ($retval == 0);
    }

    return 1;
}

##############################################################################

sub clean_logs ($)
{
    my $self = shift;
    my $logroot = main::GetVariable ('log_root');
    my $keep = shift;
    my @existing;

    # chop off trailing slash
    if ($logroot =~ m/^(.*)\/$/) {
        $logroot = $1;
    }

    my $d = new DirHandle ($logroot);

    # Load the directory contents into the @existing array

    if (!defined $d) {
    }

    while (defined($_ = $d->read)) {
        if ($_ =~ m/^(...._.._.._.._..).txt/) {
            push @existing, $logroot . '/' . $1;
        }
    }
    undef $d;

    @existing = reverse sort @existing;

    # Remove the latest $keep logs from the list

    for (my $i = 0; $i < $keep; ++$i) {
        shift @existing;
    }

    # Delete anything left in the list

    foreach my $file (@existing) {
        print "        Removing $file files\n";
        unlink $file . ".txt";
        unlink $file . "_Full.html";
        unlink $file . "_Brief.html";
    }
    return 1;
}

sub move_log ()
{
    my $self = shift;
    my $root = main::GetVariable ('root');
    my $logroot = main::GetVariable ('log_root');
    my $logfile = main::GetVariable ('log_file');

    # chop off trailing slash
    if ($logroot =~ m/^(.*)\/$/) {
        $logroot = $1;
    }

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    $logfile = $root . "/" . $logfile;

    if (!defined $logfile) {
        print STDERR __FILE__, ": Requires \"logfile\" variable\n";
        return 0;
    }
    if (!-r $logfile) {
        print STDERR __FILE__, ": Cannot read logfile: $logfile\n";
        return 0;
    }

    my $timestamp = POSIX::strftime("%Y_%m_%d_%H_%M", gmtime);
    $newlogfile = $logroot . "/" . $timestamp . ".txt";

    # Use copy/unlink instead of move so on Win32 it inherits
    # the destination dir's permissions
    print "Moving $logfile to $newlogfile\n";
    copy ($logfile, $newlogfile);
    unlink ($logfile);

    # Make sure it has the correct permissions
    chmod (0644, $newlogfile);
    return 1;
}


sub prettify_log ($)
{
    my $self = shift;
    my $moved = shift;
    my $root = main::GetVariable ('root');
    my $logfile = main::GetVariable ('log_file');

    if ($moved) {
        $logfile = $newlogfile;
    }

    Prettify::Process ($logfile);
    return 1;
}

##############################################################################

main::RegisterCommand ("process_logs", new Process_Logs ());
