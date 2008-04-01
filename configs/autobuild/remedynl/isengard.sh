#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild
PATH=/usr/local/bin:/etc:/opt/SUNWspro/bin:/usr/ccs/bin:/usr/ucb:$PATH
LD_LIBRRAY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export PATH
export LD_LIBRRAY_PATH

svn up

sh configs/autobuild/remedynl/isengard_host.sh
sh configs/autobuild/remedynl/isengard_vxworks66.sh
sh configs/autobuild/remedynl/isengard_suncc.sh
