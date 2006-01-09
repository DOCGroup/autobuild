cd ..\..\..\
set CVS_RSH=c:\cygwin\bin\ssh
c:\cygwin\bin\cvs -d :ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
perl C:\ACE\autobuild\autobuild.pl configs\autobuild\remedynl\theoden_cygwinautoconf.xml
cd configs\autobuild\remedynl
