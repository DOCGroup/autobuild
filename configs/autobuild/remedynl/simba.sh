#!/bin/sh
#
# $Id$
#

cd /home/build/ACE/autobuild
PATH=/usr/local/bin:$PATH
CVSROOT=:ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository
CVS_RSH=ssh
export CVSROOT
export CVS_RSH
export PATH

cvs -z9 up -P -d

/home/build/ACE/autobuild/configs/autobuild/remedynl/simbagcc.sh
