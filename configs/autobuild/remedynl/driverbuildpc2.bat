set CVS_RSH=ssh
set CVSROOT=:ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository
cd ..\..\..\
cvs -z9 up -P -d
del D:\Cygwin\.disable
del D:\.disable
cd configs\autobuild\remedynl
perl D:\autobuild\autobuild.pl CygwinGCC32.xml
dobuildpc2
