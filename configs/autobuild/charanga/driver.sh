#!/bin/sh
#
# $Id$
#

exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/charanga/Debian_Minimum_Static.xml 2>&1

