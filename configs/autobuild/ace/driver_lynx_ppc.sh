#!/bin/sh
#
# $Id$
#

PATH=.:$HOME/bin:/pkg/perl-5.6.1/bin:/pkg/gnu2k1/bin:/pkg/gnu/bin:/usr/bin:$PATH
export PATH

exec /pkg/perl-5.6.1/bin/perl $HOME/autobuild/autobuild.pl \
          $HOME/autobuild/configs/autobuild/ace/LYNX_PPC.xml
