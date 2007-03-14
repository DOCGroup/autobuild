#
# $Id$
#
package common::parse_compiler_output;
use strict;
use warnings;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};

  bless($self, $class);
  return $self;
}

sub Output_Subsection($) {
}

sub Output_Normal($) {
}

sub Output_Warning($) {
}

sub Output_Error($) {
}

sub Detected_Build_Error($) {
}

sub handle_compiler_output_line($) {
  my $self = shift;
  my $s = shift;


  # Check for the subsection indicator
  # VC71 || GNU make || nmake || borland make
  if ($s =~ m/^------ Build started: Project: (.*), Config.*/ || $s =~ /Entering directory (.*)/ || $s =~ /nmake.exe\" \/f Makefile.(.*) CFG.*/ || $s =~ /make .* -f (.*).bor .*/) {
    $self->Output_Subsection ($1);
    return;
  }

  # Check out the line to figure out whether it is an error or not

  # The NMAKE output on Windows includes the complete command line; if there
  # are options with the word "warning" or "error" these get flagged as
  # errors. So if it's the command line, just output as normal.
  if ($s =~ m/^[ \t]*cl.exe/) {
    $self->Output_Normal ($s);
    return;
  }

  if ($s =~ m/^Error scanning file .* for dependencies/) {
    # EVC 4 complains about non-existent files during dependency
    # generation.  This is not an actual error.
    $self->Output_Normal ($s);
    return;
  }

  if ($s =~ m/^ld: \d+\-\d+ WARNING: Duplicate symbol:/) {
    # AIX reports a bazillion multiple defines when doing templates; some
    # have the word 'error' in the symbol name - ignore those.
    $self->Output_Normal ($s);
    return;
  }

  if ($s =~ m/\.depend\..*:\s+no\s+such\s+file/i) {
    $self->Output_Normal ($s);
    return;
  }

  if ($s =~ m/Clock skew detected/) {
    # Can be given when building on NFS volumes, just ignore
    $self->Output_Normal ($s);
    return;
  }

  if ($s =~ m/has modification time/) {
    # Can be given when building on NFS volumes, just ignore
    $self->Output_Normal ($s);
    return;
  }

  if ($s =~ m/is dangerous, better use/) {
    # Linux has this annoying mktemp, mkstemp stuff. Ignore that
    # for the timebeing
    $self->Output_Normal ($s);
    return;
  }

  if ($s =~ m/possibly used unsafely, use/) {
    # Similar warnings on NetBSD
    $self->Output_Normal ($s);
    return;
  }

  if ($s =~ m/possibly used unsafely[;,] consider using/) {
    # Similar warnings on OpenBSD
    $self->Output_Normal ($s);
    return;
  }

  if ($s =~ m/\-W:c:,\-Xmismatch\-warning\=2/) {
    # catch VxWorks DIAB warning option before it is caught as Warning
    $self->Output_Normal ($s);
    return;
  }

  if ($s =~ m/ is deprecated. use /) {
    # Among these are glibc warnings to stop using the deprecated
    # pthread_setstackaddr in favor of pthread_setstack.
    $self->Output_Warning ($s);
    return;
  }

  if ($s =~ m/Too many levels of symbolic links/) {
    # Indicates a broken file system. Must be fixed to prevent
    # other errors in the future
    $self->Output_Warning ($s);
    return;
  }

  if ($s =~ m/not be built due to the following missing/) {
    # Indicates that something is not properly configured - ie,
    # incorrect depenancies in the mpc files, default.featres setting,
    # etc.
      $self->Output_Warning ($s);
      return;
  }

  if ($s =~ m/Rule line too long/) {
    # Can be given by Borland make
    $self->Output_Error ($s);
    return;
  }

  if ($s =~ m/is not recognized as an internal or external command/) {
    # Something can't be found that needs to get executed
    $self->Output_Error ($s);
    return;
  }

  if ($s =~ m/command not found/) {
    # Means we can't find something to execute
    $self->Output_Error ($s);
    return;
  }

  if ($s =~ m/(BUILD ERROR detected in [\w\/]+)/ ) {
    # If we see "BUILD ERROR detected in" then increment the build counter
    # but don't print it in the report.
    $self->Detected_Build_Error($1);
  }

  if ($s =~ m/^.*:[0-9]+: /) {
    # filename:linenumber is the typical format for an error
    if(# ... unless it is a warning
       $s =~ m/^.*:[0-9]+: warning:/i
       # ... or a template location where it could be either a
       # warning or an error, but the lines around it would show the
       # real reason ...
       || $s =~ m/^.*:[0-9]+:\s+instantiated\sfrom\s/) {
      if (defined $main::verbose and $main::verbose == 1) {
        print STDERR "Possible ERROR $s\n";
      }
      $self->Output_Warning ($s);
      return;
    }
    # It could also be part of a split line warning relating to
    # mktemp/mkstemp
    if (/mkstemp/) {
      $self->Output_Normal ($s);
      return;
    }
    # Definately an error
    $self->Output_Error ($s);
    return;
  }

  if ($s =~ m/Assertion failed/) {
    # Definitely an error, can be given by the BCB6 compiler
    $self->Output_Error ($s);
    return;
  }

  if ($s =~ m/^ld: \d+\-\d+/) {
    # AIX linking errors from ld
    if ($s =~ m/^ld: 0711\-345/) {
      # But don't report the extra "check the map" message
      $self->Output_Normal ($s);
      return;
    }
    $self->Output_Error ($s);
    return;
  }

  if ($s =~ m/\s*warning:\s/i) {
    $self->Output_Warning ($s);
    return;
  }

  if ($s =~ m/exists but should be cleaned up/i) {
    $self->Output_Warning ($s);
    return;
  }

  if ($s =~ m/out of memory/) {
    $self->Output_Error ($s);
    return;
  }

  if ($s =~ m/undefined reference to/
      || $s =~ m/: cannot open/
      || $s =~ m/: cannot find/
      || $s =~ m/: multiple definition of/
      || $s =~ m/path name does not exist/) {
    # Look for linking errors too
    $self->Output_Error ($s);
    return;
  }

  if ($s =~ m/^make.*:.*Error [2-9]$/ ) {
    # We only want to flag as errors
    # make messages which are of the form:
    # make: ........Error 1
    # If we have Error 2 or higher, it is a recursive error, and has already
    # been flagged earlier at the occurrence of "Error 1".
    $self->Output_Normal ($s);
    return;
  }

  if (($s =~ m/\berror\b/i
       && $s !~ m/::error/i
       && $s !~ m;[/.]error;i
       && $s !~ m;error[/.];i
       && $s !~ m/ error\(s\), /
       && $s !~ m/error \(future\)/i)
      || $s =~ m/^Fatal\:/
      || $s =~ m/: fatal:/)
    {
      # Look for possible errors
      $self->Output_Error ($s);
      return;
    }

  if ($s =~ m/.*\d+\-\d+:? \([SI]\)/) {
    # Again, IBM's compilers speak in code langauge
    if ($s =~ m/.*Compilation will proceed shortly./) {
      # Ignore licensing messages
      $self->Output_Normal ($s);
      return;
    }
    $self->Output_Error ($s);
    return;
  }

  if ($s =~ m/^LINK : warning LNK4089:/) {
    # Ignore this warning from MSVC
    $self->Output_Normal ($s);
    return;
  }

  if ($s =~ m/^ld: \d+\-\d+ WARNING: Duplicate symbol:/) {
    # AIX reports a bazillion multiple defines when doing templates.
    $self->Output_Normal ($s);
    return;
  }

  if ($s =~ m/vnocompatwarnings/) {
    # HP-UX uses 'nocompatwarnings' as an option to the compiler.
    $self->Output_Normal ($s);
    return;
  }

  if ($s =~ m/in call to __pthread_cleanup_push\(extern/) {
    # Solaris 8 defines __pthread_cleanup_push as a macro which
    # causes warnings. See /usr/include/pthread.h and
    # $ACE_ROOT/examples/Timer_Queue/Thread_Timer_Queue_Test.cpp
    # for more information.
    $self->Output_Normal ($s);
    return;
  }

  if ($s =~ m/in call to ASN1_dup\(extern/) {
    # Sun CC 5.x flags a warning regarding a problem in the
    # OpenSSL headers where the ASN1_dup() function expects an
    # extern "C" int(*)() function for its first parameter but a
    # non-extern "C" int(*)() function is passed in instead.  This
    # is a problem with the OpenSSL headers, not ACE/TAO/CIAO.
    $self->Output_Normal ($s);
    return;
  }

  if ( $s =~ m/^make.*\*\*\*/ ) {
    $self->Output_Error ($s);
    return;
  }

  if (($s =~ m/warning/i
       && ($s !~ m/ warning\(s\)/ && $s !~ m/\-undefined warning/))
      || $s =~ m/info: /i
      || $s =~ m/^error \(future\)/i
      || $s =~ m/^.*\.(h|i|inl|hpp|ipp|cpp|java): /)
    {
      # Catch any other warnings
      $self->Output_Warning ($s);
      return;
    }

  if ($s =~ m/^.*\d+\-\d+:? \(W\)/) {
    # IBM's compilers don't say the word "warning" - check for their code
    if ($s =~ m/.*Compilation will proceed shortly./) {
      # Ignore licensing messages
      $self->Output_Normal ($s);
      return;
    }
    $self->Output_Warning ($s);
    return;
  }

  if ($s =~ m/ defined in discarded section /) {
    # Debion GCC compiler bug with templates/inline bits
    $self->Output_Error ($s);
    return;
  }

  # Must be normal
  $self->Output_Normal ($s);
}

1
