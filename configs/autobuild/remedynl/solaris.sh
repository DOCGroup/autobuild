#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild

cvs -z9 up -P -d

exec /usr/local/bin/perl $HOME/ACE/autobuild/autobuild.pl \
                             $HOME/ACE/autobuild/configs/autobuild/remedynl/SunForte.xml
