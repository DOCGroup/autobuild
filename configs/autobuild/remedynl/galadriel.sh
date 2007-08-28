#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild

svn up

$HOME/ACE/autobuild/configs/autobuild/remedynl/galadriel_host.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/galadriel_vxworks64_ppc603.sh
