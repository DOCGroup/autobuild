#!/bin/sh
# $Id$

PERLLIB=autobuild
export PERLLIB
OUTPUTDIR=/export/web/www/scoreboard
export OUTPUTDIR
CONFIGDIR=$HOME/autobuild/configs/scoreboard
export CONFIGDIR

cd $HOME/autobuild
git pull

# Generate the index page!
/usr/bin/perl ./scoreboard.pl -v -d $OUTPUTDIR -i $CONFIGDIR/index.xml  2>&1 &
# Generate other pages!
/usr/bin/perl ./scoreboard.pl -b -d $OUTPUTDIR -f $CONFIGDIR/ace.xml -o ace.html -r ace.rss 2>&1 &
/usr/bin/perl ./scoreboard.pl -b -d $OUTPUTDIR -f $CONFIGDIR/tao.xml -o tao.html -r tao.rss 2>&1  &
/usr/bin/perl ./scoreboard.pl -b -d $OUTPUTDIR -f $CONFIGDIR/ciao.xml -o ciao.html -r ciao.rss 2>&1  &
/usr/bin/perl ./scoreboard.pl -b -d $OUTPUTDIR -f $CONFIGDIR/dds.xml -o dds.html -r dds.rss 2>&1  &

# Generate the test matrices!
##testmatrix/update_scoreboard.sh 2>&1 &

# Generate integrated pages!
/usr/bin/perl ./scoreboard.pl -b -d /export/web/www/scoreboard -z -j $CONFIGDIR/ace.xml,$CONFIGDIR/tao.xml,$CONFIGDIR/ciao.xml,$CONFIGDIR/dds.xml 2>&1 &

#Generate build matrix
#/usr/bin/perl buildmatrix/buildmatrix.pl $CONFIGDIR/ace.xml $OUTPUTDIR 1 > /project/taotmp/scoreboard/buildmatrix/output.html 2> /tmp/build.out

#/usr/bin/perl buildmatrix/buildmatrix.pl $CONFIGDIR/tao.xml $OUTPUTDIR 1 > /project/taotmp/scoreboard/buildmatrix/tao.html 2> /tmp/build.out

#Remove the obsolete db files and give the list of available db files.
##matrix_database/RemoveAndListCompilationDbFiles.sh

#
wait

exit 0
