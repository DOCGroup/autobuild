#!/bin/sh
#
# $Id$
#

PATH=/usr/local/bin:$PATH
export PATH

exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/beguine/Redhat_7.1_Core.xml 2>&1 

