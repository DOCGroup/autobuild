#!/bin/sh
#
# $Id$
#

cd /home/build/ACE
PATH=/usr/local/bin:$PATH
CVSROOT=jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository
CVS_RSH=ssh
export CVSROOT
export CVS_RSH
export PATH

cvs -z9 up -P -d

exec /opt/perl/bin/perl /home/build/ACE/autobuild/autobuild.pl \
                             /home/build/ACE/autobuild/configs/autobuild/remedynl/tribeardacc.xml
