cd ..\..\..\
cvs -z9 up -P -d
cd configs\autobuild\remedynl
perl D:\autobuild\autobuild.pl CygwinGCC32.xml
perl D:\autobuild\autobuild.pl BCB5StaticDebug.xml
c:\cygwin\bin\sleep 1h
dobuildpc2
