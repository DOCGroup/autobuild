#
# $Id$
#

package JBoss_Report;

use strict;
use warnings;

use DirHandle;
use File::Copy;
use FileHandle;
use POSIX;
use Time::Local;
use File::Path;

###############################################################################
# Forward Declarations

sub copy_log ();

my $newlogfile;
my $newreportsdir;

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

    my $project_root = main::GetVariable ('project_root');
    if (!defined $project_root) {
        print STDERR __FILE__, ": Requires \"project_root\" variable\n";
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

    my $jboss_reports_dir = main::GetVariable ('jboss_reports_dir');
    if (!defined $jboss_reports_dir) {
        print STDERR __FILE__, ": Requires \"jboss_reports_dir\" variable\n";
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
    my $project_root = main::GetVariable ('project_root');

    if (!-r $log_root || !-d $log_root) {
        ## Due to weirdness from NFS, this directory may exist but not
        ## show up until we attempt to create the directory.  If it
        ## exists, we don't want to stop processing so catch the
        ## Carp::croak with an eval.
        eval { mkpath($log_root) };
    }

    if (!-r $root || !-d $root) {
        eval { mkpath($root) };
    }

    if (!-r $project_root || !-d $project_root) {
        eval { mkpath($project_root) };
    }

    if ($main::verbose == 1 ) {
        main::PrintStatus ('Processing Logs', '');
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

    return 1;
}

##############################################################################

sub copy_log ()
{
    my $self = shift;
    my $keep = shift;
    my $root = main::GetVariable ('project_root');
    my $project_root = main::GetVariable ('root');
    my $log_root = main::GetVariable ('log_root');
    my $log_file = main::GetVariable ('log_file');
    my $jboss_reports_dir = main::GetVariable ('jboss_reports_dir');
    my $save_root;

    # chop off trailing slash
    if ($log_root =~ m/^(.*)\/$/) {
        $log_root = $1;
    }
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }
    if ($project_root =~ m/^(.*)\/$/) {
        $project_root = $1;
    }

    # Create name of save directory ( = name of build )
    if ($log_root =~ m/.*\/(.*)$/) {
        $save_root = $root . "/" . $1;
    }

    if (!-r $save_root || !-d $save_root) {
        mkpath($save_root);
    }
    my $oldlog_file = $root . "/" . $log_file;
    my $old_jboss_reports_dir = $project_root . "/" . $jboss_reports_dir;

    if (!defined $oldlog_file) {
        print STDERR __FILE__, ": Requires \"logfile\" variable\n";
        return 0;
    }
    if (!-r $oldlog_file) {
        print STDERR __FILE__, ": Cannot read logfile: $oldlog_file\n";
        return 0;
    }

    if (!defined $old_jboss_reports_dir) {
        print STDERR __FILE__, ": Requires \"jboss_reports_dir\" variable\n";
        return 0;
    }
    if (!-d $old_jboss_reports_dir) {
        print STDERR __FILE__, ": Cannot read directory: $old_jboss_reports_dir\n";
        return 0;
    }

    my $timestamp = POSIX::strftime("%Y_%m_%d_%H_%M", gmtime);
    $newlogfile = $log_root . "/" . $timestamp . ".txt";
    $newreportsdir = $log_root . "/" . $timestamp . "_reports";
    my $savelogfile = $save_root . "/" . $timestamp . ".txt";
    my $savereportsdir = $save_root . "/" . $timestamp . "_reports";

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
    
    copy_dir($old_jboss_reports_dir, $newreportsdir);

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

    # Clean up old saved files
    my $dh = new DirHandle ($save_root);
    my @existing_local_logs;

    # Load the directory contents into the @existing array

    if (!defined $dh) {
        print STDERR __FILE__, ": Could not read directory $save_root\n";
        return 0;
    }

    while (defined($_ = $dh->read)) {
        if ($_ =~ m/^(...._.._.._.._..).txt$/) {
            push @existing_local_logs, $save_root . '/' . $1;
        }
    }
    undef $dh;

    $dh = new DirHandle ($log_root);
    my @existing_logs;
    my @existing_reports;

    # Load the directory contents into the @existing array

    if (!defined $dh) {
        print STDERR __FILE__, ": Could not read directory $save_root\n";
        return 0;
    }

    while (defined($_ = $dh->read)) {
        if ($_ =~ m/^(...._.._.._.._..).txt$/) {
            push @existing_logs, $log_root . '/' . $1;
        }
        elsif ($_ =~ m/^(...._.._.._.._.._reports)$/) {
            push @existing_reports, $log_root . '/' . $1;
        }
    }
    undef $dh;
    
    @existing_local_logs = reverse sort @existing_local_logs;
    @existing_logs = reverse sort @existing_logs;
    @existing_reports = reverse sort @existing_reports;

    # Remove the latest $keep logs from the list

    for (my $i = 0; $i < $keep; ++$i) {
        shift @existing_local_logs;
        shift @existing_logs;
        shift @existing_reports;
    }

    # Delete anything left in the list

    foreach my $file (@existing_local_logs) {
        unlink $file . ".txt";
    }

    foreach my $file (@existing_logs) {
        unlink $file . ".txt";
    }

    foreach my $report_dir (@existing_reports) {
        File::Path::remove_tree($report_dir);
    }

    return 1;
}

sub copy_dir ()
{
    my $from_dir = shift;
    my $to_dir = shift;

    my $dh = new DirHandle ($from_dir);
    mkdir($to_dir, 0755);
    my $ret;
    my @dir_contents = $dh->read();
    foreach my $content (@dir_contents) {
      unless ( ($content eq ".") || ($content eq "..") ) {
        my $from_content = $from_dir . "/" . $content;
        my $to_content = $to_dir . "/" . $content;
        if (-d $from_content) {
          $ret = &copy_dir($from_content, $to_content);
          if ( $ret < 1 ) {
              print STDERR __FILE__, "Problem copying directory $from_content to $to_content: $!\n";
              return 0;
          }
        }
        elsif (-e $from_content) {
          $ret = copy ($from_content, $to_content);
          if ( $ret < 1 ) {
              print STDERR __FILE__, "Problem copying $from_content to $to_content: $!\n";
              return 0;
          }
          chmod (0644, $to_content);
        }
      }
    }

    return 1;
}


##############################################################################

main::RegisterCommand ("jboss_report", new JBoss_Report ());
