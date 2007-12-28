#!/bin/sh
#
# $Id$
#

cd /home/build/ACE/autobuild

exec /usr/local/bin/perl /home/build/ACE/autobuild/autobuild.pl \
                             /home/build/ACE/autobuild/configs/autobuild/remedynl/solaris_host.xml

