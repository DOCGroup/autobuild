cd ..\..\..\
cvs -z9 up -P -d
cd configs\autobuild\remedynl
perl D:\autobuild\autobuild.pl BCB5StaticDebug.xml
c:\cygwin\bin\sleep 3h
dobuildpc2