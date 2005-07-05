call "C:\Program Files\Microsoft Visual Studio\VC98\Bin\vcvars32.bat"
f:
cd \Overnight_Builds\DOC_Group\autobuild
set CVSROOT=:ext:sma@cvs.doc.wustl.edu:/project/cvs-repository
set CVS_RSH=c:\cygwin\bin\ssh
c:\cygwin\bin\cvs -z9 up -P -d
cd configs\autobuild\prism
perl f:\Overnight_Builds\DOC_Group\autobuild\autobuild.pl Win2003_MSVC6_Debug.xml
c:\cygwin\bin\chmod o+r T:\doc-scoreboard\windows\MSVC6_Debug\*
