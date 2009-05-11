#!/bin/sh
#
# $Id$
#
cd /home/build/ACE/autobuild/
svn up
exec /usr/bin/perl /home/build/ACE/autobuild/autobuild.pl /home/build/ACE/autobuild/configs/autobuild/remedynl/cegcc_cygwin.xml