#!/bin/sh
#
# $Id$
#

cd /home/build/ACE/autobuild

/usr/local/bin/svn up

sh configs/autobuild/remedynl/solaris_host66.sh
sh configs/autobuild/remedynl/solaris_vxworks66.sh
