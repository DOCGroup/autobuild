#!/bin/sh
#
# $Id$
#

cd /home/build/ACE/autobuild

/usr/local/bin/svn up

sh solaris_host.sh
sh solaris_vxworks.sh
