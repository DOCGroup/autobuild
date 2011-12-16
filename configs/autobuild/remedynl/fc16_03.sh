#!/bin/sh
#
# $Id$

# Make sure autobuild directory is up to date.
cd $HOME/autobuild
svn up

sh $HOME/autobuild/configs/autobuild/remedynl/fc16_03_fullccm.sh && \
   $HOME/autobuild/configs/autobuild/remedynl/fc16_03_fullccm_ne.sh && \
