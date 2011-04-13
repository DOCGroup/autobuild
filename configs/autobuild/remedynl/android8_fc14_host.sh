#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

exec /usr/bin/perl /home/build/ACE/autobuild/autobuild.pl \
                             /home/build/ACE/autobuild/configs/autobuild/remedynl/android8_fc14_host.xml
