#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild

svn up

$HOME/ACE/autobuild/configs/autobuild/remedynl/android9_fc14_host.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/android9_fc14_target.sh
