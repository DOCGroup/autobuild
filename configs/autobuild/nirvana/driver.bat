@echo off
setlocal
set "LIB=%LIB%;d:\ssl\openssl-0.9.6\out32dll"
set "INCLUDE=%INCLUDE%;D:\ssl\openssl-0.9.6\inc32"
set "CVSROOT=:ext:wustlbuilds:/project/cvs-repository"
call "C:\Program Files\Microsoft Visual Studio\VC98\Bin\vcvars32.bat"
cd ..\..\..\
cvs up -P -d
cd configs\autobuild\nirvana
if not exist Z: net use Z: \\TAO\bugzilla_www
perl D:\bugzilla\autobuild\autobuild.pl %1 %2 %3 %4 %5 %6 %7 %8 %9
endlocal