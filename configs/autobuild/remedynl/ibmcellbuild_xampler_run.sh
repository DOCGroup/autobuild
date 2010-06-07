#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

sh $HOME/ACE/autobuild/configs/autobuild/remedynl/ps3cellbuild_xampler_host.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/ps3cellbuild_xampler.sh
