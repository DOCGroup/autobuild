#!/bin/sh
#
# $Id$
#

cd /build/ACE/autobuild

exec /usr/local/bin/perl /build/ACE/autobuild/autobuild.pl \
                             /build/ACE/autobuild/configs/autobuild/remedynl/tribeardgcc.xml
