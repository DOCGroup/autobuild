#!/pkg/gnu/bin/bash
#
# $Id$
#

PATH=/opt/SUNWspro_6.2/SUNWspro/bin:/pkg/perl-5.6.1/bin:/pkg/gnu/bin:$PATH
export PATH

exec /pkg/perl-5.6.1/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/danzon/SunOS_SunCC51.xml 2>&1 

