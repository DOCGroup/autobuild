cd ..\..\..\
cvs -z9 up -P -d
cd configs\autobuild\remedynl
rem perl D:\autobuild\autobuild.pl MingWGCC31.xml
perl D:\autobuild\autobuild.pl BCB6DynamicRelease.xml
perl D:\autobuild\autobuild.pl BCB6DynamicDebugWChar.xml
perl D:\autobuild\autobuild.pl BCB6DynamicDebug.xml
dobuildpc1
