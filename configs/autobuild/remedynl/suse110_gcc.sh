#!/bin/sh
#
# $Id$

# Make sure autobuild directory is up to date.
cd $HOME/autobuild
svn up

# Run the build.
sh $HOME/autobuild/configs/autobuild/remedynl/suse110_gcc_ace.sh
