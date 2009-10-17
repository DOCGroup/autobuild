rem $Id$

cd C:\bczar\autobuild
svn up
cd configs\autobuild\equus
call equus_vc8_release.bat
call equus_vc8.bat
