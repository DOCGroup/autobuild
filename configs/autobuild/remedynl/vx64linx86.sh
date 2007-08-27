#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild

svn up

$HOME/ACE/autobuild/configs/autobuild/remedynl/vx64linx86_host.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/vx64linx86_vxworks64.sh
