rem $Id: Win2003_MSVC6_Debug.bat 3921 2006-07-27 12:02:37Z sma $
call "C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7\bin\VCVARS32.BAT"
c:
cd \Overnight_Builds\DOC_Group
svn up autobuild
svn status autobuild
cd \Overnight_Builds\DOC_Group\vc71\inlineMFC
perl C:\Overnight_Builds\DOC_Group\autobuild\autobuild.pl c:\Overnight_Builds\DOC_Group\autobuild\configs\autobuild\prism\Win2003_MSVC71_Inline_MFC.xml
c:\cygwin\bin\chmod o+r /cygdrive/T/doc-scoreboard/windows/VC71_InlineMFC/*
