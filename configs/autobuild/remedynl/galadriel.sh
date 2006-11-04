#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

$HOME/ACE/autobuild/configs/autobuild/remedynl/galadriel_host.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/galadriel_vxworks61.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/galadriel_vxworks61_ppc603.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/galadriel_galadriel.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/galadriel_footprint.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/galadriel_autoconf.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/galadriel_vxworks63r.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/galadriel_vxworks63ripv6.sh
