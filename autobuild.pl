eval '(exit $?0)' && eval 'exec perl -S $0 ${1+"$@"}'
    & eval 'exec perl -S $0 $argv:q'
    if 0;

#
# $Id$
#


if ( $^O eq 'VMS' ) {
  unshift(@INC, getExecutePath($0));
} else  {
  use FindBin;
  use lib $FindBin::Bin;
}

require common::simpleparser;
use diagnostics;
use Time::Local;
use File::Basename;
use Cwd;

my $status_file = '';
my $build_start_time = scalar gmtime(time());
## Use 'our' to make $verbose visible outside this file
our $verbose = 0;
my @files;
my %data = ();
my %command_table = ();

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
# Subroutines to get execution path into @INC (nicked  from MPC:-)
# because FindBin does not work on OpenVMS
#
if ($^O eq "VMS") {
  require VMS::Filespec;
  import VMS::Filespec qw(unixpath);
}

sub which {
  my($prog)   = shift;
  my($exec)   = $prog;
  my($part)   = '';
  if ( $^O eq 'VMS' ) {
    my($envSep) = ';';
    if (defined $ENV{'PATH'}) {
      foreach $part (split(/$envSep/, $ENV{'PATH'})) {
        $part .= "$prog";
        if ( -x $part ) {
          $exec = $part;
          last;
        }
      }
    }
  }
  else  {
    my($envSep) = ($^O eq 'MSWin32' ? ';' : ':');
    if (defined $ENV{'PATH'}) {
      foreach $part (split(/$envSep/, $ENV{'PATH'})) {
        $part .= "/$prog";
        if ( -x $part ) {
          $exec = $part;
          last;
        }
      }
    }
  }

  return $exec;
}


sub getExecutePath {
  my($prog) = shift;
  my($loc)  = '';

  if ( $^O eq 'VMS' ) {
    if ($prog ne basename($prog)) {
      my($dir) = unixpath( dirname($prog) );
      if ($prog =~ /^[\/\\]/) {
        $loc = $dir;
      }
      else {
        $loc = unixpath(getcwd()) . $dir;
      }
    }
    else {
      $loc = unixpath( dirname(which($prog)) );
    }

    if ($loc eq '.') {
      $loc = unixpath( getcwd() );
    }
  } else {
    if ($prog ne basename($prog)) {
      if ($prog =~ /^[\/\\]/ ||
          $prog =~ /^[A-Za-z]:[\/\\]?/) {
        $loc = dirname($prog);
      }
      else {
        $loc = getcwd() . '/' . dirname($prog);
      }
    }
    else {
      $loc = dirname(which($prog));
    }

    if ($loc eq '.') {
      $loc = getcwd();
    }

    if ($loc ne '') {
      $loc .= '/';
    }
  }

  return $loc;
}

#
# Callbacks for commands
#

sub GetVariable ($)
{
    my $varname = shift;
    my $value = $data{VARS}->{$varname};
    if ($value && $value ne '') {
        # fix the seperators
        $value =~ s/\\/\//g;
        # expand environment variables
        # on windows
        $value =~ s/%([^%]*)%/$ENV{$1}/ge;
        # on unix, note they must be in this form ${xxx}
        $value =~ s'\$\{(\w+)\}'$ENV{$1}'ge;
    }
    return $value;
}

sub RegisterCommand ($$)
{
    my $name = shift;
    my $obj = shift;

    if (defined $command_table{$name}) {
        print STDERR "Command \"$name\" already defined\n";
        return 0;
    }

    $command_table{$name} = $obj;
    return 1;
}

sub SetStatusFile ($)
{
    $status_file = shift;
}

sub ChangeStatus ($$)
{
    my $command = shift;
    my $details = shift;
    
    if ($status_file ne '') {
        my $file_handle = new FileHandle ($status_file, 'w');
        
        if (!defined $file_handle) {
            print STDERR __FILE__, ": Error setting status to file ($status_file): $!\n";
            
            # Non fatal error, so just return.
            return;
        }

        print $file_handle "SCOREBOARD_STATUS: $command\n\n";
        
        print $file_handle "Command details:    $details\n" if ($details ne '');
        
        print $file_handle 'Command started:    ' . (scalar gmtime(time())) . " UTC\n";
        print $file_handle "Last Build started: $build_start_time UTC\n";
    }
}

