#!/bin/sh
#
# $Id$

PERLLIB=autobuild
export PERLLIB

CVS_RSH=ssh
export CVS_RSH

cd $HOME/autobuild
cvs up

#exec /usr/bin/perl $HOME/autobuild/scoreboard.pl -o /export/project/workarea01/Scoreboard/html -c $HOME/autobuild/configs/scoreboard/acetao.xml 2>&1 &


exec /usr/bin/perl ./scoreboard.pl -v -d /export/project/workarea01/Scoreboard/html -i $HOME/autobuild/configs/scoreboard/index.xml  2>&1 &
exec /usr/bin/perl ./scoreboard.pl -v -d /export/project/workarea01/Scoreboard/html -f $HOME/autobuild/configs/scoreboard/ace.xml -o /project/taotmp/bala/html/ace.html 2>&1 &
exec /usr/bin/perl ./scoreboard.pl -d /export/project/workarea01/Scoreboard/html -f $HOME/autobuild/configs/scoreboard/ace_future.xml -o /export/project/workarea01/Scoreboard/html/ace_future.html 2>&1 &
exec /usr/bin/perl ./scoreboard.pl -d /export/project/workarea01/Scoreboard/html -f $HOME/autobuild/configs/scoreboard/tao.xml -o /export/project/workarea01/Scoreboard/html/tao.html 2>&1  &
exec /usr/bin/perl ./scoreboard.pl -d /export/project/workarea01/Scoreboard/html -f $HOME/autobuild/configs/scoreboard/tao_future.xml -o /export/project/workarea01/Scoreboard/html/tao_future.html 2>&1 &
exec /usr/bin/perl ./scoreboard.pl -d /export/project/workarea01/Scoreboard/html -f $HOME/autobuild/configs/scoreboard/misc.xml -o /export/project/workarea01/Scoreboard/html/misc.html 2>&1 &
exec /usr/bin/perl ./scoreboard.pl -d /export/project/workarea01/Scoreboard/html -z 2>&1;

