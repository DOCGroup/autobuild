#!/bin/sh
#
# $Id$
#

cd /build/ACE
PATH=/usr/local/bin:$PATH
CVSROOT=jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository
CVS_RSH=ssh
export CVSROOT
export CVS_RSH
export PATH

cvs -z9 up -P -d

exec /usr/local/bin/perl /build/ACE/autobuild/autobuild.pl \
                             /build/ACE/autobuild/configs/autobuild/remedynl/hpux.xml
