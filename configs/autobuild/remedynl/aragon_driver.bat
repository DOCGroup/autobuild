cd \ace\autobuild
set CVS_RSH=c:\cygwin\bin\ssh
c:\cygwin\bin\cvs -d :ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\remedynl
perl c:\ACE\autobuild\autobuild.pl aragon_msvcwchar.xml
perl c:\ACE\autobuild\autobuild.pl aragon_msvcunicode.xml
perl c:\ACE\autobuild\autobuild.pl aragon_msvcdebug.xml
perl c:\ACE\autobuild\autobuild.pl aragon_msvclibdebug.xml
perl c:\ACE\autobuild\autobuild.pl aragon_msvclibrelease.xml
perl c:\ACE\autobuild\autobuild.pl aragon_msvcunicodedebug.xml
perl c:\ACE\autobuild\autobuild.pl aragon_msvcrelease.xml

