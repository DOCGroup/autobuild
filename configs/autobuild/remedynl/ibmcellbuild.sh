#!/bin/sh
#
# $Id$
#

svn up /build/ACE/autobuild

cd $HOME/ACE/autobuild

svn up

exec /usr/bin/perl $HOME/ACE/autobuild/autobuild.pl \
                             $HOME/ACE/autobuild/configs/autobuild/remedynl/ibmcellbuild.xml

