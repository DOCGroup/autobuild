#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild
PATH=/usr/local/bin:/etc:/opt/SUNWspro/bin:/usr/ccs/bin:/usr/ucb:$PATH
CVSROOT=:ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository
CVS_RSH=ssh
export CVSROOT
export CVS_RSH
export PATH

cvs -z9 up -P -d

exec /usr/local/bin/perl $HOME/ACE/autobuild/autobuild.pl \
                             $HOME/ACE/autobuild/configs/autobuild/remedynl/SunForte.xml
