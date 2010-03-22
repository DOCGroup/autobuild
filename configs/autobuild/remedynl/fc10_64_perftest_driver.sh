#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild

svn up

sh $HOME/ACE/autobuild/configs/autobuild/remedynl/fc10_64_perftest.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/fc10_64_perftest_ts.sh

