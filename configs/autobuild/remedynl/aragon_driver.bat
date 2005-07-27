cd \ace\autobuild
set CVS_RSH=c:\cygwin\bin\ssh
c:\cygwin\bin\cvs -d :ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\remedynl
perl c:\ACE\autobuild\autobuild.pl aragon_cb6sr.xml
call aragon_vxworks-pcPentiumXSharedLib-gnu-run.bat
perl c:\ACE\autobuild\autobuild.pl aragon_cb6sr.xml
call aragon_vxworks-pcPentium-gnu-run.bat
perl c:\ACE\autobuild\autobuild.pl aragon_cb6sr.xml
call aragon_vxworks-pcPentiumX-gnu-run.bat
