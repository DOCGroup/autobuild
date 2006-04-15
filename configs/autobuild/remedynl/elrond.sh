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

sh $HOME/ACE/autobuild/configs/autobuild/remedynl/elrond_icc64.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/elrond_icc32.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/elrond_gcc.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/elrond_autoconf.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/elrond_ondemand.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/elrond_sendfile.sh
