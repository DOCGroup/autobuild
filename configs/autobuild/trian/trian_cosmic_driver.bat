rem $Id$

cd C:\bczar\autobuild
svn up
cd configs\autobuild\trian
call trian_cosmic_release.bat
call trian_cosmic_debug.bat
call trian_cosmic_debug_tests.bat