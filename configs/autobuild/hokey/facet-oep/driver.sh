#!/bin/sh
#
# $Id$
#
# Author: Dante Cannarozzi
# Purpose: autobuild driver for running the facet builds using ACE_TAO from boeing OEP. 
#          It first builds the external libraries that facet uses, then jACE and ACE_TAO.

# the directory that contains the configuration files
BASE=$HOME/autobuild/configs/autobuild/hokey/facet-oep

/usr/bin/perl $HOME/autobuild/autobuild.pl $BASE/facet.xml
/usr/bin/perl $HOME/autobuild/autobuild.pl $BASE/jACE.xml
/usr/bin/perl $HOME/autobuild/autobuild.pl $BASE/ACE_TAO.xml
/usr/bin/perl $HOME/autobuild/autobuild.pl $BASE/tao-facet-adapter.xml
/usr/bin/perl $HOME/autobuild/autobuild.pl $BASE/oep-scenarios.xml
