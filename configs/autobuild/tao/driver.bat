@echo off
setlocal
set "LIB=%LIB%;F:\bugzilla\ssl\openssl-0.9.6\out32dll"
set "INCLUDE=%INCLUDE%;F:\bugzilla\ssl\openssl-0.9.6\inc32"
call "E:\Program Files\Microsoft Visual Studio\VC98\Bin\vcvars32.bat"
cd ..\..\..\
cvs up -P -d
cd configs\autobuild\tao
perl F:\bugzilla\autobuild\autobuild.pl %1 %2 %3 %4 %5 %6 %7 %8 %9
endlocal