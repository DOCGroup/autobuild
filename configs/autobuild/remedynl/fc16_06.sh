#!/bin/sh
#
# $Id$

# Make sure autobuild directory is up to date.
cd $HOME/autobuild
svn up

sh $HOME/autobuild/configs/autobuild/remedynl/fc16_06_fp_corbaec.sh && \
   $HOME/autobuild/configs/autobuild/remedynl/fc16_06_fp_corbaem.sh && \
   $HOME/autobuild/configs/autobuild/remedynl/fc16_06_nologging.sh && \
   $HOME/autobuild/configs/autobuild/remedynl/fc16_06_fp_corbaems.sh

