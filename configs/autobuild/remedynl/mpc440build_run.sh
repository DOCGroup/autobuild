#!/bin/sh
#
# $Id$
#
cd $HOME/teton_build/ACE/autobuild

svn up

sh $HOME/teton_build/ACE/autobuild/configs/autobuild/remedynl/mpc440build_host.sh && $HOME/teton_build/ACE/autobuild/configs/autobuild/remedynl/mpc440build.sh
