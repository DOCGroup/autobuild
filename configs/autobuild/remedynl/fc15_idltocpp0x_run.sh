#!/bin/sh
#
# $Id$

# Make sure autobuild directory is up to date.
cd $HOME/ACE/autobuild
svn up

# Run the build.
exec /usr/bin/perl $HOME/ACE/autobuild/autobuild.pl \
                             $HOME/ACE/autobuild/configs/autobuild/remedynl/fc15_versioned.xml

exec /usr/bin/perl $HOME/ACE/autobuild/autobuild.pl \
                             $HOME/ACE/autobuild/configs/autobuild/remedynl/fc15_idltocpp0x.xml

