#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

sh $HOME/ACE/autobuild/configs/autobuild/remedynl/ubuntu910_64_gcc.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/ubuntu910_64_autoconf.sh
