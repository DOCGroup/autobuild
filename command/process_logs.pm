#

package Process_Logs;

use strict;
use warnings;

use common::prettify;
use DirHandle;
use File::Copy;
use FileHandle;
use POSIX;
use Time::Local;
use File::Path;
use common::utility;

###############################################################################
# Forward Declarations

sub move_log ();
sub clean_logs ($);
sub prettify_log ($);
sub index_logs ();
sub save_root ();
sub copy_log ();
sub keep_files ();

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
    if (!defined $root) {
        print STDERR __FILE__, ": Requires \"root\" variable\n";
        return 0;
    }

    my $log_root = main::GetVariable ('log_root');
    if (!defined $log_root) {
        print STDERR __FILE__, ": Requires \"log_root\" variable\n";
        return 0;
    }

    my $log_file = main::GetVariable ('log_file');
    if (!defined $log_file) {
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
    my $keep = 10;
    my $moved = 0;
    my $log_root = main::GetVariable ('log_root');
    my $root = main::GetVariable ('root');

    if (!-r $log_root || !-d $log_root) {
        ## Due to weirdness from NFS, this directory may exist but not
        ## show up until we attempt to create the directory.  If it
        ## exists, we don't want to stop processing so catch the
        ## Carp::croak with an eval.
        eval { mkpath($log_root) };
    }

    if (!-r $root || !-d $root) {
        mkpath($root);
    }

    if ($main::verbose == 1 ) {
        main::PrintStatus ('Processing Logs', '');
    }

    # Move the logs

    if ($options =~ m/move/) {
        $moved = 1;
        my $retval = $self->move_log ();
        return 0 if ($retval == 0);
    }

    # Copy the logs

    if ($options =~ m/copy='([^']*)'/ || $options =~ m/copy=([^\s]*)/) {
        if ($moved == 1) {
            print STDERR __FILE__, ": move and copy are mutually exclusive\n";
            return 0;
        }
        $moved = 1;
        my $retval = $self->copy_log ($1);
        return 0 if ($retval == 0);
    }
    elsif ($options =~ m/copy/) {
        if ($moved == 1) {
            print STDERR __FILE__, ": move and copy are mutually exclusive\n";
            return 0;
        }
        $moved = 1;
        my $retval = $self->copy_log ($keep);
        return 0 if ($retval == 0);
    }

    # Prettify the logs

    my $prettify_keep = 0;
    if ($options =~ m/prettify='([^']*)'/ || $options =~ m/prettify=([^\s]*)/) {
        my $retval = $self->prettify_log ($moved, $1);
        return 0 if ($retval == 0);
    }
    elsif ($options =~ m/prettify/) {
        my $retval = $self->prettify_log ($moved);
        return 0 if ($retval == 0);
    }

    # Clean the logs

    if ($options =~ m/clean='([^']*)'/ || $options =~ m/clean=([^\s]*)/) {
        my $retval = $self->clean_logs ($1);
        return 0 if ($retval == 0);
    }
    elsif ($options =~ m/clean/) {
        my $retval = $self->clean_logs ($keep);
        return 0 if ($retval == 0);
    }

    # Create an index

    if ($options =~ m/index/) {
        my $retval = $self->index_logs ();
        return 0 if ($retval == 0);
    }

    return 1;
}

##############################################################################

sub clean_logs ($)
{
    my $self = shift;
    my $log_root = main::GetVariable ('log_root');
    my $keep = shift;
    my @existing;

    # chop off trailing slash
    if ($log_root =~ m/^(.*)\/$/) {
        $log_root = $1;
    }

    my $dh = new DirHandle ($log_root);

    # Load the directory contents into the @existing array

    if (!defined $dh) {
        print STDERR __FILE__, ": Could not read directory $log_root\n";
        return 0;
    }

    while (defined($_ = $dh->read)) {
        if ($_ =~ m/^(...._.._.._.._..).txt/) {
            push @existing, $log_root . '/' . $1;
        }
    }
    undef $dh;

    @existing = reverse sort @existing;

    # Remove the latest $keep logs from the list

    for (my $i = 0; $i < $keep; ++$i) {
        shift @existing;
    }

    # Delete anything left in the list
    foreach my $file (@existing) {
        Prettify::delete_prettify_output($file);
    }

    return 1;
}

