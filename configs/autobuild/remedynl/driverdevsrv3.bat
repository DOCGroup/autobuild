cd \ace\autobuild
set CVS_RSH=ssh
cvs -d :ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\remedynl
perl c:\ACE\autobuild\autobuild.pl msvclibdebug.xml
perl c:\ACE\autobuild\autobuild.pl msvclibrelease.xml
perl c:\ACE\autobuild\autobuild.pl msvcrelease.xml
perl c:\ACE\autobuild\autobuild.pl msvcdebug.xml

