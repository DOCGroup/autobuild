#!/bin/sh
#
# $Id$
#

cd /home/build/ACE/autobuild

exec /opt/perl/bin/perl /home/build/ACE/autobuild/autobuild.pl \
                             /home/build/ACE/autobuild/configs/autobuild/remedynl/simbagcc.xml
