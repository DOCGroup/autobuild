#!/bin/sh
#
# $Id$
#

cd $HOME/autobuild
PATH=$HOME/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin
CVSROOT=cvs.doc.wustl.edu:/project/cvs-repository
CVS_RSH=ssh
export CVSROOT
export CVS_RSH
export PATH

cvs -z9 up -P -d

exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                   $HOME/autobuild/configs/autobuild/slytherin/OpenBSD_Single_Threaded.xml 2>&1
