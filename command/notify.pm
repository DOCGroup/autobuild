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

##############################################################################

sub Run ($)
{
    my $self      = shift;
    my $options   = shift;
    my $log_file  = main::GetVariable('log_file');
    my $root      = main::GetVariable('root');
    my $mail_prog = main::GetVariable('mail_prog') || '/bin/mail';
    my $mail_map  = main::GetVariable('mail_map');
    my $domain    = $self->getDomain();
    my $revctrl   = 'svn';
    my $compiler  = 'g++';
    my $subject   = 'Compile Errors';

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

    if ($options =~ s/subject='([^']+)'//) {
      $subject = $1;
    }
    elsif ($options =~ s/subject=([^\s]+)//) {
      $subject = $1;
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
      my $started = undef;
      my $class   = undef;
      my $cfile   = undef;
      my $dir     = '.';
      my $proceed = undef;
      my $current = undef;
      my @lines   = ();

      while(<$fh>) {
        if (/^#################### (.*)$/) {
          my $section = $1;
          if ($section =~ /^compile\s/i) {
            $proceed = 1;
          }
          elsif ($proceed) {
            $proceed = undef;
          }
        }
        if ($proceed) {
          push(@lines, $_);
          if (/Entering\s+directory\s+\`(.*)\'$/) {
            $dir = $1;
          }
          elsif (/Leaving\s+directory\s+/) {
            push(@{$files{$current}}, join('', @lines)) if (defined $current);
            $current = undef;
            @lines   = ();
          }
          elsif (index($_, $compiler) == 0) {
            push(@{$files{$current}}, join('', @lines)) if (defined $current);
            $started = 1;
            $class   = undef;
            $current = undef;
            @lines   = ($_);
          }
          elsif ($started) {
            if (/no\s+rule\s+to\s+make\s+target\s+`(.*)'/) {
              $current = "$dir/$1";
              $files{$current} = ["$current is missing"];
              $started = undef;
            }
            elsif (/^([^:]+):(\d+):\d+:\s*error:\s+(.*):\s*no\s+such\s+file/i ||
                   /^"([^"]+)",\s+line\s+(\d+):\s*error:\s*could\s+not\s+open\s+include\s+file\s+"([^"]+)"/i) {
              $current   = "$dir/$1";
              my $number = $2;
              my $file   = $3;
              $file = "$dir/$file" if ($file !~ /\//);
                
              $files{$current}  = [] if (!defined $files{$current});

              $files{$file} = [] if (!defined $files{$file});
              $started = undef;
            }
            elsif (/^[^:]+:\d+:\s*error:\s*prototype\s+for\s+'.*'\s+does\s+not\s+match\s+any\s+in\s+class\s+'(.*)'/i) {
              $class = $1;
            }
            elsif ($class) {
              if (/^([^:]+):(\d+):\s*error:\s*candidate[s]?\s+(are|is):/i) {
                $current = $1;
                $current = "$dir/$current" if ($current !~ /\//);
                $cfile = $current;
                $files{$current} = [] if (!defined $files{$current});
              }
              elsif (/^([^:]+):(\d+):\s*error:/i) {
                $current = $1;
                $current = "$dir/$current" if ($current !~ /\//);
                if (defined $cfile && $current eq $cfile) {
                  $files{$current} = [] if (!defined $files{$current});
                }
                else {
                  $cfile = undef;
                }
              }
            }
            elsif (/^([^:]+):(\d+):\s*error:/i ||
                   /^"([^"]+)",\s+line\s+(\d+):\s*error:/i) {
              $current = "$dir/$1";
              $files{$current} = [] if (!defined $files{$current});
              $started = undef;
            }
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

          my $mh = new FileHandle();
          my $sopt = ($^O eq 'linux' ? "-s '$subject'" : '');
          if (open($mh, "| $mail_prog $sopt $email")) {
            print $mh "Subject:$subject\n" if ($sopt eq '');
            print $mh "$msg\n";
            close($mh);
          }
          else {
            print STDERR __FILE__, ": ERROR: Unable to run $mail_prog\n";
            return 0;
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
