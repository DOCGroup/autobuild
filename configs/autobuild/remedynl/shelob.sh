#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

sh $HOME/ACE/autobuild/configs/autobuild/remedynl/shelob_gcc.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/shelob_icc101_32.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/shelob_icc91_32.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/shelob_icc91_64.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/shelob_acefortao.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/shelob_coiop.sh
