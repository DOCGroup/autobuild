#!/bin/sh
#
# $Id$

# Make sure autobuild directory is up to date.
cd $HOME/autobuild
svn up

sh $HOME/autobuild/configs/autobuild/remedynl/fc16_04_perf_ts.sh && \
   $HOME/autobuild/configs/autobuild/remedynl/fc16_04_lwccm_ne.sh && \
   $HOME/autobuild/configs/autobuild/remedynl/fc16_04_fullccm.sh &&
