#!/bin/sh
#
# $Id$

PERLLIB=autobuild
export PERLLIB

CVS_RSH=ssh
export CVS_RSH

cd $HOME/autobuild
cvs up

# /usr/bin/perl $HOME/autobuild/scoreboard.pl -o /export/project/workarea01/Scoreboard/html -c $HOME/autobuild/configs/scoreboard/acetao.xml 2>&1 &

# Generate the index page!
/usr/bin/perl ./scoreboard.pl -v -d /export/web/www/scoreboard -i $HOME/autobuild/configs/scoreboard/index.xml  2>&1 &
# Generate other pages!
/usr/bin/perl ./scoreboard.pl -v -d /export/web/www/scoreboard -f $HOME/autobuild/configs/scoreboard/ace.xml -o ace.html  2>&1 &
/usr/bin/perl ./scoreboard.pl -d /export/web/www/scoreboard -f $HOME/autobuild/configs/scoreboard/ace_future.xml -o ace_future.html 2>&1 &
/usr/bin/perl ./scoreboard.pl -d /export/web/www/scoreboard -f $HOME/autobuild/configs/scoreboard/tao.xml -o tao.html 2>&1  &
/usr/bin/perl ./scoreboard.pl -d /export/web/www/scoreboard -f $HOME/autobuild/configs/scoreboard/tao_future.xml -o tao_future.html 2>&1 &
/usr/bin/perl ./scoreboard.pl -d /export/web/www/scoreboard -f $HOME/autobuild/configs/scoreboard/misc.xml -o misc.html 2>&1 &
/usr/bin/perl ./scoreboard.pl -d /export/web/www/scoreboard -f $HOME/autobuild/configs/scoreboard/subset.xml -o subset.html 2>&1 &
/usr/bin/perl ./scoreboard.pl -d /export/web/www/scoreboard -f $HOME/autobuild/configs/scoreboard/cosmic.xml -o cosmic.html 2>&1 &

# Generate the test matrices!
testmatrix/update_scoreboard.sh 2>&1 &

# Generate integrated pages!
/usr/bin/perl ./scoreboard.pl -d /export/web/www/scoreboard -z 2>&1 &

#Generate build matrix
#/usr/bin/perl buildmatrix/buildmatrix.pl $HOME/autobuild/configs/scoreboard/ace.xml /export/web/www/scoreboard 1 > /project/taotmp/scoreboard/buildmatrix/output.html 2> /tmp/build.out

#/usr/bin/perl buildmatrix/buildmatrix.pl $HOME/autobuild/configs/scoreboard/tao.xml /export/web/www/scoreboard 1 > /project/taotmp/scoreboard/buildmatrix/tao.html 2> /tmp/build.out

#Remove the obsolete db files and give the list of available db files.
matrix_database/RemoveAndListCompilationDbFiles.sh

#Copy the test stat index page to the webserver
cp $HOME/autobuild/configs/autobuild/remedynl/teststats.html /export/web/www/scoreboard

#
wait

exit 0
