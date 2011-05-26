#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

exec /usr/bin/perl $HOME/ACE/autobuild/autobuild.pl \
                             $HOME/ACE/autobuild/configs/autobuild/remedynl/fc15_opendds.xml
