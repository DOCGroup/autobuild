#!/bin/sh
#
# $Id$

# Make sure autobuild directory is up to date.
cd $HOME/autobuild
svn up

sh $HOME/autobuild/configs/autobuild/remedynl/fc16_05_tao_valgrind.sh

