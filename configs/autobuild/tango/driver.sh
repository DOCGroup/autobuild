#!/pkg/gnu/bin/bash
#
# $Id$
#

PATH=:$HOME/bin:/pkg/gnu2k1/bin:/pkg/gnu/bin:$PATH
export PATH

exec /pkg/perl-5.6.1/bin/perl -w $HOME/autobuild/autobuild.pl \
                     $HOME/autobuild/configs/autobuild/tango/SunOS_GCC_2_95.xml

