#!/bin/sh
#
# $Id$

# Make sure autobuild directory is up to date.
cd $HOME/autobuild
svn up

# Run the build.
sh $HOME/autobuild/configs/autobuild/isislab/blade47/NoInt.sh
sh $HOME/autobuild/configs/autobuild/isislab/blade47/CORBAemicro.sh
sh $HOME/autobuild/configs/autobuild/isislab/blade47/CORBAecompact.sh