sub PrintStatus ($$)
{
    my $section = shift;
    my $description = shift;
    
    ChangeStatus ($section, $description);
    
    if ($description ne '') {
        $description = "($description) ";
    }

    print "\n#################### $section $description";
    print "[" . (scalar gmtime(time())) . " UTC]\n";
}

#
# Load the commands here
#
require common::mail;
require command::anonymous_shell;
require command::auto_run_tests;
require command::check_compiler;
require command::check_linker;
require command::print_os_version;
require command::print_autotools_version;
require command::print_perl_version;
require command::print_valgrind_version;
require command::print_make_version;
require command::print_cidlc_version;
require command::process_listener;
require command::configure;
require command::create_ace_build;
require command::create_ace_build_legacy;
require command::clone_build_tree;
require command::cvs;
require command::cvsgrab;
require command::file_manipulation;
require command::fuzz;
require command::log;
if ( $^O eq 'VMS' ) {
  require command::vmsmake;
} 
else {
  require command::make;
}
require command::printaceconfig;
require command::print_status;
require command::process_logs;
require command::sam;
require command::shell;
require command::status;
require command::win32make;
require command::rem_sems;
require command::generate_makefile;
require command::generate_workspace;
require command::vc6make;
require command::vc7make;
require command::wincemake;
require command::svn;
#
# Parse, CheckReqs, and Run
#

my $parser = new SimpleParser;
my $pathsep = ':';

foreach my $file (@files) {
    print "Parsing file: $file\n" if ($verbose);
    $parser->Parse ($file, \%data);

    ## Put the name of the file we are parsing into a global variable
    ## named BUILD_CONFIG_FILE. 
    $data{VARS}->{BUILD_CONFIG_FILE} = File::Basename::basename( $file );

    ## Grab the relative path for the config file so we can pull a copy
    ##  from cvs later
    my $temp_file = $file;

    ## If $temp_file doesn't include the path, we need to get it relative
    ## to the current directory.
    if ($temp_file !~ m/\/configs\/autobuild/){
        ## we need to prepend the path if the caller cd'd into the directory
        ## that contains the config file (this assumes it's in the autobuild
        ## tree...
        my $current_dir = getcwd ();
        $current_dir =~ s/\\/\//g;
        # add trailing slash if not there
        if ($current_dir !~ m/^.*\/$/) {
            $current_dir = $current_dir."/";
        }
        $temp_file = $current_dir.$temp_file;
    }

    ## replace windows seperators with unix ones
    $temp_file =~ s/\\/\//g;

    ## strip off the anything prior to "configs/autobuild"
    $temp_file =~ s/.*configs\/autobuild/configs\/autobuild/;
    $data{VARS}->{CVS_CONFIG_FILE} = $temp_file;


    if($^O eq "MSWin32"){
        $pathsep = ';';
    }

    print "\nSetting Enviroment variables, pathsep '$pathsep'\n" if ($verbose);

    foreach my $variable (@{$data{ENVIRONMENT}}) {
        print "Variable: ", $variable->{NAME}, "=", $variable->{VALUE}, "\n" if ($verbose);
        
        if ($variable->{TYPE} eq 'replace') {
            $ENV{$variable->{NAME}} = $variable->{VALUE};
        }
        elsif ($variable->{TYPE} eq 'prefix') {
            $ENV{$variable->{NAME}} = $variable->{VALUE} . $pathsep . $ENV{$variable->{NAME}};
        }
        elsif ($variable->{TYPE} eq 'suffix') {
            $ENV{$variable->{NAME}} = $ENV{$variable->{NAME}} . $pathsep . $variable->{VALUE};
        }
        else {
            print STDERR "Don't know type: $variable->{TYPE}\n";
            exit;
        }
    }

    print "\nChecking Requirements\n" if ($verbose);

    foreach my $command (@{$data{COMMANDS}}) {
        print "Command: ", $command->{NAME}, "\n" if ($verbose);
        if (!defined $command_table{$command->{NAME}}) {
            print STDERR "Unknown Command: $command->{NAME}\n";
            exit;
        }
        if ($command_table{$command->{NAME}}->CheckRequirements () == 0) {
            exit;
        }
    }

    print "\nRunning Commands\n" if ($verbose);

    foreach my $command (@{$data{COMMANDS}}) {
        print "Command: ", $command->{NAME}, "\n" if ($verbose);
        if ($command_table{$command->{NAME}}->Run ($command->{OPTIONS}) == 0) {
            last;
        }
    }
}
