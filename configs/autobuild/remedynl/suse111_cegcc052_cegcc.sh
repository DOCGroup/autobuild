#!/bin/sh
#
# $Id$
#
cd /home/build/cegcc/
svn up
cd /home/build/cegcc/src/scripts/x86
rm -rf *
../build-x86.sh
