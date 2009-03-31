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
$HOME/ACE/autobuild/configs/autobuild/remedynl/vx67linother_vxworks67r.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/vx67linother_vxworks67ripv6.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/vx67linother_vxworks67rk.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/vx67linother_vxworks67rkp.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/vx67linother_vxworks67sh.sh

