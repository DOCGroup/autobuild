#!/bin/sh
#
# $Id$
#

cd /usr/users/build/ACE/autobuild
PATH=/usr/local/bin:${PATH}
CVSROOT=:ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository
CVS_RSH=ssh
export CVSROOT
export CVS_RSH
export PATH

cvs -z9 up -P -d

exec /usr//bin/perl $HOME/ACE/autobuild/autobuild.pl \
                             $HOME/ACE/autobuild/configs/autobuild/remedynl/Tru64.xml
