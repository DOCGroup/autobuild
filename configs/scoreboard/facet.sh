#!/bin/sh
#
# $Id$

# Author: Dante Cannarozzi
# Purpose: Generate the facet scoreboard results as well as the facet build
#          using ACE+TAO from cvs


PERLLIB=autobuild
export PERLLIB

#CVS_RSH=ssh
#export CVS_RSH

cd $HOME/autobuild
#cvs up


# Generate the index page!
exec /usr/bin/perl ./scoreboard.pl -v -d /project/deuce/pces/facet/scoreboard -i $HOME/autobuild/configs/scoreboard/index-facet.xml  2>&1 &
#exec /usr/bin/perl ./scoreboard.pl -v -d /project/deuce/pces/facet/scoreboard -i $HOME/autobuild/configs/scoreboard/index-facet-cvs.xml  2>&1 &
# Generate other pages!
exec /usr/bin/perl ./scoreboard.pl -v -d /project/deuce/pces/facet/scoreboard -f $HOME/autobuild/configs/scoreboard/facet.xml -o facet.html  2>&1 &
exec /usr/bin/perl ./scoreboard.pl -v -d /project/deuce/pces/facet/scoreboard -f $HOME/autobuild/configs/scoreboard/facet-cvs.xml -o facet-cvs.html  2>&1 &

# Generate integrated pages!
#exec /usr/bin/perl ./scoreboard.pl -d /export/project/workarea01/Scoreboard/html -z 2>&1;

