cd ..\..\..\
set CVS_RSH=c:\cygwin\bin\ssh
cvs -d :ext:mcorino@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\remedynl
perl C:\ACE\autobuild\autobuild.pl cross_host_vc71.xml
