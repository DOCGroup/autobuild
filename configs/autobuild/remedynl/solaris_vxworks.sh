#!/bin/sh
#
# $Id$
#

cd /nfs/solaris/autobuild

exec /usr/local/bin/perl /nfs/solaris/autobuild/autobuild.pl \
                             /nfs/solaris/autobuild/configs/autobuild/remedynl/solaris_vxworks.xml

