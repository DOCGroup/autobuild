#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

sh $HOME/ACE/autobuild/configs/autobuild/remedynl/ps3gccbuild_host.sh && $HOME/ACE/autobuild/configs/autobuild/remedynl/ps3gccbuild.sh
