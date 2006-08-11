@echo off
rem $Id: Win2003_MSVC6_Debug.bat 3921 2006-07-27 12:02:37Z sma $
set THIS_BUILD=C:\Overnight_Builds\DOC_Group\vc71\standardMFC\
echo ==============================================================================
echo                          DOC_Group MSVC71 Standard MFC
echo ==============================================================================
if not exist %THIS_BUILD%.disable goto doBuild
  echo.
  echo A previous build is either still in progress or failed abnormally as the
  echo "%THIS_BUILD%.disable" file exists.
  echo.
  pause
  if exist %THIS_BUILD%.disable goto :eof
:doBuild
call "C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7\bin\VCVARS32.BAT"
mkdir C:\temp > nul: 2>&1
mkdir C:\temp\DOC_Group > nul: 2>&1
mkdir C:\temp\DOC_Group\standardMFC > nul: 2>&1
set TEMP=C:\temp\DOC_Group\standardMFC
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
echo For status, notepad %THIS_BUILD%build.txt
cd %THIS_BUILD%
perl C:\Overnight_Builds\DOC_Group\autobuild\autobuild.pl C:\Overnight_Builds\DOC_Group\autobuild\configs\autobuild\prism\Win2003_MSVC71_Standard_MFC.xml > nul: 2>&1
cd \Overnight_Builds\DOC_Group\autobuild\configs\autobuild\prism
echo Finished !!
