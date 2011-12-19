#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

sh $HOME/ACE/autobuild/configs/autobuild/remedynl/ngc/ibmcellbuild_host.sh && $HOME/ACE/autobuild/configs/autobuild/remedynl/ngc/ibmcellbuild.sh && $HOME/ACE/autobuild/configs/autobuild/remedynl/ngc/ibmcellbuild_lwccm_ne_rw_pre.sh


