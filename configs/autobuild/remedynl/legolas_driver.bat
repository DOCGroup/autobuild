cd ..\..\..\
set CVS_RSH=c:\cygwin\bin\ssh
c:\cygwin\bin\cvs -d :ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\remedynl
perl C:\ACE\autobuild\autobuild.pl legolas_cross_host_vc71.xml
perl C:\ACE\autobuild\autobuild.pl legolas_vxworks-ppc85xx-gnu.xml
perl C:\ACE\autobuild\autobuild.pl legolas_vxworks-ppc604-gnu.xml
perl C:\ACE\autobuild\autobuild.pl legolas_cross_host_vc71.xml
perl C:\ACE\autobuild\autobuild.pl legolas_vxworks-pentium-gnu.xml
perl C:\ACE\autobuild\autobuild.pl legolas_vxworks-pentium-pthread-gnu.xml
