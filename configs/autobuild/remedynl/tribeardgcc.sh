#!/bin/sh
#
# $Id$
#

cd /build/ACE
PATH=/usr/local/bin:$PATH
CVSROOT=:ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository
CVS_RSH=ssh
export CVSROOT
export CVS_RSH
export PATH

cvs -z9 up -P -d

exec /opt/perl/bin/perl /build/ACE/autobuild/autobuild.pl \
                             /build/ACE/autobuild/configs/autobuild/remedynl/tribeardgcc.xml
