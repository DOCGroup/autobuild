cd ..\..\..\
cvs -z9 up -P -d
del D:\Cygwin\.disable
del D:\.disable
cd configs\autobuild\remedynl
perl D:\autobuild\autobuild.pl CygwinGCC32.xml
rem c:\cygwin\bin\sleep 1h
dobuildpc2
