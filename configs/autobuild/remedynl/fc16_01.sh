#!/bin/sh
#
# $Id$

# Make sure autobuild directory is up to date.
cd $HOME/autobuild
svn up

# Run the build.
sh $HOME/autobuild/configs/autobuild/remedynl/fc16_01_coiop.sh && \
   $HOME/autobuild/configs/autobuild/remedynl/fc16_01_corbae_compact.sh && \
   $HOME/autobuild/configs/autobuild/remedynl/fc16_01_acefortao.sh && \
   $HOME/autobuild/configs/autobuild/remedynl/fc16_01_wchar.sh && \
   $HOME/autobuild/configs/autobuild/remedynl/fc16_01_ipv6.sh && \
   $HOME/autobuild/configs/autobuild/remedynl/fc16_01_xmlconfig.sh
