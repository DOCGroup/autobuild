@echo off
setlocal
set "LIB=%LIB%;C:\openssl-0.9.6c\out32dll"
set "INCLUDE=%INCLUDE%;C:\openssl-0.9.6c\inc32"
call "C:\Program Files\Microsoft Visual Studio\VC98\Bin\vcvars32.bat"
cd ..\..\..\
cvs up -P -d
cd configs\autobuild\ringil
perl C:\builds\autobuild\autobuild.pl %1 %2 %3 %4 %5 %6 %7 %8 %9
endlocal