#!/bin/sh
#
# $Id$
#

PATH=/usr/local/bin:$PATH
export PATH

LD_LIBRARY_PATH=/usr/local/bin:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH

exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/beguine/Redhat_Explicit_Templates.xml 2>&1 

