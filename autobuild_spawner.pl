#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use File::Spec::Functions;

## Get Environment variables used for locating
## directory containting script to run as child
## as well as storing child's process id file in

use Env qw(@JENKINS_HOME);
#print "@JENKINS_HOME\n";
my $PIDFILE = "@JENKINS_HOME\/buildPid.txt";
print "PIDFILE Loc: $PIDFILE\n";

## This is a parent process, so store own pid as parent
my $childs_pid;
my $childs_proc;
my $cmd = catfile($ENV{AUTOBUILD_ROOT}, 'autobuild.pl');
my $Win_cmd = "perl $cmd @ARGV";
my $debug = 1;
my $wait_pid_time_sec = 60 * 3; # Every 3 minutes

package Parent;

use POSIX ":sys_wait_h";
use POSIX "setsid";

sub create_pid_file {
  print "Creating pid file\n";
  my($pid) = @_;
  open FILE, '+>'.$PIDFILE;
  print FILE "$pid";
  close FILE;
}

sub delete_pid_file {
  unlink $PIDFILE;
}

sub get_childs_pid_from_file {
  open FILE, $PIDFILE;
  my @pids; 
  while(<FILE>) {
    chomp;
    push @pids, $_;
  }
  close FILE;
  return $pids[0];
}

sub step_child_still_running {
  my ($childs_pid) = @_;
  #By sending SIGZERO to kill, simply sees if the
  #process exists and can accept signals (does not
  #actually kill)
  return kill 0, $childs_pid;
}

sub start_child_process {
  #die "cannot execute cmd: $cmd" unless -x $cmd;
#  print "$^O\n";
  if ($^O eq 'MSWin32') # Windows
  {
    require Win32::Process;

    #Need to tell process which exe to use to run the cmd
    #so find which perl is being used and format path to
    #pass to process create
    my $perl = `where perl`;
    $perl =~ s/\\/\\\\/g;
    chomp $perl;
    print "Windows Perl location $perl\n";

    print "Windows command: $Win_cmd\n";
    #Child is either created or fails to spawn and exits
    #thus ending child's logical processing
    Win32::Process::Create($childs_proc, $perl, $Win_cmd, 0, 0, ".") ||
        print "Could not spawn child (Windows): $!\n";

    #parent
    $childs_pid = $childs_proc->GetProcessID();

    print "Windows: Child created with pid: $childs_pid\n";
  }
  else #Unix
  {
    $SIG{CHLD} = 'IGNORE';
    $childs_pid = fork();
    unless (defined $childs_pid)
    {
      print "Could not spawn child (Unix): $!\n";
    }
    if ($childs_pid == 0) #child
    {
      unless ($debug)
      {
        open STDIN, "<", "/dev/null" or die "Can't read /dev/null: $!";
        open STDOUT, ">", "/dev/null" or die "Can't write /dev/null: $!";
      }
      setsid() or warn "setsid cannot start a new session: $!";
      unless ($debug)
      {
        open STDERR, '>^STDOUT' or die "Can't dup stdout: $!";
      }
      local $| = 1;

      print "Linux command: $cmd\n";
      #Child either exec's or exits thus ending child's logical processing
      unless (exec($cmd, @ARGV))
      {
        print "Could not start child: $cmd: $!\n";
        CORE::exit(0);
      }
    }
    #parent
    $SIG{CHLD} = 'DEFAULT';
  }
  #parent
  Parent::create_pid_file($childs_pid);
  return $childs_pid;
}

sub wait_on_child {
  my ($childs_pid) = @_;
  my $child_exit_status;
  while (1) {
    ## Wait on child to finish using waitpid with WNOHANG
    ## which returns:
    ## -1  - on error
    ## 0   - if child exists but has not yet changed state
    ## pid - when child with pid's state has changed

    print "Parent (PID:$$) waiting on child (PID: $childs_pid)\n";
    my $res = waitpid($childs_pid, WNOHANG);

    if ($res == -1) {
      my $child_exit_status = $? >> 8;
      print "Child exited with ERROR and status ", $child_exit_status, "\n";
      exit($child_exit_status);
    }

    if ($res != 0) {
      my $child_exit_status = $? >> 8;
      print "Child exited with status ", $child_exit_status, "\n";
      return $child_exit_status;
    }
    sleep ($wait_pid_time_sec);
  }
}

sub join_childs_thread {
  wait();
}

package ReturnCode::Type;

## Use these for exit status return values
use constant {
  EXIT_GOOD => 0,
  EXIT_ERROR => 1,
  EXIT_STILL_RUNNING => 3
};

package main;

print "THIS IS A PARENT PROCESS WITH PID: $$\n";

if(-e $PIDFILE) {
  ## The existence of a PIDFILE means this parent process is
  ## not the parent of the current, possibly running child.
  ## Open PIDFILE and extract child's process id
  my $step_childs_pid = Parent::get_childs_pid_from_file();
  print "PID FROM FILE: $step_childs_pid\n";

  ## Because this process is a step-parent, can't waitpid on
  ## child process, so instead simply check if it is still running
  if(Parent::step_child_still_running($step_childs_pid)){
    print "Child still running, but we don't own it\n";
    print "Exiting with status ", ReturnCode::Type->EXIT_STILL_RUNNING, "\n";
    exit(ReturnCode::Type->EXIT_STILL_RUNNING);
  } else {
    print "Child's pid file still present, but no longer running!\n";
    Parent::delete_pid_file();
    print "Deleted child's pid file\n";
  }
}

# PARENT PROCESSING CONTINUES HERE
# (Child processing all done in process started by star_child_process)

## PIDFILE doesn't exist, so this parent process
## can spawn the child process.
print "PID FILE DOESN'T EXIST, CREATE CHILD PROCESS\n";
$childs_pid = Parent::start_child_process();

Parent::wait_on_child($childs_pid);

print "About to wait on child thread to finish shutting down\n";
Parent::join_childs_thread();

print "Wait complete\n";

Parent::delete_pid_file();
print "Deleted child's pid file\n";

print "Exiting with status ", ReturnCode::Type->EXIT_GOOD, "\n";
exit(ReturnCode::Type->EXIT_GOOD);
