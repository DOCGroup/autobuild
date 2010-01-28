#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

sh $HOME/ACE/autobuild/configs/autobuild/remedynl/mpc440_xampler_host.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/mpc440_xampler.sh
