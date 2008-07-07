@echo off
rem $Id$
set THIS_BUILD=C:\Overnight_Builds\DOC_Group\vc8\standardUniMFC\
echo ==============================================================================
echo                      DOC_Group MSVC8 Standard Unicode MFC
echo ==============================================================================
if not exist %THIS_BUILD%.disable goto doBuild
  echo.
  echo A previous build is either still in progress or failed abnormally as the
  echo "%THIS_BUILD%.disable" file exists.
  echo.
  pause
  if exist %THIS_BUILD%.disable goto :eof
:doBuild
call "C:\Overnight_Builds\autobuild-xml\MachineConfig\Windows\Map_Network_Drives.bat"
rem  ==============================================================================
rem  The following fixes a problem with chaining builds on after one another where
rem  the PATH continues to grow with all previous ACE_ROOT etc. being listed in it.
rem  Later builds can "confuse" previously built ace.dll etc. with their own if
rem  these are not removed.
rem  ==============================================================================
if "%ORIGINAL_PATH%" == "" (
   set ORIGINAL_PATH=%PATH%
) else (
   set PATH=%ORIGINAL_PATH%
)
if "%ORIGINAL_INCLUDE%" == "" (
   set ORIGINAL_INCLUDE=%INCLUDE%
) else (
   set INCLUDE=%ORIGINAL_INCLUDE%
)
if "%ORIGINAL_LIB%" == "" (
   set ORIGINAL_LIB=%LIB%
) else (
   set LIB=%ORIGINAL_LIB%
)
call "C:\Program Files\Microsoft Visual Studio 8\Common7\Tools\vsvars32.bat"
mkdir C:\temp > nul: 2>&1
mkdir C:\temp\DOC_Group > nul: 2>&1
mkdir C:\temp\DOC_Group\standardUniMFC > nul: 2>&1
set TEMP=C:\temp\DOC_Group\standardUniMFC
set TMP=%TEMP%
echo.
echo Updating autobuild
C:
cd \Overnight_Builds\DOC_Group
svn up autobuild
echo.
echo status autobuild
svn status autobuild
echo.
if exist c:\cygwin\bin\date.exe echo This build started:
if exist c:\cygwin\bin\date.exe c:\cygwin\bin\date +"%%X on %%a %%d-%%b-%%Y"
echo For status, notepad %THIS_BUILD%build.txt
cd %THIS_BUILD%
perl C:\Overnight_Builds\DOC_Group\autobuild\autobuild.pl C:\Overnight_Builds\DOC_Group\autobuild\configs\autobuild\prism\Vista_MSVC8_Standard_UnicodeMFC.xml
cd \Overnight_Builds\DOC_Group\autobuild\configs\autobuild\prism
echo Finished !!
if exist c:\cygwin\bin\date.exe c:\cygwin\bin\date +"%%X on %%a %%d-%%b-%%Y"
