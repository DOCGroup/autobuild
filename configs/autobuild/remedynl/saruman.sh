#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

sh $HOME/ACE/autobuild/configs/autobuild/remedynl/saruman_icc110.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/saruman_gcc.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/saruman_icc101.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/saruman_icc111.sh
