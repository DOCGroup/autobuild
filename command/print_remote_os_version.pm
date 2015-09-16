#

package print_remote_os_version;

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

    my $remote_shell = main::GetVariable ('remote_shell');

    if (!defined $remote_shell) {
        print STDERR __FILE__, ": Requires \"remote_shell\" variable\n";
        return 0;
    }

    return 1;
}

##############################################################################

my $remote_script = <<'__REMOTE_SCRIPT__';

package remote_os_version;

use strict;
use warnings;

use Cwd;
use File::Path;
use Sys::Hostname;
use POSIX qw(:time_h);

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {};

    bless ($self, $class);
    return $self;
}

sub do_print ($)
{
    my $self = shift;

    print "<h3>Hostname</h3>\n";
    print hostname(), "\n";

    if(-x "/bin/uname"){
        print "<h3>OS version (uname -a)</h3>\n";
        system("/bin/uname -a");
    } else {
      if(-x "/usr/bin/uname"){
          print "<h3>OS version (uname -a)</h3>\n";
          system("/usr/bin/uname -a");
      }
    }

    if(-x "/usr/bin/oslevel"){
        print "<h3>AIX version (oslevel)</h3>\n";
        system("/usr/bin/oslevel");
    }

    if(-x "/usr/bin/lsb_release"){
        print "<h3>Linux Standard Base and Distribution information (lsb_release -a)</h3>\n";
        system("/usr/bin/lsb_release -a");
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

    if(-r "/etc/release"){
        print "<h3>OS release (/etc/release)</h3>\n";
        system("cat /etc/release");
    }

    if(-r "/etc/version"){
        print "<h3>OS version (/etc/version)</h3>\n";
        system("cat /etc/version");
    }

    if(-r "/usr/local/ngclinux/x86_64/version"){
        print "<h3>NGC Linux release (/usr/local/ngclinux/x86_64/version)</h3>\n";
        system("cat /usr/local/ngclinux/x86_64/version");
    }

    if(-r "/usr/local/ceel/x86_64/version"){
        print "<h3>CEEL release (/usr/local/ceel/x86_64/version)</h3>\n";
        system("cat /usr/local/ceel/x86_64/version");
    }

    if(-r "/var/emulab/boot/nodeid"){
        print "<h3>Emulab NodeId(/var/emulab/boot/nodeid)</h3>\n";
        system("cat /var/emulab/boot/nodeid");
    }

    if(-x "/bin/ip"){
        print "<h3>Linux IP network address information (ip addr show)</h3>\n";
        system("/bin/ip addr show");
    } else {
        if(-x "/sbin/ip"){
            print "<h3>Linux IP network address information (ip addr show)</h3>\n";
            system("/sbin/ip addr show");
        }
    }

    if(-x "/usr/sbin/prtdiag"){
        print "<h3>Sun System Information (/usr/sbin/prtdiag)</h3>\n";

        # NOTE: prtdiag(1M) is not supported in non-global zones.
        #       An administrator must redirect global prtdiag output to a
        #       file in the non-global zone (i.e.: /etc/zones/prtdiag).
        my $zoned;

        if(-x "/usr/bin/zonename"){
            my $zone = `/usr/bin/zonename`;
            chomp($zone);

            if("global" ne $zone){
                system("cat /etc/zones/prtdiag");
                $zoned = 1;
            }
        }

        if(!$zoned){
            system("/usr/sbin/prtdiag");
        }
    }

    if(-r "/bin/df"){
        print "<h3>Disk space information (df -H)</h3>\n";
        system("/bin/df -H");
    }

    if(-r "/proc/cpuinfo"){
        my $systeminfo = `cat /proc/cpuinfo` ;

        print "<h3>Processor info</h3>\n";
        print filter_info($systeminfo, "(model name)|(cpu[ \t]*\:)") . "\n";
    }

    if(-r "/proc/meminfo"){
        my $systeminfo = `cat /proc/meminfo` ;

        print "<h3>Memory info</h3>\n";
        print filter_info($systeminfo, "MemTotal") . "\n";
    }

    print "<h3>Approximate BogoMIPS (larger means faster)</h3>\n",
          $self->delay_factor(), "\n";

    return 1;
}

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

sub delay_factor {
  my($lps)    = 128;
  my($factor) = 1;
  my($fudge)  = 80;

  if ($^O eq 'solaris') {
    $fudge = 45;
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

(new remote_os_version())->do_print();

exit 0;

__REMOTE_SCRIPT__

sub Run ($)
{
    my $self = shift;

    my $remote_shell = main::GetVariable ('remote_shell');

    main::PrintStatus ('Config', "print Remote OS Version - remote shell=$remote_shell" );

    open REMOTE_CMD, "| $remote_shell perl"
        or die "can't fork: $!";

    print REMOTE_CMD $remote_script;

    close REMOTE_CMD; # or die "bad remote cmd: $! $?";

    return 1;
}

##############################################################################

main::RegisterCommand ("print_remote_os_version", new print_remote_os_version());
