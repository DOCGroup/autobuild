#!/bin/sh
#
# $Id$
#
CVSROOT=:ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository
export CVSROOT

CVS_RSH=ssh
export CVS_RSH

cd $HOME/ACE/autobuild

cvs -z9 up -P -d

$HOME/ACE/autobuild/configs/autobuild/remedynl/driverpc2valgrind.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/driverpc2gccnoinline.sh
