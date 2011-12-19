#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild
svn up

exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
     $HOME/autobuild/configs/autobuild/remedynl/fc16_core.xml
