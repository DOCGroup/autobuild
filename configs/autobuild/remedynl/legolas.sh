#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

#$HOME/ACE/autobuild/configs/autobuild/remedynl/legolas_host.sh
#$HOME/ACE/autobuild/configs/autobuild/remedynl/legolas_rtems.sh
#$HOME/ACE/autobuild/configs/autobuild/remedynl/legolas_rtems_nonet.sh
#$HOME/ACE/autobuild/configs/autobuild/remedynl/legolas_rtems_nonets.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/legolas_qnx.sh
