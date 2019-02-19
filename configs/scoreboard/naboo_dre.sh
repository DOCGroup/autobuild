#!/bin/sh
# $Id$

PERLLIB=autobuild
export PERLLIB

cd $HOME/autobuild
git pull

# Generate the index page!
/usr/bin/perl ./scoreboard.pl -v -d /export/web/www/scoreboard -i $HOME/autobuild/configs/scoreboard/index.xml  2>&1 &
# Generate other pages!
/usr/bin/perl ./scoreboard.pl -b -d /export/web/www/scoreboard -f $HOME/autobuild/configs/scoreboard/ace.xml -o ace.html -r ace.rss 2>&1 &
/usr/bin/perl ./scoreboard.pl -b -d /export/web/www/scoreboard -f $HOME/autobuild/configs/scoreboard/tao.xml -o tao.html -r tao.rss 2>&1  &
/usr/bin/perl ./scoreboard.pl -b -d /export/web/www/scoreboard -f $HOME/autobuild/configs/scoreboard/ciao.xml -o ciao.html -r ciao.rss 2>&1  &
/usr/bin/perl ./scoreboard.pl -b -d /export/web/www/scoreboard -f $HOME/autobuild/configs/scoreboard/dds.xml -o dds.html -r dds.rss 2>&1  &
/usr/bin/perl ./scoreboard.pl -b -d /export/web/www/scoreboard -f $HOME/autobuild/configs/scoreboard/misc.xml -o misc.html 2>&1 &

# Generate the test matrices!
##testmatrix/update_scoreboard.sh 2>&1 &

# Generate integrated pages!
/usr/bin/perl ./scoreboard.pl -b -d /export/web/www/scoreboard -z 2>&1 &

#Generate build matrix
#/usr/bin/perl buildmatrix/buildmatrix.pl $HOME/autobuild/configs/scoreboard/ace.xml /export/web/www/scoreboard 1 > /project/taotmp/scoreboard/buildmatrix/output.html 2> /tmp/build.out

#/usr/bin/perl buildmatrix/buildmatrix.pl $HOME/autobuild/configs/scoreboard/tao.xml /export/web/www/scoreboard 1 > /project/taotmp/scoreboard/buildmatrix/tao.html 2> /tmp/build.out

#Remove the obsolete db files and give the list of available db files.
##matrix_database/RemoveAndListCompilationDbFiles.sh

#
wait

exit 0
