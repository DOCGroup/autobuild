#!/bin/sh
#
# $Id$
#

PATH=/usr/local/bin:$PATH
export PATH

LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH

exec /usr/bin/perl $HOME/development/ace/autobuild/autobuild.pl \
                             $HOME/development/ace/autobuild/configs/autobuild/dresystems/skoll_1.xml 2>&1 

