#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild

svn up

$HOME/ACE/autobuild/configs/autobuild/remedynl/vx67linx86_host.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/vx67linx86_vxworks67k.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/vx67linppc603_vxworks67k.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/vx67linx86_vxworks67.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/vx67linx86_vxworks67p.sh
