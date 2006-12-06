#
# $Id$
#

package Notify;

use strict;
use warnings;

use Cwd;
use FileHandle;
use File::Basename;
use Sys::Hostname;

use common::prettify;

use vars qw(@ISA);
@ISA = qw(Prettify);

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
    my @vars = ('root', 'log_file');

    foreach my $var (@vars) {
      my $val = main::GetVariable ($var);
      if (!defined $val) {
          print STDERR __FILE__, ": Requires \"$var\" variable\n";
          return 0;
      }
    }

    return 1;
}

##############################################################################

sub getDomain
{
  my($domain) = undef;
  my($host)   = hostname();

  if (defined $host) {
    ## First try the hostname
    if ($host =~ /[^\.]+\.(.*)/) {
      $domain = $1;
    }
    else {
      ## Next try the hosts file
      my($hosts) = ($^O eq 'MSWin32' ?
                      "$ENV{SystemRoot}/system32/drivers/etc/hosts" :
                      '/etc/hosts');
      my($fh)    = new FileHandle();
      if (open($fh, $hosts)) {
        while(<$fh>) {
          if (/$host\.([^\s]+)/) {
            $domain = $1;
            last;
          }
        }
        close($fh);
      }

      if (!defined $domain) {
        ## Next try ipconfig on Windows
        if ($^O eq 'MSWin32') {
          if (open($fh, 'ipconfig /all |')) {
            while(<$fh>) {
              if (/Primary\s+DNS\s+Suffix[^:]+:\s+(.*)/) {
                $domain = $1;
              }
              elsif (/DNS\s+Suffix\s+Search[^:]+:\s+(.*)/) {
                $domain = $1;
              }
            }
            close($fh);
          }
        }
        else {
          ## Try /etc/resolv.conf on UNIX
          if (open($fh, '/etc/resolv.conf')) {
            while(<$fh>) {
              if (/search\s+(.*)/) {
                $domain = $1;
                last;
              }
            }
            close($fh);
          }
        }
      }
    }
  }
  return $domain;
}

sub getEmail ($)
{
  my $self     = shift;
  my $revctrl  = shift;
  my $file     = shift;
  my $domain   = shift;
  my $mail_map = shift;
  my $email    = undef;
  my $pwd      = getcwd();

  if (chdir(dirname($file))) {
    my($version)  = undef;
    my($username) = undef;
    my($ph) = new FileHandle();
    if (open($ph, "$revctrl status -v " . basename($file) . "|")) {
      if ($revctrl =~ /cvs/) {      
        while(<$ph>) {
          if (/working\s+revision\s*:\s*([^\s]+)/i) {
            $version = $1;
          }
        }
      }
      elsif ($revctrl =~ /svn/) {
        while(<$ph>) {
          if (/\d+\s+\d+\s+([^\s]+)/) {
            $username = $1;
          }
        }
      }
      close($ph);
    }

    if (defined $version) {
      if (open($ph, "$revctrl log -r$version " . basename($file) . "|")) {
        if ($revctrl =~ /cvs/) {      
          while(<$ph>) {
            if (/date:.*author:\s+([^;]+)/i) {
              $username = $1;
            }
          }
        }
        close($ph);
      }
    }

    if (defined $username) {
      if (defined $$mail_map{$username}) {
        $email = $$mail_map{$username};
      }
      else {
        $email = $username . '@' . $domain;
      }
    }
    else {
      print STDERR __FILE__, ": WARNING: ",
                   "Unable to determine the last user to modify $file\n";
    }
    chdir($pwd);
  }
  else {
    print STDERR __FILE__, ": WARNING: ",
                 "Unable to chdir to ", dirname($file), "\n";
  }
  
  return $email;
}

sub resolveLinks {
  my $self = shift;
  my $file = shift;

  if (-l $file) {
    my($contents) = readlink($file);
    if (index($contents, '../') == 0) {
      $file = dirname($file) . '/' . $contents;
    }
    else {
      $file = $contents;
    }
  }

  return $file;
}

sub sendEmail {
  my $self      = shift;
  my $mail_prog = shift;
  my $subject   = shift;
  my $msg       = shift;
  my @email     = @_;
  my $mh        = new FileHandle();
  my $sopt      = ($^O eq 'linux' ? "-s '$subject'" : '');

  if (open($mh, "| $mail_prog $sopt @email")) {
    print $mh "Subject:$subject\n" if ($sopt eq '');
    print $mh "$msg\n";
    close($mh);
  }
  else {
    print STDERR __FILE__, ": ERROR: Unable to run $mail_prog\n";
    return 0;
  }
}

