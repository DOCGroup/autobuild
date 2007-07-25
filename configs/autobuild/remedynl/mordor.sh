#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

/usr/local/bin/svn up

$HOME/ACE/autobuild/configs/autobuild/remedynl/mordor_acc.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/mordor_gcc.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/mordor_accwchar.sh
$HOME/ACE/autobuild/configs/autobuild/remedynl/mordor_gccwchar.sh

