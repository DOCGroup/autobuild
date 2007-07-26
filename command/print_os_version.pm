#
# $Id$
#

package print_os_version;

use strict;
use warnings;

use Cwd;
use File::Path;
use Sys::Hostname;
use POSIX qw(:time_h);

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

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;
    my $useuname = shift;

    main::PrintStatus ('Config', "print OS Version" );

    print "<h3>Hostname</h3>\n";
    print hostname(), "\n";

    if(-x "/bin/uname"){
        print "<h3>OS version (uname -a)</h3>\n";
        system("/bin/uname -a");
    }

    if(-x "/usr/bin/uname"){
        print "<h3>OS version (uname -a)</h3>\n";
        system("/usr/bin/uname -a");
    }

    if(-x "/usr/bin/oslevel"){
        print "<h3>AIX version (oslevel)</h3>\n";
        system("/usr/bin/oslevel");
    }

    if(-r "/etc/redhat-release"){
        print "<h3>RedHat Linux Version (/etc/redhat-release)</h3>\n";
	system("cat /etc/redhat-release");
    }

    if(-r "/etc/SuSE-release"){
        print "<h3>SuSE Linux Version (/etc/SuSE-release)</h3>\n";
        system("cat /etc/SuSE-release");
    }

    if(-r "/etc/debian_version"){
        print "<h3>Debian Linux Version (/etc/debian_version)</h3>\n";
	system("cat /etc/debian_version");
    }

    if(-r "/proc/version"){
        print "<h3>Linux Kernel Version (/proc/version)</h3>\n";
	system("cat /proc/version");
    }

    if(-r "/usr/sbin/prtdiag"){
        print "<h3>Sun System Information (/usr/sbin/prtdiag)</h3>\n";
        system("/usr/sbin/prtdiag");
    }

    if(lc $useuname eq "useuname"){
        print "<h3>OS version (uname -a)</h3>\n";
        system("uname -a");
        print "\n";
    }

    if(-r "/proc/cpuinfo"){
        my $systeminfo = `cat /proc/cpuinfo` ;

        print "<h3>Processor info</h3>\n";
        print filter_info($systeminfo, "model name") . "\n";
    }

    if(-r "/proc/meminfo"){
        my $systeminfo = `cat /proc/meminfo` ;

        print "<h3>Memory info</h3>\n";
        print filter_info($systeminfo, "MemTotal") . "\n";
    }

    if($^O eq "MSWin32"){
        my $systeminfo = `systeminfo` ;

        print "<h3>Microsoft Version</h3>\n";
        print filter_info($systeminfo, "os") . "\n";

        print "<h3>Processor info</h3>\n";
        print filter_info($systeminfo, "processor") . "\n";

        print "<h3>Memory info</h3>\n";
        print filter_info($systeminfo, "total physical memory") . "\n";
        print filter_info($systeminfo, "virtual memory") . "\n";
    }

    print "<h3>Approximate BogoMIPS (larger means faster)</h3>\n",
          $self->delay_factor(), "\n";

    print "<h3>Environment:</h3>\n";
    my $name;
    foreach $name (sort keys %ENV) {
        print "$name = $ENV{$name}\n";
    }
    print "\n";

    return 1;
}

##############################################################################

sub filter_info {
    my $str = shift ;
    my $pattern = shift ;
    my @result ;
    my $doing = 0 ;
    foreach my $line (split("\n",$str)) {
        if ($line =~ /^($pattern)/i) {
            $doing = 1 ;
            push(@result,$line) ;
        } elsif (($doing) && ($line =~ /^\s+/o)) {
            push(@result,$line) ;
        } else {
            $doing = 0 ;
        }
    }
    return join("\n",@result) ;
}

##############################################################################

sub delay_factor {
  my($lps)    = 128;
  my($factor) = 1;
  my($fudge)  = 80;

  if ($^O eq 'solaris') {
    $fudge = 45;
  }
  elsif ($^O eq 'MSWin32' || $^O eq 'cygwin') {
    $fudge = 63;
  }

  ## Keep increasing the loops per second until the amount of time
  ## exceeds the number of clocks per second.  The original code
  ## did not multiply $ticks by 8 but, for faster machines, it doesn't
  ## seem to return false values.  The multiplication is done to minimize
  ## the amount of time it takes to determine the correct factor.
  while(($lps <<= 1)) {
    my($ticks) = clock();
    for(my $i = $lps; $i >= 0; $i--) {
    }
    $ticks = clock() - $ticks;
    if ($ticks * 8 >= CLOCKS_PER_SEC) {
      $factor = ((($lps / $ticks) * (CLOCKS_PER_SEC * 8)) * $fudge) / 500000;
      last;
    }
  }

  return $factor;
}

##############################################################################

main::RegisterCommand ("print_os_version", new print_os_version());
