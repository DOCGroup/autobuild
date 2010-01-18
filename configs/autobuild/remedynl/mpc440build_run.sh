#!/bin/sh
#
# $Id$
#
cd $HOME/mpc440_build/ACE/autobuild

svn up

sh $HOME/mpc440_build/ACE/autobuild/configs/autobuild/remedynl/mpc440build_host.sh && $HOME/mpc440_build/ACE/autobuild/configs/autobuild/remedynl/mpc440build.sh
