#!/bin/sh
#
# $Id$
#

cd /home/build/ACE/autobuild

svn up

exec /usr/local/bin/perl /home/build/ACE/autobuild/autobuild.pl \
                             /home/build/ACE/autobuild/configs/autobuild/remedynl/solaris_host.xml

exec /usr/local/bin/perl /home/build/ACE/autobuild/autobuild.pl \
                             /home/build/ACE/autobuild/configs/autobuild/remedynl/solaris_vxworks.xml
