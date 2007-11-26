#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

$HOME/ACE/autobuild/configs/autobuild/remedynl/saruman_gcc.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/saruman_icc101.sh
