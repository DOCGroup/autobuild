#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild

exec /opt/perl/bin/perl $HOME/ACE/autobuild/autobuild.pl \
                             $HOME/ACE/autobuild/configs/autobuild/remedynl/mordor_autoconfgcc.xml

