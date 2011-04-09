#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

exec /usr/pkg/bin/perl $HOME/ACE/autobuild/autobuild.pl \
                             $HOME/ACE/autobuild/configs/autobuild/remedynl/qnx65.xml
