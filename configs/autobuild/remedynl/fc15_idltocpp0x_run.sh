#!/bin/sh
#
# $Id$

# Make sure autobuild directory is up to date.
cd $HOME/ACE/autobuild
svn up

# Run the build.
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/fc15_versioned.sh && $HOME/ACE/autobuild/configs/autobuild/remedynl/fc15_idltocpp0x.sh && $HOME/ACE/autobuild/configs/autobuild/remedynl/fc15_idltocpp0x_v.sh && $HOME/ACE/autobuild/configs/autobuild/remedynl/fc15_idltocpp0x_fuzz.sh
