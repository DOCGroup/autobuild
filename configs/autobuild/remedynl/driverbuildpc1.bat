cd ..\..\..\
start c:\putty\pageant.exe c:\putty\privatenokey
sleep 4
del D:\bcb6d\.disable
del D:\BCB6ddwchar\.disable
del D:\BCB6dr\.disable
set CVS_RSH=plink
cvs -d :ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\remedynl
rem perl D:\autobuild\autobuild.pl MingWGCC31.xml
rem perl D:\autobuild\autobuild.pl CygwinGCC2_95_3_5.xml 
rem perl D:\autobuild\autobuild.pl BCB6DynamicRelease.xml 
perl D:\autobuild\autobuild.pl BCB6DynamicDebugWChar.xml 
perl D:\autobuild\autobuild.pl BCB6DynamicDebug.xml
dobuildpc1
