#!/bin/sh
#
# $Id$
#
CVS_RSH=/usr/bin/ssh
export CVS_RSH

/usr/bin/perl $HOME/autobuild/autobuild.pl \
	autobuild/configs/autobuild/ace_isis/RH8_Static_Core.xml >/dev/null 2>&1 </dev/null

