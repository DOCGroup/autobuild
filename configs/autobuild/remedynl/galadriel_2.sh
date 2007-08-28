#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild
svn up
$HOME/ACE/autobuild/configs/autobuild/remedynl/galadriel_vxworks63r.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/galadriel_vxworks63ripv6.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/galadriel_vxworks64r.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/galadriel_vxworks64ripv6.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/galadriel_vxworks64rk.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/galadriel_vxworks64rdiab.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/galadriel_vxworks64sh.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/galadriel_vxworks64shdiab.sh
