#!/bin/sh
#
# $Id$
#

cd /build/ACE/autobuild
PATH=/usr/local/bin:$PATH
CVSROOT=:ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository
CVS_RSH=ssh
export CVSROOT
export CVS_RSH
export PATH

cvs -z9 up -P -d

/build/ACE/autobuild/configs/autobuild/remedynl/tribeardacc.sh
/build/ACE/autobuild/configs/autobuild/remedynl/tribeardgcc.sh
