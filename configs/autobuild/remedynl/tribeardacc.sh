#!/bin/sh
#
# $Id$
#

cd /build/ACE/autobuild

exec /opt/perl/bin/perl /build/ACE/autobuild/autobuild.pl \
                             /build/ACE/autobuild/configs/autobuild/remedynl/tribeardacc.xml
