#!/bin/sh
#
# $Id$
#
CVS_RSH=/usr/bin/ssh
export CVS_RSH

/usr/bin/perl $HOME/autobuild/autobuild.pl \
	$HOME/autobuild/configs/autobuild/ace_isis/RH8_Static_Core.xml

