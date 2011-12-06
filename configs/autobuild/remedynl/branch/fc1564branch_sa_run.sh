#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

sh $HOME/ACE/autobuild/configs/autobuild/remedynl/branch/fc1564branch_sa.sh && $HOME/ACE/autobuild/configs/autobuild/remedynl/branch/fc1564branch_sa_full.sh