sub collectCompileErrors {
  my $self  = shift;
  my $line  = shift;
  my $files = $self->{'parser'}->{'files'};

  push(@{$self->{'parser'}->{'lines'}}, $line);
  if ($line =~ /Entering\s+directory\s+\`(.*)\'$/) {
    $self->{'parser'}->{'dir'} = $1;
  }
  elsif ($line =~ /Leaving\s+directory\s+/) {
   if (defined $self->{'parser'}->{'current'}) {
      push(@{$$files{$self->{'parser'}->{'current'}}},
           join('', @{$self->{'parser'}->{'lines'}}));
    }
    $self->{'parser'}->{'current'}  = undef;
    $self->{'parser'}->{'lines'} = [];
  }
  elsif (index($line, $self->{'parser'}->{'compiler'}) == 0) {
    if (defined $self->{'parser'}->{'current'}) {
      push(@{$$files{$self->{'parser'}->{'current'}}},
           join('', @{$self->{'parser'}->{'lines'}}));
    }
    $self->{'parser'}->{'started'} = 1;
    $self->{'parser'}->{'class'}   = undef;
    $self->{'parser'}->{'current'} = undef;
    $self->{'parser'}->{'lines'}   = [$line];
  }
  elsif ($self->{'parser'}->{'started'}) {
    if ($line =~ /no\s+rule\s+to\s+make\s+target\s+`(.*)'/) {
      $self->{'parser'}->{'current'} = "$self->{'parser'}->{'dir'}/$1";
      $$files{$self->{'parser'}->{'current'}} =
            ["$self->{'parser'}->{'current'} is missing"];
      $self->{'parser'}->{'started'} = undef;
    }
    elsif ($line =~ /^([^:]+):(\d+):\d+:\s*error:\s+(.*):\s*no\s+such\s+file/i ||
           $line =~ /^"([^"]+)",\s+line\s+(\d+):\s*error:\s*could\s+not\s+open\s+include\s+file\s+"([^"]+)"/i) {
      my $number = $2;
      my $file   = $3;
      $self->{'parser'}->{'current'} = "$self->{'parser'}->{'dir'}/$1";
      $file = "$self->{'parser'}->{'dir'}/$file" if ($file !~ /\//);

      if (!defined $$files{$self->{'parser'}->{'current'}}) {
        $$files{$self->{'parser'}->{'current'}} = [];
      }

      $$files{$file} = [] if (!defined $$files{$file});
      $self->{'parser'}->{'started'} = undef;
    }
    elsif ($line =~ /^[^:]+:\d+:\s*error:\s*prototype\s+for\s+'.*'\s+does\s+not\s+match\s+any\s+in\s+class\s+'(.*)'/i) {
      $self->{'parser'}->{'class'} = $1;
    }
    elsif ($self->{'parser'}->{'class'}) {
      if ($line =~ /^([^:]+):(\d+):\s*error:\s*candidate[s]?\s+(are|is):/i) {
        $self->{'parser'}->{'current'} = $1;
        if ($self->{'parser'}->{'current'} !~ /\//) {
          $self->{'parser'}->{'current'} =
            "$self->{'parser'}->{'dir'}/$self->{'parser'}->{'current'}";
        }
        $self->{'parser'}->{'cfile'} = $self->{'parser'}->{'current'};
        if (!defined $$files{$self->{'parser'}->{'current'}}) {
          $$files{$self->{'parser'}->{'current'}} = [];
        }
      }
      elsif ($line =~ /^([^:]+):(\d+):\s*error:/i) {
        $self->{'parser'}->{'current'} = $1;
        if ($self->{'parser'}->{'current'} !~ /\//) {
          $self->{'parser'}->{'current'} =
            "$self->{'parser'}->{'dir'}/$self->{'parser'}->{'current'}";
        }
        if (defined $self->{'parser'}->{'cfile'} &&
            $self->{'parser'}->{'current'} eq $self->{'parser'}->{'cfile'}) {
          if (!defined $$files{$self->{'parser'}->{'current'}}) {
            $$files{$self->{'parser'}->{'current'}} = [];
          }
        }
        else {
          $self->{'parser'}->{'cfile'} = undef;
        }
      }
    }
    elsif ($line =~ /^([^:]+):(\d+):.*error/i ||
           $line =~ /^"([^"]+)",\s+line\s+(\d+):.*error/i) {
      $self->{'parser'}->{'current'} = "$self->{'parser'}->{'dir'}/$1";
      if (!defined $$files{$self->{'parser'}->{'current'}}) {
        $$files{$self->{'parser'}->{'current'}} = [];
      }
      $self->{'parser'}->{'started'} = undef;
    }
  }
}

sub collectTestErrors {
  my $self = shift;
  my $line = shift;
  $self->Test_Handler($line);
}

