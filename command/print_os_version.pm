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

    if(lc $useuname eq "useuname"){
        print "<h3>OS version (uname -a)</h3>\n";
        system("uname -a");
        print "\n";
    }

    if($^O eq "MSWin32"){
        print "<h3>Microsoft Version (VER)</h3>\n";
	system("VER");
    }

    print "<h3>Approximate BogoMIPS (smaller means faster)</h3>\n",
          $self->delay_factor(), "\n";

    return 1;
}

##############################################################################

sub delay_factor {
  my($lps)    = 128;
  my($factor) = 1;

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
      $factor = 500000 / (($lps / $ticks) * CLOCKS_PER_SEC);
      last;
    }
  }

  return $factor;
}

##############################################################################

main::RegisterCommand ("print_os_version", new print_os_version());
