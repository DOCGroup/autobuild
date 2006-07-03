#!/bin/sh
#
# $Id$

# Make sure autobuild directory is up to date.
cd $HOME/autobuild
CVS_RSH=ssh
export CVS_RSH
cvs up -P -d

# Run the build.
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/NoInt.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/CORBAemicro.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/CORBAecompact.sh
