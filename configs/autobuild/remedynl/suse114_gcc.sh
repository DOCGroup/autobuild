#!/bin/sh
#
# $Id$
#

cd $HOME/autobuild
svn up

exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
     $HOME/autobuild/configs/autobuild/remedynl/suse114_gcc.xml

