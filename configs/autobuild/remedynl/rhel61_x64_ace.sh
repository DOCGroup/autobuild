#!/bin/sh
#
# $Id$
#

cd $HOME/autobuild

exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
     $HOME/autobuild/configs/autobuild/remedynl/rhel61_x64_ace.xml

