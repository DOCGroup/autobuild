
package command::Process::Process;

use strict;
use POSIX "sys_wait_h";
use Cwd;
use File::Basename;
use Config;

# we need to import this package to get the value of $OSNAME
use English;

if ( $OSNAME eq "MSWin32" ) {
    require command::Process::ProcessWin32;   
}
else # ( $OSNAME neq "MSWin32" )
{
    require command::Process::ProcessUnix;
}

1;
