#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild
svn up
$HOME/ACE/autobuild/configs/autobuild/remedynl/vx64linother_vxworks64r.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/vx64linother_vxworks64ripv6.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/vx64linother_vxworks64rk.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/vx64linother_vxworks64rkp.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/vx64linother_vxworks64sh.sh