sub move_log ()
{
    my $self = shift;
    my $root = main::GetVariable ('root');
    my $log_root = main::GetVariable ('log_root');
    my $log_file = main::GetVariable ('log_file');

    # chop off trailing slash
    if ($log_root =~ m/^(.*)\/$/) {
        $log_root = $1;
    }

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    $log_file = $root . "/" . $log_file;

    if (!defined $log_file) {
        print STDERR __FILE__, ": Requires \"logfile\" variable\n";
        return 0;
    }
    if (!-r $log_file) {
        print STDERR __FILE__, ": Cannot read logfile: $log_file\n";
        return 0;
    }

    my $timestamp = POSIX::strftime("%Y_%m_%d_%H_%M", gmtime);
    $newlogfile = $log_root . "/" . $timestamp . ".txt";

    # Use copy/unlink instead of move so on Win32 it inherits
    # the destination dir's permissions
    if ($main::verbose == 1) {
        print "Moving $log_file to $newlogfile\n";
    }

    my $ret;
    ## copy returns the number of successfully copied files
    $ret = copy ($log_file, $newlogfile);
    if ( $ret < 1 ) {
        print STDERR __FILE__, "Problem copying $log_file to $newlogfile: $!\n";
    }
    else {
        ## unlink returns the number of successfully copied files
        $ret = unlink ($log_file);
        if ( $ret < 1 ) {
            print STDERR __FILE__, "Problem deleting $log_file\n";
        }
    }

    # Make sure it has the correct permissions
    chmod (0644, $newlogfile);
    return 1;
}


sub prettify_log ($)
{
    my $self = shift;
    my $moved = shift;
    my $keep_logs = shift;
    my $root = main::GetVariable ('root');
    my $log_file = main::GetVariable ('log_file');

    if ($moved) {
        $log_file = $newlogfile;
    }

    my $process = Prettify::Process ($log_file);
    if ($process && $keep_logs) {
        # if keeping prettified logs, then identify each prettified log file,
        # copy it to the save_root (same as copy_log), and then keep at most
        # $keep_logs
        my $junit;
        my $save_root;
        my @filenames;
        for my $output (@{$process->{OUTPUT}}) {
            push(@filenames, $output->{FILENAME});
        }
        undef $process;
        for my $file (@filenames) {
            if (defined $file && -r $file) {
                $save_root = save_root() if !defined $save_root;
                $file =~ s/^(.*[\/\\])//;
                my $basedir = $1;

                # copy the Prettify::Process generated file
                my $oldfile = $basedir . $file;
                my $newfile = $save_root . "/" . $file;
                my $ret = copy ($oldfile, $newfile);
                if ( $ret < 1 ) {
                    print STDERR __FILE__, "Problem copying $oldfile to $newfile: $!\n";
                    return 0;
                }

                # Make sure it has the correct permissions
                chmod (0644, $newfile);

                # identify the _*.* extension for this output (_Full.html, _JUnit.xml, etc.)
                $file =~ /_[^_]+\.\w+$/;
                my $ext = $&;
                my $search = '^.*' . $ext;
                $self->keep_files($save_root, $search, $keep_logs);
            }
        }
    }
    return 1;
}

sub index_logs ()
{
    my $self = shift;
    my $log_root = main::GetVariable ('log_root');
    my $name = main::GetVariable ('name');
    my $diffroot = main::GetVariable ('diffroot');
    my @files;

    # chop off trailing slash
    if ($log_root =~ m/^(.*)\/$/) {
        $log_root = $1;
    }

    utility::index_logs ($log_root, $name, $diffroot);

    return 1;
}

