@echo off
setlocal
set "HOME=C:\Users\bugzilla"
set "OLDCD=%CD%"
cd %HOME%\builds
cvs up -P -d autobuild
cd "%OLDCD%
perl %HOME%\builds\autobuild\autobuild.pl %1 %2 %3 %4 %5 %6 %7 %8 %9
endlocal