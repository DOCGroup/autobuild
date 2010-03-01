#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

bash $HOME/ACE/autobuild/configs/autobuild/remedynl/ubuntu910_64_autoconf.sh
bash $HOME/ACE/autobuild/configs/autobuild/remedynl/ubuntu910_64_gcc.sh
