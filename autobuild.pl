eval '(exit $?0)' && eval 'exec perl -S $0 ${1+"$@"}'
  & eval 'exec perl -S $0 $argv:q'
  if 0;

##############################################################################
# $Id$
##############################################################################

use diagnostics;
use Time::Local;
use File::Basename;
use Cwd;

if ( $^O eq 'VMS' ) {
  require VMS::Filespec;
  import VMS::Filespec qw(unixpath);
}
else {
  use FindBin;
  use lib ($FindBin::Bin || '.');
}

## Use 'our' to make visible outside this file
#
our $verbose = 0;
our $deprecated = 0;
our $pathsep = (($^O eq "MSWin32") ? ';' : ':');
our $dirsep =  (($^O eq "MSWin32") ? '\\' : '/');
my $keep_going = 0;
my $parse_only = 0;
my $check_only = 0;
my $xml_dump = 0;
my $status_file = '';
my $build_start_time = scalar gmtime(time());
my @files;
my %data = ();
my %command_table = ();
my $cvs_tag;
my $starting_dir= getcwd ();
my $warn_nonfatal;

##############################################################################
# Load the commands allowed here
#
require common::mail;
require command::anonymous_shell;
require command::auto_run_tests;
require command::check_compiler;
require command::check_linker;
require command::doxygen;
require command::print_os_version;
require command::print_autotools_version;
require command::print_perl_version;
require command::print_valgrind_version;
require command::print_make_version;
require command::print_openssl_version;
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
require command::notify;
if ( $^O eq 'VMS' ) {
  require command::vmsmake;
}
else {
  require command::make;
}
require command::printaceconfig;
require command::print_status;
require command::process_logs;
require command::shell;           ## (Setup stage) execute command.
require command::status;
require command::tar;
require command::test;            ## as shell (but Test Stage)
require command::win32make;
require command::rem_sems;
require command::generate_makefile;
require command::generate_workspace;
require command::vc6make;
require command::vc7make;
require command::wincemake;
require command::svn;
require command::zip;
require command::unzip;
require command::run_perl_script;  ## This runs a perl command (like test).
require command::run_process;      ## This Spawns/Kills a concurrent test.
require command::setup_lvrt;
require command::eval;

