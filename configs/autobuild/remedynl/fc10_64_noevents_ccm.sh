#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

$HOME/ACE/autobuild/configs/autobuild/remedynl/fc10_64_ne_fccm.sh

$HOME/ACE/autobuild/configs/autobuild/remedynl/fc10_64_ne_lwccm.sh
