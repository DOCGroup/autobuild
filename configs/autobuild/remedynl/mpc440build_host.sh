#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild

exec /usr/bin/perl $HOME/teton_build/ACE/autobuild/autobuild.pl \
                             $HOME/teton_build/ACE/autobuild/configs/autobuild/remedynl/mpc440build_host.xml

