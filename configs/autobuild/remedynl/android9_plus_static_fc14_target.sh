#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

exec /usr/bin/perl /home/build/ACE/autobuild/autobuild.pl \
                             /home/build/ACE/autobuild/configs/autobuild/remedynl/android9_plus_static_fc14_target.xml
