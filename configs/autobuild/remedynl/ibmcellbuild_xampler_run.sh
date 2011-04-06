#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

sh $HOME/ACE/autobuild/configs/autobuild/remedynl/ibmcellbuild_xampler_host.sh && $HOME/ACE/autobuild/configs/autobuild/remedynl/ibmcellbuild_xampler.sh
