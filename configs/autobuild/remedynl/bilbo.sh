#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild
PATH=/usr/local/bin:/etc:/opt/SUNWspro/bin:/usr/ccs/bin:/usr/ucb:$PATH
export PATH

svn up

exec /usr/bin/perl $HOME/ACE/autobuild/autobuild.pl \
                             $HOME/ACE/autobuild/configs/autobuild/remedynl/bilbo_suncc.xml