##############################################################################
# Parse the arguments supplied when executed
#
while ($#ARGV >= 0)
{
  if ($ARGV[0] =~ m/^-v$/i) {
    if (defined $ARGV[1] && $ARGV[1] =~ m/^(\d+)$/) {
      shift;
      $verbose = $1;
    }
    else {
      ++$verbose;
    }
    shift;
  }
  elsif ($ARGV[0] =~ m/^-v(\d+)$/i) {
    $verbose = $1;
    shift;
  }
  elsif ($ARGV[0] =~ m/^-c$/i) {
    $check_only = 1;
    shift;
  }
  elsif ($ARGV[0] =~ m/^-d$/i) {
    $deprecated = 1;
    shift;
  }
  elsif ($ARGV[0] =~ m/^-k$/i) {
    $keep_going = 1;
    shift;
  }
  elsif ($ARGV[0] =~ m/^-p$/i) {
    $parse_only = 1;
    shift;
  }
  elsif ($ARGV[0] =~ m/^-cvs_tag$/i) {
    shift;
    $cvs_tag = shift;
    if (!defined $cvs_tag) {
      print "cvs_tag requires a tag name\n";
      exit 1;
    }
    print "CVS tag set to: $cvs_tag\n";
  }
  elsif ($ARGV[0] =~ m/^-xml$/i) {
      shift;
      $xml_dump = 1;
  }
  elsif ($ARGV[0] =~ m/^-w$/i) {
    $warn_nonfatal = 1;
    shift;
  }
  elsif ($ARGV[0] =~ m!^(-|/\?)!) {
    print "Error: Unknown option $ARGV[0]\n" if ($ARGV[0] !~ m!^(-|/)\?!);
    print
      "Useage: $0 [-c][-cvs_tag <tag>][-d][-k][-p][-v][-xml] files_to_process.xml [...]\n",
      "where:\n",
      "  -c    Parse and Check each command but don't execute any\n",
      "  -cvs_tag <tag>  Checkout operations use <tag> instead of HEAD\n",
      "  -d    Deprecated features issue warning messages\n",
      "  -k    Keep going if errors encountered\n",
      "  -p    Parse only, don't check or execute commands\n",
      "  -v    Verbose parsing messages displayed (more for each -v given)\n",
      "  -v0   Verbose off (default)\n",
      "  -v1   Verbose level 1\n",
      "  -v2   Verbose level 2\n",
      "  -xml  Dumps to <your_file>_dump.xml a newly processed input file\n",
      "  -w    Non-fatal errors are only warnings\n",
      "\n";
    exit 1;
  }
  else {
    push @files, shift;
  }
}

if (scalar @files == 0) {
  print "No input files specified\n";
  exit 1;
}

require common::betterparser;
my $parser = new BetterParser;

##############################################################################
# Subroutines to get execution path into @INC (nicked  from MPC:-)
# because FindBin does not work on OpenVMS
#
sub which {
  my($prog)   = shift;
  my($exec)   = $prog;
  my($part)   = '';
  if (defined $ENV{'PATH'}) {
	  foreach $part (split(/$pathsep/, $ENV{'PATH'})) {
	    $part .= (( $^O eq 'VMS' ) ? "" : "/" ) . "$prog";
	    if ( -x $part ) {
		    $exec = $part;
		    last;
	    }
	  }
  }
  return $exec;
}

##############################################################################
#
sub GetVariable ($)
{
  my $varname = shift;
  my $value = $data{VARS}->{$varname};
  if ($value && $value ne '') {
    # fix the seperators
    #
    $value =~ s/\\/\//g;

    # expand environment variables on windows
    #
    $value =~ s/%([^%]*)%/$ENV{$1}/ge;

    # on unix, note they must be in this form ${xxx}
    #
    $value =~ s'\$\{(\w+)\}'$ENV{$1}'ge;
  }
  return $value;
}

##############################################################################
#
sub GetEnvironment ()
{
  return @{$data{ENVIRONMENT}};
}

##############################################################################
#
sub IsRegisteredCommand ($)
{
  my $name = shift;
  return defined $command_table{$name};
}

##############################################################################
#
sub RegisterCommand ($$)
{
  my $name = shift;
  my $obj = shift;

  if (IsRegisteredCommand ($name)) {
    print STDERR "Command \"$name\" already defined\n";
    return 0;
  }

  $command_table{$name} = $obj;
  return 1;
}

##############################################################################
#
sub SetStatusFile ($)
{
  $status_file = shift;
}

##############################################################################
#
sub ChangeStatus ($$)
{
  my $command = shift;
  my $details = shift;

  if ($status_file ne '') {
    my $file_handle = new FileHandle ($status_file, 'w');

    if (!defined $file_handle) {
      print STDERR __FILE__,
        ': ', ($warn_nonfatal ? 'Unable to set' : 'Error setting'),
	" status to file ($status_file)", ($warn_nonfatal ? '' : ": $!"), "\n";

      # Non fatal error, so just return.
      return;
    }

    print $file_handle "SCOREBOARD_STATUS: $command\n\n";

    print $file_handle "Command details:    $details\n" if ($details ne '');

    print $file_handle 'Command started:    ' .
      (scalar gmtime(time())) . " UTC\n";
    print $file_handle "Last Build started: $build_start_time UTC\n";
  }
}

# This variable holds the status from the last time ::PrintStatus was set explicitly
my $previous_status = "Beginning";

##############################################################################
#
sub PrintStatus ($$)
{
  my $section = shift;
  my $description = shift;

  if ($section eq "")
  {
    $section = $previous_status;
  }
  else
  {
    $previous_status = $section;
  }

  ChangeStatus ($section, $description);

  if ($description ne '') {
    $description = "($description) ";
  }

  print "\n#################### $section $description";
  print "[" . (scalar gmtime(time())) . " UTC]\n";
}

##############################################################################
# This takes a string and substitues any <variable_names> into a copy of the
# string. In case of undefined variables, also needs the filename and line
# number(s) where the definition of this string was found.
#
sub subsituteVars ($;$$$)
{
  my ($inputString, $filename, $lineFrom, $lineTo) = @_;
  my $outputString= $inputString;

  # Search and replace all <vars> in string
  #
  while ($outputString =~ s/<(\w+)>(.*)$//) {
    my $variable = $1;
    my $restOfString = $2;
    my $value= GetVariable( $variable );
    if (!defined $value) {
      if (defined $filename && defined $lineFrom) {
        print STDERR "WARNING: $filename($lineFrom";
        if (defined $lineTo && $lineTo != $lineFrom) {
          print STDERR "-$lineTo";
        }
        print STDERR "):\n";
      }
      print STDERR "  Variable <$variable> has not been defined";
      if ($inputString !~ m/^\s*<$variable>\s*$/) {
        print STDERR ", as used in:\n  \'$inputString\'";
      }
      print STDERR "\n";
      $value= "";
    }

    $outputString .= $value . $restOfString;
  }

  return $outputString;
}

##############################################################################
# Due to a problem with VMS systems being unable to directly assign complete
# new hashes to the %ENV environment, we need to check and if necessary
# perform the changes one by one.
#
sub ChangeENV (\%)
{
  my $newENV = shift;
  if ($^O ne "VMS") {
    %ENV = %$newENV;
    return;
  }

  # Check if any environment variables are to be removed, and if so delete
  # them from the current environment. Only do this if the name is one we
  # have actually been told to modify.
  #
  my $thisKey;
  foreach $thisKey (keys %ENV) {
    if (!defined $newENV->{$thisKey}) {
      foreach my $variable (@{$data{ENVIRONMENT}}) {
        if ($variable->{NAME} eq $thisKey) {
          delete $ENV{$thisKey};
          last;
        }
      }
    }
  }

  # Now set any new or changed values into the current environment.
  # Only change the ENV values if they have actually changed, some
  # seem to be READONLY (and even if they are set back to the same
  # value it causes problems). Only do this if the name is one we
  # have actually been told to modify.
  #
  foreach $thisKey (keys %$newENV) {
    if (!defined $ENV{$thisKey} || $ENV{$thisKey} ne $newENV->{$thisKey}) {
      foreach my $variable (@{$data{ENVIRONMENT}}) {
        if ($variable->{NAME} eq $thisKey) {
          $ENV{$thisKey} = $newENV->{$thisKey};
          last;
        }
      }
    }
  }
}

##############################################################################
# Parse, CheckReqs, and Run every inputfile passed in.
#
INPFILE: foreach my $file (@files) {
  undef (@{$data{ENVIRONMENT}});
  undef (%{$data{VARS}});
  undef (@{$data{COMMANDS}});
  undef (%{$data{GROUPS}});
  undef (@{$data{UNUSED_GROUPS}});

  # We save a copy of the initial environment values which is stored under
  # the name "default", any other group names encountered by the parsing will
  # add extra entried to this hash, and add another copy of the initial
  # environment (so these can be modified seporatly from the default).
  #
  my %copyENV = %ENV;
  $data{GROUPS}->{default} = \%copyENV;
  push @{$data{UNUSED_GROUPS}}, "default";

  # Put the name of the file we are parsing into a global variable
  # named BUILD_CONFIG_FILE, and its path into BUILD_CONFIG_PATH.
  #
  if (!File::Spec->file_name_is_absolute ($file)) {
    $file = File::Spec->rel2abs ($file);
  }
  $data{VARS}->{BUILD_CONFIG_FILE} = File::Basename::basename ($file);
  $data{VARS}->{BUILD_CONFIG_PATH} = File::Basename::dirname  ($file);
  my $temp_file = $file;
  $temp_file =~ s!\\!/!g;  ## replace windows seperators with unix ones
  $temp_file =~ s!^.*configs/autobuild!configs/autobuild!;
  $data{VARS}->{CVS_CONFIG_FILE} = $temp_file;

  # Put the name of this autobuild file we are parsing into a global variable
  # named AUTOBUILD_PL_PATH.
  #
  my $this_file = __FILE__;
  if (!File::Spec->file_name_is_absolute ($this_file)) {
    $this_file = File::Spec->rel2abs ($this_file);
  }
  $data{VARS}->{AUTOBUILD_PL_PATH} = $this_file;
  $data{VARS}->{AUTOBUILD_ROOT} = File::Basename::dirname ($this_file);

  # Setup some other usefull variables before parsing the actual xml file.
  #
  $data{VARS}->{'cvs_tag'}   = (defined $cvs_tag) ? $cvs_tag : 'HEAD';
  #
  $data{VARS}->{'isAIX'}     = ($^O eq 'aix'    ) ? 1 : 0;
  $data{VARS}->{'isDecOSF'}  = ($^O eq 'dec_osf') ? 1 : 0;
  $data{VARS}->{'isHpux'}    = ($^O eq 'hpux'   ) ? 1 : 0;
  $data{VARS}->{'isLinux'}   = ($^O eq 'linux'  ) ? 1 : 0;
  $data{VARS}->{'isLynxos'}  = ($^O eq 'lynxos' ) ? 1 : 0;
  $data{VARS}->{'isSolaris'} = ($^O eq 'solaris') ? 1 : 0;
  $data{VARS}->{'isVMS'}     = ($^O eq 'VMS'    ) ? 1 : 0;
  $data{VARS}->{'isWin'}     = ($^O eq 'MSWin32') ? 1 : 0;
  #
  # and this is the generic one for everything non-windows / VMS.
  #
  $data{VARS}->{'isUnix'}    = ($^O ne 'VMS' &&
                                $^O ne 'MSWin32') ? 1 : 0;

  ############################################################################
  # Parse the actual xml input file
  #
  my $errors_found = !$parser->Parse ($file, \%data);
  if (scalar @{$data{ENVIRONMENT}}  &&
      scalar @{$data{COMMANDS}}     &&       
      scalar @{$data{UNUSED_GROUPS}}  ) {
    print STDERR "WARNING: $file:\n",
                 "  Environment group",
                 (1 == scalar @{$data{UNUSED_GROUPS}}? " \"" : "s \""),
                 join ("\", \"", @{$data{UNUSED_GROUPS}}), "\" w",
                 (1 == scalar @{$data{UNUSED_GROUPS}}? "as" : "ere"),
                 " declared but never used\n";
  }

  if ($xml_dump) {
    require common::simplencoder;
    my $encoder = new SimpleEncoder;
    my $xml_dump_file = $file;
    $xml_dump_file =~ s/(\..*)$/_dump$1/;
    print "\nEncoding: $file\n      as: $xml_dump_file\n" if ($verbose);
    $encoder->Encode ($xml_dump_file, \%data);
    next;
  }

  if (!$keep_going && $errors_found) {
    print STDERR "\nNo commands are being checked (due to the errors above)\n";
    exit 1;
  }

  if ($parse_only) {
    print "\nParsed successfully, No errors found\n";
    next;
  }

  ############################################################################
  # Actaully set the environment variables
  #
  print "\nSetting Enviroment variables\n" if ($verbose);
  my %originalENV = %ENV;
  foreach my $variable (@{$data{ENVIRONMENT}}) {
    my $VALUE = $variable->{VALUE};
    my $NAME  = $variable->{NAME};
    $NAME = uc $NAME if ($^O eq 'MSWin32');

    # Find in which environment groups this setting must take effect
    #
    my $GROUPS = $variable->{GROUPS};
    if (!defined $GROUPS || !scalar @$GROUPS) {
      my @allKeys= keys %{$data{GROUPS}};
      $GROUPS = \@allKeys;
    }

    my $onlyDefault = (1 == scalar keys %{$data{GROUPS}});
    foreach my $thisGroup (@$GROUPS) {
      my $thisENV = $data{GROUPS}->{$thisGroup};
      my $TYPE = $variable->{TYPE};
      if ($TYPE =~ m/^(?:delete|remove|unset)$/i) {
        delete $thisENV->{$NAME} if (defined $thisENV->{$NAME});
        print "  Deleted $NAME" .
              ($onlyDefault ? "\n" : " <-$thisGroup\n") if (1 < $verbose);
      }
      else {
        if (!defined $thisENV->{$NAME} || $TYPE =~ m/^(?:replace|set)$/i) {
          $thisENV->{$NAME} = $VALUE;
        }
        elsif ($TYPE =~ m/^prefix$/i) {
          $VALUE =~ s/^$pathsep*//;
          $VALUE =~ s/$pathsep*$//;
          $thisENV->{$NAME} =~ s/^$pathsep*//;
          $thisENV->{$NAME} =~ s/$pathsep*$//;
          $thisENV->{$NAME} = $VALUE . $pathsep . $thisENV->{$NAME} if ("" ne $VALUE);
        }
        elsif ($TYPE =~ m/^(?:postfix|suffix)$/i) {
          $VALUE =~ s/^$pathsep*//;
          $VALUE =~ s/$pathsep*$//;
          $thisENV->{$NAME} =~ s/^$pathsep*//;
          $thisENV->{$NAME} =~ s/$pathsep*$//;
          $thisENV->{$NAME} .= $pathsep . $VALUE if ("" ne $VALUE);
        }
        elsif ($TYPE !~ m/^(?:default(?:_(?:only|value)?)?|ifundefined)$/i) {
          print STDERR "IGNORING Don't know type \"$TYPE\"\n",
                      "  for Variable: $NAME=\"$VALUE\"\n";
          $errors_found = 1;
          last;
        }

        print "  $NAME=\"" . $thisENV->{$NAME} . "\"" .
              ($onlyDefault ? "\n" : " <-$thisGroup\n") if (1 < $verbose);
      }
    } ## foreach environment group to modify
  } ## End of setting environment variables loop

  if (!$keep_going && $errors_found) {
    print STDERR "\nNo commands are being checked (due to the errors above)\n";
    next;
  }

  my $oldRoot = $data{VARS}->{root};
  if (defined $oldRoot && $oldRoot =~ s/\s*([^\s]+)\s*/$1/) {
    if (!File::Spec->file_name_is_absolute ($oldRoot)) {
      $oldRoot = File::Spec->rel2abs ($oldRoot);
      $data{VARS}->{root} = $oldRoot;
    }
    print "\nRoot is \"$oldRoot\"\n" if ($verbose);
    chdir ($oldRoot);
  }
  elsif ($verbose) {
    print "\nRoot is UNDEFINED\n";
  }
  my $rootDir= getcwd ();

  print "Directory separator is: $dirsep\n" if ($verbose);
  print "Path separator is: $pathsep\n" if ($verbose);

  ############################################################################
  # Check each command's requirements
  #
  print "\nChecking Requirements\n" if ($verbose);

  my $currentENV = "";
  foreach my $command (@{$data{COMMANDS}}) {
    # Since not all parsers define all of the command attributes,
    # we make sure that any undefined ones have default meanings.
    #
    $command->{SUBVARS} = 2       if (!defined $command->{SUBVARS});
    $command->{GROUP} = "default" if (!defined $command->{GROUP});

    # Note, $command->{IF_TEXT} cannot be checked here as the previous
    # commands have not actually been executed yet. Thus if we are
    # checking for the result of one of those commands (rather than simply
    # the true/false of some variable setup by the xml control file) we
    # wouldn't perform the commands requirements checking stage.
    #
    my $NAME      = $command->{NAME};
    my $OPTIONS   = $command->{OPTIONS};
    my $SUBVARS   = $command->{SUBVARS};
    my $DIRECTORY = $command->{DIRECTORY};
    my $GROUP     = $command->{GROUP};

    # These command attributes may not exist.
    #
    my $FILE      = $command->{FILE};
    my $LINE_FROM = $command->{LINE_FROM};
    my $LINE_TO   = $command->{LINE_FROM};

    my $CMD = "Checking \"$NAME\" line";
    if (!defined $LINE_TO || $LINE_FROM == $LINE_TO) {
      $CMD .= " $LINE_FROM";
    }
    else {
      $CMD .= "s $LINE_FROM-$LINE_TO";
    }
    $CMD .= " of \"$FILE\"";
    print "  $CMD\n" if (1 < $verbose);

    if (!IsRegisteredCommand ($NAME)) {
      print STDERR "  Unknown $CMD\n";
      $command->{NAME}= "";  ## IGNORE this command if we keep going
      $errors_found = 1;
    }
    else {
      my $cmd_handler = $command_table{$NAME};

      # Subsitute any <variables> in the command's options string IF
      # desired. (0= Don't Subsitute, 1= Always Subsitute, 2= If command
      # normally requires subsitution, otherwise don't.)
      #
      if (2 == $SUBVARS &&
          defined $cmd_handler->{'substitute_vars_in_options'} &&
          $cmd_handler->{'substitute_vars_in_options'}            ) {
        $command->{SUBVARS}= 1; # Record that we are subsituting
      }

      # We must change the environment BEFORE we attempt to subsituteVars
      # as the function can subsitute environment values in place of
      # environment names within the variable being subsituted.
      #
      if ($GROUP ne $currentENV) {
        $currentENV = $GROUP;
        ChangeENV (%{$data{GROUPS}->{$GROUP}});
      }

      # Always subsitute any <variables> in the command's directory string.
      #
      if ("" ne $DIRECTORY) {
        $DIRECTORY=
          subsituteVars ($DIRECTORY, $FILE, $LINE_FROM, $LINE_TO);

        if ($DIRECTORY =~ s/\s*([^\s]+)\s*/$1/ &&
            !File::Spec->file_name_is_absolute ($DIRECTORY)) {
          $DIRECTORY = File::Spec->rel2abs ($DIRECTORY);
        }

        if ("" ne $DIRECTORY) {
          # If we fail here it may be due to a previous command such as mkdir
          # not yet having been executed, so we don't report problems here.
          #
          if (chdir ($DIRECTORY)) {
            $data{VARS}->{root} = $DIRECTORY;
          }
        }
      } ## DIRECTORY specified

      if ($cmd_handler->CheckRequirements () == 0) {
        print STDERR "  When $CMD\n" if ($verbose <= 1);
        $command->{NAME}= "";  ## IGNORE this command if we keep going
        $errors_found = 1;
      }

      if ("" ne $DIRECTORY) {
        chdir ($rootDir);
        $data{VARS}->{root} = $oldRoot;
      }
    } ## Command is known
  } ## end of check command requirements

  if (!$keep_going && $errors_found) {
    print STDERR "\nNo commands are being executed (due to the errors above)\n";
    chdir ($starting_dir);
    ChangeENV (%originalENV);
    next;
  }

  if ($check_only) {
    print "\nCommands checked successfully, No errors found\n";
    next;
  }

  ############################################################################
  # Execute each command
  #
  print "\nRunning Commands\n" if ($verbose);
  foreach my $command (@{$data{COMMANDS}}) {
    # Ignore any unknown commands (errors displayed above in check
    # requirements)
    #
    my $NAME      = $command->{NAME};
    next if ("" eq $NAME);

    # These command attributes always exist due check requirements.
    #
    my $OPTIONS   = $command->{OPTIONS};
    my $SUBVARS   = $command->{SUBVARS};
    my $DIRECTORY = $command->{DIRECTORY};
    my $GROUP     = $command->{GROUP};
    my $IF_TEXT   = $command->{IF_TEXT};

    # These command attributes may not exist.
    #
    my $FILE      = $command->{FILE};
    my $LINE_FROM = $command->{LINE_FROM};
    my $LINE_TO   = $command->{LINE_FROM};

    my $CMD = "Executing \"$NAME\" line";
    if (!defined $LINE_TO || $LINE_FROM == $LINE_TO) {
      $CMD .= " $LINE_FROM";
    }
    else {
      $CMD .= "s $LINE_FROM-$LINE_TO";
    }
    $CMD .= " of \"$FILE\"";
    my $CMD2 = "with options: \"$OPTIONS\"";

    print "\n",'=' x 79,"\n===== $CMD\n" if (1 < $verbose);

    # We must change the environment BEFORE we attempt to subsituteVars
    # as the function can subsitute environment values in place of
    # environment names within the variable being subsituted.
    #
    if ("default" ne $GROUP) {
      print "===== environment: \"$GROUP\"\n" if (1 < $verbose);
    }
    if ($GROUP ne $currentENV) {
      $currentENV = $GROUP;
      ChangeENV (%{$data{GROUPS}->{$GROUP}});
    }

    print "===== $CMD2\n" if (1 < $verbose);

    # Work out if we are going to execute this command.
    #
    my $IF_result =
      subsituteVars ($IF_TEXT, $FILE, $LINE_FROM, $LINE_TO);
    if ($IF_result !~ s/^\s*(?:true|)\s*$/1/i) {
      $IF_result = eval ($IF_result);
      $IF_result = 0 if (!defined $IF_result ||
                         $IF_result !~ s/^\s*([^\s]+)\s*$/$1/);
    }

    if ($IF_result) {
      # Subsitute any <variables> in the command's options string IF desired.
      #
      $OPTIONS=
        subsituteVars ($OPTIONS, $FILE, $LINE_FROM, $LINE_TO) if ($SUBVARS);
      if ($OPTIONS ne $command->{OPTIONS}) {
        print "===== subsitutions: \"$OPTIONS\"\n" if (1 < $verbose);
      }

      # Always subsitute any <variables> in the command's directory string
      # if a change of directory/root has been specified for the command.
      #
      if ("" ne $DIRECTORY) {
        $DIRECTORY=
          subsituteVars ($DIRECTORY, $FILE, $LINE_FROM, $LINE_TO );

        if ($DIRECTORY =~ s/\s*([^\s]+)\s*/$1/ &&
            !File::Spec->file_name_is_absolute ($DIRECTORY)) {
          $DIRECTORY = File::Spec->rel2abs ($DIRECTORY);
        }

        if ("" ne $DIRECTORY) {
          print "===== root: \"$DIRECTORY\"\n" if (1 < $verbose);
          $data{VARS}->{root} = $DIRECTORY;
          if (!chdir ($DIRECTORY)) {
            print STDERR "WARNING: While $CMD $CMD2:\n" if ($verbose <= 1);
            print STDERR "  Cannot change to directory \"$DIRECTORY\"\n";
          }
        }
      }

      if ($command_table{$NAME}->Run ($OPTIONS) == 0) {
        print STDERR "ERROR: While $CMD $CMD2:\n" if ($verbose <= 1);
        print STDERR "  The command failed";
        if (!$keep_going) {
          print STDERR ", exiting.\n";
          chdir ($starting_dir);
          ChangeENV (%originalENV);
          next INPFILE;
        }
        print STDERR "!\n";
      }
      
      if ("" ne $DIRECTORY) {
        $data{VARS}->{root} = $oldRoot;
        chdir ($rootDir);
      }
    } 
    else {
      print "===== Skipped because if=\"$IF_TEXT\" is false\n" if (1 < $verbose);
    }
  } ## end of execute commands
  print "\nFinished Commands\n" if ($verbose);
  chdir ($starting_dir);
  ChangeENV (%originalENV);
} ## next input file
