#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

$HOME/ACE/autobuild/configs/autobuild/remedynl/morton_autoconfgcc.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/morton_acc.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/morton_gcc.sh

