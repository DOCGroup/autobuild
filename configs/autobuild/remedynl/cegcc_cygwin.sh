#!/bin/sh
#
# $Id$
#
cd /cygdrive/c/ACE/autobuild/
svn up
exec /usr/bin/perl /cygdrive/c/ACE/autobuild/autobuild.pl /cygdrive/c/ACE/autobuild/configs/autobuild/remedynl/cegcc_cygwin.xml
