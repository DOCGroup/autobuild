#!/bin/sh
#
# $Id$
#
CVSROOT=:ext:ucibuilds@cvs.doc.wustl.edu:/project/cvs-repository
export CVSROOT

CVS_RSH=/usr/bin/ssh
export CVS_RSH

cd /project/curufin/bugzilla/SingleThreaded
cvs -r -z 3 -Q checkout -P autobuild

exec perl -w ./autobuild/autobuild.pl autobuild/configs/autobuild/curufin/SingleThreaded.xml >/dev/null 2>&1 </dev/null

