#!/bin/csh
#
# $Id$
#
cd /export/home/bugzilla/FACET/RTEvent/facet
source setup-gcj.csh
exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/hokey/facet.xml
exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/hokey/ACE_TAO.xml
