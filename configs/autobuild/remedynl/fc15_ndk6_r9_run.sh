#!/bin/sh
#
# $Id$

# Make sure autobuild directory is up to date.
cd $HOME/ACE/autobuild
svn up

# Run the build.
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/fc15_ndk6_r9_host.sh && $HOME/ACE/autobuild/configs/autobuild/remedynl/fc15_ndk6_r9_target.sh
