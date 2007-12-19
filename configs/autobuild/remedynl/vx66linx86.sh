#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild

svn up

$HOME/ACE/autobuild/configs/autobuild/remedynl/vx66linx86_host.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/vx66linx86_vxworks66.sh
