#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

sh $HOME/ACE/autobuild/configs/autobuild/remedynl/ngc/fc12_optimized_host.sh && $HOME/ACE/autobuild/configs/autobuild/remedynl/ngc/fc12_optimized.sh
