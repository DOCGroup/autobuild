#!/bin/sh
#
# $Id$
#
# Author: Dante Cannarozzi
# Purpose: autobuild driver running the standard facet builds. It first builds
#          the external libraries that facet uses, then jACE, ACE_TAO.
#          Then it runs through facet builds with different features enabled.
#          We only want to build the tao-facet-adapter with the ttl and
#          correlation_filter enabled.

# the directory which has all of the configuration files
BASE=$HOME/autobuild/configs/autobuild/hokey/facet

/usr/bin/perl $HOME/autobuild/autobuild.pl $BASE/facet.xml
/usr/bin/perl $HOME/autobuild/autobuild.pl $BASE/corba-facet.xml
/usr/bin/perl $HOME/autobuild/autobuild.pl $BASE/jACE.xml

# do we really need to do this every night?
#/usr/bin/perl $HOME/autobuild/autobuild.pl $BASE/ACE_TAO.xml

# build each of the different facet configurations
for f in $BASE/facet-*.xml
do
  /usr/bin/perl $HOME/autobuild/autobuild.pl $f

  # build the tao-facet-adapter if we have correlation_filter and ttl enabled
  if [ $f = "$BASE/facet-correlation_ttl.xml" ] 
  then
    /usr/bin/perl $HOME/autobuild/autobuild.pl $BASE/tao-facet-adapter.xml
  fi
done


