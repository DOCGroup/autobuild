#!/bin/sh
#
# $Id$
#

cd /export/home/build/ACE/autobuild
PATH=/usr/local/bin:/etc:/opt/SUNWspro/bin:/usr/ccs/bin:/usr/ucb:/opt/csw/bin:$PATH
LD_LIBRRAY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export PATH
export LD_LIBRRAY_PATH

svn up

sh configs/autobuild/remedynl/anduin_suncc.sh
