cd ..\..\..\
cvs -z9 up -P -d
cd configs\autobuild\remedynl
perl D:\autobuild\autobuild.pl BCB6DynamicDebugWChar.xml
perl D:\autobuild\autobuild.pl BCB6DynamicDebug.xml
perl D:\autobuild\autobuild.pl MingWGCC31.xml
dobuildpc1
