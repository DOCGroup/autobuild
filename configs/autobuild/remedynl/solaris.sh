#!/bin/sh
#
# $Id$
#

cd /home/build/ACE/autobuild

/usr/local/bin/svn up

sh configs/autobuild/remedynl/solaris_host55.sh
sh configs/autobuild/remedynl/solaris_vxworks55.sh
