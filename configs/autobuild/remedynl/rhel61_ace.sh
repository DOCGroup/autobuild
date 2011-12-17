#!/bin/sh
#
# $Id$

# Make sure autobuild directory is up to date.
cd $HOME/autobuild
svn up

# Run the build.
sh $HOME/autobuild/configs/autobuild/remedynl/rhel61_x64_ace.sh && \
   $HOME/autobuild/configs/autobuild/remedynl/rhel61_x32_ace.sh