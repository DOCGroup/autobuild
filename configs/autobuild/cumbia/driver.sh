#!/bin/sh
#
# $Id$

# Make sure autobuild directory is up to date.
cd $HOME/autobuild
svn up

# Run the build.
sh $HOME/autobuild/configs/autobuild/cumbia/NoIIOP.sh
sh $HOME/autobuild/configs/autobuild/cumbia/CORBAemicro.sh
sh $HOME/autobuild/configs/autobuild/cumbia/CORBAecompact.sh
sh $HOME/autobuild/configs/autobuild/cumbia/NoInt.sh
