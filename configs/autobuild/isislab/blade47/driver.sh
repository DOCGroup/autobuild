#!/bin/sh
#
# $Id$

# Make sure autobuild directory is up to date.
cd $HOME/autobuild
CVS_RSH=ssh
export CVS_RSH
cvs up -P -d

# Run the build.
exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
  $HOME/autobuild/configs/autobuild/isislab/blade47/NoInt_NoEx.xml
