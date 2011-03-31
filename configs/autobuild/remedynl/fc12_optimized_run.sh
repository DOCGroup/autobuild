#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

sh $HOME/ACE/autobuild/configs/autobuild/remedynl/fc12_optimized_host.sh && $HOME/ACE/autobuild/configs/autobuild/remedynl/fc12_optimized.sh
