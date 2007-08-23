#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild

exec /usr/bin/perl $HOME/ACE/autobuild/autobuild.pl \
                             $HOME/ACE/autobuild/configs/autobuild/remedynl/vx64lin86_vxworks64.xml

