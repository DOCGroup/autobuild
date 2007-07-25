#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

sh $HOME/ACE/autobuild/configs/autobuild/remedynl/elrond_cidlc.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/elrond_icc64.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/elrond_icc32.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/elrond_gcc.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/elrond_autoconf.sh
