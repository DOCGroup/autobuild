@echo off
setlocal
set "HOME=C:\Users\bugzilla"
cd ..\..\..\
cvs up -P -d
cd configs\autobuild\ringil
perl C:\builds\autobuild\autobuild.pl %1 %2 %3 %4 %5 %6 %7 %8 %9
endlocal