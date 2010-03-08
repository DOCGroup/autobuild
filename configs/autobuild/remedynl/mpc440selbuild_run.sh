#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

sh $HOME/ACE/autobuild/configs/autobuild/remedynl/mpc440selbuild_host.sh && $HOME/ACE/autobuild/configs/autobuild/remedynl/mpc440selbuild.sh
