cd \develop\autobuild
set CVS_RSH=ssh
cvs -d :ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\remedynl
perl c:\Develop\autobuild\autobuild.pl MingWTAO.xml
dodevsrv4

