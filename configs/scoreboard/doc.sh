#!/bin/sh
#
# $Id$

export PERLLIB=autobuild

exec /usr/bin/perl $HOME/autobuild/scoreboard.pl -c autobuild/configs/scoreboard/acetao.xml 2>&1
