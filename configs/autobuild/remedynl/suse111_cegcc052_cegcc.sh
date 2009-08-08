#!/bin/sh
#
# $Id$
#
cd /home/build/cegcc/
svn up
cd /home/build/cegcc/src/scripts
rm -rf /home/build/opt
rm -rf /home/build/cegcc/src/scripts/x86
mkdir /home/build/cegcc/src/scripts/x86
cd /home/build/cegcc/src/scripts/x86
../build-x86.sh --prefix=/home/build/opt/x86mingw32ce/ > /home/build/cegccbuild.txt
# rename libcoredll6.a to libcoredll.a to avoid
# linker errors
cd /home/build/opt/x86mingw32ce/i386-mingw32ce/lib/
mv libcoredll6.a libcoredll.a -f
#copy all dll to lib-dir
cd /home/build/opt/x86mingw32ce/
find . -name *.dll -type f -print0 |xargs -0 -i cp {} /home/build/ACE/cegcc/ACE_wrappers/lib
scp /home/build/cegccbuild.txt johnnyw@naboo.dre.vanderbilt.edu:/web/users/remedynl/cegccbuild.txt
