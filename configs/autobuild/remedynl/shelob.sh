#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

sh $HOME/ACE/autobuild/configs/autobuild/remedynl/shelob_icc10_32.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/shelob_icc10_64.sh
