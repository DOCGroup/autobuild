#!/bin/sh
#
# $Id$
#

PATH=/usr/local/bin:$PATH
export PATH

LD_LIBRARY_PATH=/usr/local/lib:$PATH
export LD_LIBRARY_PATH

exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/beguine/Redhat_7.1_Full.xml 2>&1 

