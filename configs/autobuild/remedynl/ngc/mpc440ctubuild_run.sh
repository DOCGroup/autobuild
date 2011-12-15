#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

sh $HOME/ACE/autobuild/configs/autobuild/remedynl/ngc/mpc440ctubuild_host.sh && $HOME/ACE/autobuild/configs/autobuild/remedynl/ngc/mpc440ctubuild.sh
