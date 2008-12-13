#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild

svn up

sh $HOME/ACE/autobuild/configs/autobuild/remedynl/suse110_icc101_64.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/suse110_icc101_64_v.sh

