@echo off
setlocal
set "LIB=%LIB%;d:\ssl\openssl-0.9.6\out32dll"
set "INCLUDE=%INCLUDE%;D:\ssl\openssl-0.9.6\inc32"
set "CVSROOT=:ext:wustlbuilds@cvs:/project/cvs-repository"
set "CVS_RSH=plink"
call "C:\Program Files\Microsoft Visual Studio .NET\Vc7\bin\vcvars32.bat"
cd ..\..\..\
cvs up -P -d
cd configs\autobuild\nirvana
if not exist Z: net use Z: \\TAO\bugzilla_www
perl G:\bugzilla\autobuild\autobuild.pl %1 %2 %3 %4 %5 %6 %7 %8 %9
endlocal



