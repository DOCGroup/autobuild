#!/bin/sh
#
# $Id$

PERLLIB=autobuild
export PERLLIB

CVS_RSH=ssh
export CVS_RSH

cd $HOME/autobuild
cvs up

exec /usr/bin/perl $HOME/autobuild/scoreboard.pl -o /export/project/workarea01/Scoreboard/html -c $HOME/autobuild/configs/scoreboard/acetao.xml 2>&1
