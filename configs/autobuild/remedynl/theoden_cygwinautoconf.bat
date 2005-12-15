cd ..\..\..\
set CVS_RSH=ssh
cvs -d :ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
perl C:\ACE\autobuild\autobuild.pl configs\autobuild\remedynl\theoden_cygwinautoconf.xml 
cd configs\autobuild\remedynl