#
# $Id$
#

package print_os_version;

use strict;
use warnings;

use Cwd;
use File::Path;

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
    return 1;
}

##############################################################################

main::RegisterCommand ("print_os_version", new print_os_version());
