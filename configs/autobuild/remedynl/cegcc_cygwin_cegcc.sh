#!/bin/sh
#
# $Id$
#
cd /opt
rm -rf *
cd /home/build/cegcc/
svn up
rm -rf /home/build/cegcc/src/scripts/x86
mkdir /home/build/cegcc/src/scripts/x86
cd /home/build/cegcc/src/scripts/x86
../build-x86.sh > /home/build/cegcc.txt
# rename libcoredll6.a to libcoredll.a to avoid
# linker errors
cd /opt/x86mingw32ce/i386-mingw32ce/lib/
mv libcoredll6.a libcoredll.a -f
# copy all dll to lib-dir
cd /opt/x86mingw32ce/
find . -name *.dll -type f -print0 |xargs -0 -i cp {} /cygdrive/d/ACE/cegcc/ACE_wrappers/lib
