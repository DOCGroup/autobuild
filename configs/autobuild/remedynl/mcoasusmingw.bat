cd ..\..\..\
set CVS_RSH=ssh
cvs -d :ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\remedynl
perl c:/ACE/autobuild/autobuild.pl MingWTAO.xml
perl c:/ACE/autobuild/autobuild.pl MingW.xml
perl c:/ACE/autobuild/autobuild.pl mingws.xml
