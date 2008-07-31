#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild

exec /usr/bin/perl $HOME/ACE/autobuild/autobuild.pl \
                             $HOME/ACE/autobuild/configs/autobuild/remedynl/suse110_icc110_64.xml

