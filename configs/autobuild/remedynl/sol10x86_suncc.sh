#!/bin/sh
#
# $Id$
#

cd /export/home/build/ACE/autobuild

PATH=/usr/local/bin:/etc:/opt/sunstudio12.1/bin:/opt/SUNWspro/bin:/usr/ccs/bin:/usr/ucb:/opt/csw/bin:$PATH
LD_LIBRRAY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export PATH
export LD_LIBRRAY_PATH

svn up

exec /usr/bin/perl /export/home/build/ACE/autobuild/autobuild.pl \
                             /export/home/build/ACE/autobuild/configs/autobuild/remedynl/sol10x86_suncc.xml

