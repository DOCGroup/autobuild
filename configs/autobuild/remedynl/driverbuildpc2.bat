cd ..\..\..\
cvs -z9 up -P -d
cd configs\autobuild\remedynl
perl D:\autobuild\autobuild.pl MingWStatic.xml
perl D:\autobuild\autobuild.pl BCB5StaticDebug.xml
dobuildpc2