#!/bin/sh
#
# $Id$
#

cd /home/build/ACE/autobuild

svn up

sh solaris_host.sh
sh solaris_vxworks.sh
