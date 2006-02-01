cd ..\..\..\
set CVS_RSH=c:\cygwin\bin\ssh
c:\cygwin\bin\cvs -d :ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\remedynl

perl C:\ACE\autobuild\autobuild.pl theoden_bcb2006dr.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2006sr.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2006dd.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2006sd.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2006ddu.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2006dd_ipv6.xml
perl C:\ACE\autobuild\autobuild.pl theoden_cygwinautoconf.xml

perl C:\ACE\autobuild\autobuild.pl theoden_cb6sr.xml
perl C:\ACE\autobuild\autobuild.pl theoden_vxworks-simnt-gnu.xml
