#!/bin/csh
#
# $Id$
#
cd /export/home/bugzilla/FACET/RTEvent/facet
source setup-gcj.csh
exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/hokey/facet.xml
cd /export/home/bugzilla/FACET/RTEvent/tao-facet-adaptor
setup.sh
exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/hokey/jACE.xml
exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/hokey/ACE_TAO.xml
exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/hokey/tao-facet-adapter.xml
