#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild

svn up

$HOME/ACE/autobuild/configs/autobuild/remedynl/android9_plus_fc14_host.sh
# No shared object builds due to problems with the Android compiler regarding dynamic_cast
# $HOME/ACE/autobuild/configs/autobuild/remedynl/android9_plus_fc14_target.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/android9_plus_static_fc14_target.sh
