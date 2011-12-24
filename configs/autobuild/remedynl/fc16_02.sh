#!/bin/sh
#
# $Id$

# Make sure autobuild directory is up to date.
cd $HOME/autobuild
svn up

# Run the build.
sh $HOME/autobuild/configs/autobuild/remedynl/fc16_02_valgrind.sh && \
   $HOME/autobuild/configs/autobuild/remedynl/fc16_02_perf.sh

