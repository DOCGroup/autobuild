#!/bin/sh
#
# $Id$
#

CVSROOT=:ext:ossama@cvs.doc.wustl.edu:/project/cvs-repository
export CVSROOT

CVS_RSH=ssh
export CVS_RSH

cd $HOME/work/autobuild

cvs -z9 up -P -d

exec /usr/bin/perl $HOME/work/autobuild/autobuild.pl \
  $HOME/work/autobuild/configs/autobuild/ossama/void-gcc-4.0.xml

