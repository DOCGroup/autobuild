#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild
PATH=/usr/local/bin:/etc:/opt/SUNWspro/bin:/usr/ccs/bin:/usr/ucb:/opt/csw/bin:$PATH
LD_LIBRRAY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export PATH
export LD_LIBRRAY_PATH

svn up

sh configs/autobuild/remedynl/minas_purify_fast.sh
sh configs/autobuild/remedynl/minas_purify.sh
sh configs/autobuild/remedynl/minas_suncc.sh
sh configs/autobuild/remedynl/minas_quantify.sh
