cd \ace\autobuild
set CVS_RSH=c:\cygwin\bin\ssh
c:\cygwin\bin\cvs -d :ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\remedynl
perl c:\ACE\autobuild\autobuild.pl frodo_msvcdebug.xml
perl c:\ACE\autobuild\autobuild.pl frodo_msvclibdebug.xml
perl c:\ACE\autobuild\autobuild.pl frodo_msvclibrelease.xml
perl c:\ACE\autobuild\autobuild.pl frodo_msvcunicodedebug.xml
perl c:\ACE\autobuild\autobuild.pl frodo_msvcrelease.xml

