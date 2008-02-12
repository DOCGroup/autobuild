#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

$HOME/ACE/autobuild/configs/autobuild/remedynl/arwen_icc101.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/arwen_gcc.sh
