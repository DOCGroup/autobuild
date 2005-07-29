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

$HOME/ACE/autobuild/configs/autobuild/remedynl/eowyn_any.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/eowyn_gcc.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/eowyn_gccwarn.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/eowyn_ipv6wchar.sh
