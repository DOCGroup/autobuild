#!/bin/sh
#
# $Id$
#

PATH=.:$HOME/bin:/opt/SUNWspro_6.1/SUNWspro/bin:/pkg/perl-5.6.1/bin/usr/ccs/bin:/pkg/gnu2k1/bin:/pkg/gnu/bin:/usr/bin:/pkg/purify/purify-5.1-solaris2:$PATH
export PATH

exec /pkg/perl-5.6.1/bin/perl $HOME/autobuild/autobuild.pl \
          $HOME/autobuild/configs/autobuild/ace/SunOS_FORTE_UPDATE_1.xml
