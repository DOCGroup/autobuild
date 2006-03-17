#!/bin/sh
#
# $Id$
#

cd $HOME/

exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/isisbuilds/isis_valgrind.xml

