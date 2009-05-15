#!/bin/sh
#
# $Id$
#
cd /opt
rm -rf *
cd /home/build/cegcc/
svn up
cd /home/build/cegcc/src/scripts/x86
rm -rf *
../build-x86.sh
#copy all dll to lib-dir
cd /opt/x86mingw32ce/
find . -name *.dll -type f -print0 |xargs -0 -i cp {} /home/build/ACE/cegcc/ACE_wrappers/lib
