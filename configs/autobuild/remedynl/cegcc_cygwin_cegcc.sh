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
../build-x86.sh > /home/build/cegcc.txt
# rename libcoredll6.a to libcoredll.a to avoid
# linker errors
cd /opt/x86mingw32ce/i386-mingw32ce/lib/
mv libcoredll6.a libcoredll.a -f
# copy all dll to lib-dir
cd /opt/x86mingw32ce/
find . -name *.dll -type f -print0 |xargs -0 -i cp {} /home/build/ACE/cegcc/ACE_wrappers/lib
