#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

sh $HOME/mpc440_build/ACE/autobuild/configs/autobuild/remedynl/mpc440_xampler_host.sh
sh $HOME/mpc440_build/ACE/autobuild/configs/autobuild/remedynl/mpc440_xampler.sh
