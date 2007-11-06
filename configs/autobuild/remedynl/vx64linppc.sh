#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild

svn up

$HOME/ACE/autobuild/configs/autobuild/remedynl/vx64linppc_host.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/vx64linppc_vxworks64.sh