sub Output_Subsection {
  my $self = shift;
  my $line = shift;
  $self->{'parser'}->{'current'} = $line;
  $self->{'parser'}->{'tests'}->{$line} = [];
}

sub Output_Error {
  my $self = shift;
  my $line = shift;
  my $key  = $self->{'parser'}->{'current'} || '';
  push(@{$self->{'parser'}->{'tests'}->{$key}}, $line);
}

sub Output_Warning {
}

sub Output_Normal {
}

##############################################################################

sub Run ($)
{
    my $self       = shift;
    my $options    = shift;
    my $log_file   = main::GetVariable('log_file');
    my $root       = main::GetVariable('root');
    my $mail_prog  = main::GetVariable('mail_prog') || '/bin/mail';
    my $mail_map   = main::GetVariable('mail_map');
    my $domain     = $self->getDomain();
    my $revctrl    = 'svn';
    my $compiler   = 'g++';
    my $csubject    = 'Compile Errors';
    my $tsubject   = 'Test Errors';
    my $lead_email = '';

    # replace all '\x22' with '"'
    $options =~ s/\\x22/"/g;

    if ($options =~ s/compiler='([^']+)'//) {
      $compiler = $1;
    }
    elsif ($options =~ s/compiler=([^\s]+)//) {
      $compiler = $1;
    }

    if ($options =~ s/revctrl='([^']+)'//) {
      $revctrl = $1;
    }
    elsif ($options =~ s/revctrl=([^\s]+)//) {
      $revctrl = $1;
    }

    if ($options =~ s/compile_subject='([^']+)'//) {
      $csubject = $1;
    }
    elsif ($options =~ s/compile_subject=([^\s]+)//) {
      $csubject = $1;
    }

    if ($options =~ s/test_subject='([^']+)'//) {
      $tsubject = $1;
    }
    elsif ($options =~ s/test_subject=([^\s]+)//) {
      $tsubject = $1;
    }

    if ($options =~ s/lead_email='([^']+)'//) {
      $lead_email = $1;
    }
    elsif ($options =~ s/lead_email=([^\s]+)//) {
      $lead_email = $1;
    }

    if (!-r $root || !-d $root) {
      mkpath($root);
    }

    my $fh = new FileHandle();
    my %mail_map = ();
    if (defined $mail_map) {
      if (open($fh, $mail_map)) {
        while(<$fh>) {
          if (/^([^\s]+)\s+([^\s]+)$/) {
            $mail_map{$1} = $2;
          }
        }
        close($fh);
      }
      else {
        print STDERR __FILE__,
                     ": ERROR: Unable to open the email map: $mail_map\n";
        return 0;
      }
    }

    if (open($fh, "$root/$log_file")) {
      my %files   = ();
      my %tests   = ();
      my $proceed = undef;
      my %collectors = ('compile' => \&collectCompileErrors,
                        'test'    => \&collectTestErrors,
                       );

      while(<$fh>) {
        if (/^#################### (.*)$/) {
          my $section = $1;
          if ($section =~ /^(compile)\s/i) {
            $proceed = lc($1);
          }
          elsif ($section =~ /^(test)\s/i) {
            $proceed = lc($1);
          }
          elsif ($proceed) {
            $proceed = undef;
          }

          $self->{'parser'} = {'started'  => undef,
                               'class'    => undef,
                               'cfile'    => undef,
                               'dir'      => '.',
                               'current'  => undef,
                               'compiler' => $compiler,
                               'lines'    => [],
                               'files'    => \%files,
                               'tests'    => \%tests,
                              };
        }
        if (defined $proceed) {
          my $func = $collectors{$proceed};
          if (defined $func) {
            $self->$func($_);
          }
        }
      }
      close($fh);

      foreach my $file (sort keys %files) {
        my $email = $self->getEmail($revctrl, $self->resolveLinks($file),
                                    $domain, \%mail_map);
        if (defined $email) {
          my $msg = '';
          if (scalar(@{$files{$file}}) == 0) {
            $msg = "$file may be missing";
          }
          else {
            foreach my $line (@{$files{$file}}) {
              $msg .= $line;
            }
          }
          $self->sendEmail($mail_prog, $csubject, $msg, $lead_email, $email);
        }
      }

      if ($lead_email ne '') {
        foreach my $test (sort keys %tests) {
          if (defined $tests{$test}->[0]) {
            my $msg = "$test\n";
            foreach my $line (@{$tests{$test}}) {
              $msg .= $line;
            }
            $self->sendEmail($mail_prog, $tsubject, $msg, $lead_email);
          }
        }
      }
    }
    else {
      print STDERR __FILE__, ": ERROR: Unable to read $log_file\n";
      return 0;
    }

    return 1;
}

##############################################################################

main::RegisterCommand ("notify", new Notify ());
