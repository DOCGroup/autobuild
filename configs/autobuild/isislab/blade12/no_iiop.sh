#!/bin/sh
#
# $Id: ace_for_tao.sh 3813 2006-07-14 01:56:33Z wotte $

# Make sure autobuild directory is up to date.
cd $HOME/autobuild
svn up

# Run the build.
exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
  $HOME/autobuild/configs/autobuild/isislab/blade12/no_iiop.xml