sub save_root ()
{
    my $root = main::GetVariable ('root');
    my $log_root = main::GetVariable ('log_root');
    my $save_root;

    # chop off trailing slash
    if ($log_root =~ m/^(.*)\/$/) {
        $log_root = $1;
    }

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    # Create name of save directory ( = name of build )
    if ($log_root =~ m/.*\/(.*)$/) {
        $save_root = $root . "/" . $1;
    }

    if (!-r $save_root || !-d $save_root) {
        mkpath($save_root);
    }
    return $save_root;
}

sub copy_log ()
{
    my $self = shift;
    my $keep = shift;
    my $root = main::GetVariable ('root');
    my $log_root = main::GetVariable ('log_root');
    my $log_file = main::GetVariable ('log_file');
    my $save_root = save_root();

    # chop off trailing slash
    if ($log_root =~ m/^(.*)\/$/) {
        $log_root = $1;
    }

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    my $oldlog_file = $root . "/" . $log_file;

    if (!defined $oldlog_file) {
        print STDERR __FILE__, ": Requires \"logfile\" variable\n";
        return 0;
    }
    if (!-r $oldlog_file) {
        print STDERR __FILE__, ": Cannot read logfile: $oldlog_file\n";
        return 0;
    }

    my $timestamp = POSIX::strftime("%Y_%m_%d_%H_%M", gmtime);
    $newlogfile = $log_root . "/" . $timestamp . ".txt";
    my $savelogfile = $save_root . "/" . $timestamp . ".txt";

    if ($main::verbose == 1) {
        print "Copying $oldlog_file to $newlogfile\n";
    }

    my $ret;
    ## copy returns the number of successfully copied files
    $ret = copy ($oldlog_file, $newlogfile);
    if ( $ret < 1 ) {
        print STDERR __FILE__, "Problem copying $oldlog_file to $newlogfile: $!\n";
        return 0;
    }

    # Make sure it has the correct permissions
    chmod (0644, $newlogfile);

    # Touch a trigger file to tell the scoreboard that the log is complete
    my $triggerfile = $log_root . "/post";
    open(FH, ">$triggerfile");
    close(FH);

    if ($main::verbose == 1) {
        print "Saving $oldlog_file as $newlogfile\n";
    }

    # This should be a simple move, however, we  use copy/unlink instead
    # of move since on Windows the move fails if the file is open (like
    # a test that doesn't finish) whereas the copy and unlink succeed.
    $ret = copy ($oldlog_file, $savelogfile);
    if ( $ret < 1 ) {
        print STDERR __FILE__, "Problem copying $oldlog_file to $savelogfile: $!\n";
        return 0;
    }
    $ret = unlink ($oldlog_file);
    if ( $ret < 1 ) {
        print STDERR __FILE__, "Problem removing $oldlog_file: $!\n";
    }
    chmod (0644, $savelogfile);

    $self->keep_files($save_root, '^...._.._.._.._..\\.txt$', $keep);

    return 1;
}

sub keep_files ()
{
    my $self = shift;
    my $dir = shift;
    my $pattern = shift;
    my $keep = shift;

    # Clean up old saved files
    my $dh = new DirHandle ($dir);
    my @existing;

    # Load the directory contents into the @existing array

    if (!defined $dh) {
        print STDERR __FILE__, ": Could not read directory $dir\n";
        return 0;
    }

    while (defined($_ = $dh->read)) {
        # if the file matches the desired pattern, then store it to determine
        # if it should be kept or removed
        if ($_ =~ m/$pattern/) {
            push @existing, $dir . '/' . $_;
        }
    }
    undef $dh;

    @existing = reverse sort @existing;

    # Remove the latest $keep logs from the list

    for (my $i = 0; $i < $keep; ++$i) {
        shift @existing;
    }

    # Delete anything left in the list

    foreach my $file (@existing) {
        unlink $file;
    }

    return 1;
}


##############################################################################

main::RegisterCommand ("process_logs", new Process_Logs ());
