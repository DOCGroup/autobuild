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

# Generate the index page!
exec /usr/bin/perl ./scoreboard.pl -v -d /project/taotmp/scoreboard/html -i $HOME/autobuild/configs/scoreboard/index.xml  2>&1 &
# Generate other pages!
exec /usr/bin/perl ./scoreboard.pl -v -d /project/taotmp/scoreboard/html -f $HOME/autobuild/configs/scoreboard/ace.xml -o ace.html  2>&1 &
exec /usr/bin/perl ./scoreboard.pl -d /project/taotmp/scoreboard/html -f $HOME/autobuild/configs/scoreboard/ace_future.xml -o ace_future.html 2>&1 &
exec /usr/bin/perl ./scoreboard.pl -d /project/taotmp/scoreboard/html -f $HOME/autobuild/configs/scoreboard/tao.xml -o tao.html 2>&1  &
exec /usr/bin/perl ./scoreboard.pl -d /project/taotmp/scoreboard/html -f $HOME/autobuild/configs/scoreboard/tao_future.xml -o tao_future.html 2>&1 &
exec /usr/bin/perl ./scoreboard.pl -d /project/taotmp/scoreboard/html -f $HOME/autobuild/configs/scoreboard/misc.xml -o misc.html 2>&1 &
# Generate integrated pages!
exec /usr/bin/perl ./scoreboard.pl -d /project/taotmp/scoreboard/html -z 2>&1;

# Generate the test matrices!
$HOME/autobuild/update_scoreboard.sh
