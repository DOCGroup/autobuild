#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

$HOME/ACE/autobuild/configs/autobuild/remedynl/arwen_icc91.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/arwen_icc90.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/arwen_gcc.sh
