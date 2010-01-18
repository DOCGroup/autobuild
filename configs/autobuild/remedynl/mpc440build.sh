#!/bin/sh
#
# $Id$
#

cd $HOME/mpc440_build/ACE/autobuild

exec /usr/bin/perl $HOME/mpc440_build/ACE/autobuild/autobuild.pl \
                             $HOME/mpc440_build/ACE/autobuild/configs/autobuild/remedynl/mpc440build.xml

