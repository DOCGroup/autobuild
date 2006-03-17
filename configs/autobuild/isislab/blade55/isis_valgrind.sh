#!/bin/sh
#
# $Id$
#

cd $HOME/

exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/isislab/blade55/isis_valgrind.xml

