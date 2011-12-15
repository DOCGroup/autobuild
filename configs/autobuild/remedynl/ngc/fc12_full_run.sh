#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

sh $HOME/ACE/autobuild/configs/autobuild/remedynl/fc12_full_host.sh && $HOME/ACE/autobuild/configs/autobuild/remedynl/fc12_full.sh
