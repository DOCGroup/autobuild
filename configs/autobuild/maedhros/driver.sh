#!/bin/sh
#
# $Id$
#
CVSROOT=:ext:ucibuilds@cvs.doc.wustl.edu:/project/cvs-repository
export CVSROOT

CVS_RSH=/usr/bin/ssh
export CVS_RSH

cd /project/maedhros/bugzilla/Core
cvs -r -z 3 -Q checkout -P autobuild

PATH=/usr/local/redhat-7.1/gcc-3.0.2/bin:$PATH
export PATH

LD_LIBRARY_PATH=$ACE_ROOT/ace:/usr/local/redhat-7.1/gcc-3.0.2/lib
export LD_LIBRARY_PATH

exec perl -w ./autobuild/autobuild.pl autobuild/configs/autobuild/maedhros/Core.xml >/dev/null 2>&1 </dev/null

