#!/bin/sh
#
# $Id$
#

PATH=$HOME/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin
export PATH

exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                   $HOME/autobuild/configs/autobuild/slytherin/OpenBSD_Full.xml 2>&1
