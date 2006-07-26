call "C:\Program Files\Microsoft Visual Studio\VC98\Bin\vcvars32.bat"
f:
cd \Overnight_Builds\DOC_Group\autobuild
svn up .
cd configs\autobuild\prism
perl f:\Overnight_Builds\DOC_Group\autobuild\autobuild.pl Win2003_MSVC6_Debug.xml
c:\cygwin\bin\chmod o+r /cygdrive/T/doc-scoreboard/windows/MSVC6_Debug/*
