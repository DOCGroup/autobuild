cd ..\..\..\
c:\cygwin\bin\svn up
cd configs\autobuild\remedynl

perl C:\ACE\autobuild\autobuild.pl theoden_bcb2007dr.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2006sr.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2006dd.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2006sd.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2007ddu.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2006dds.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2006dd_ipv6.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2007dd.xml
perl C:\ACE\autobuild\autobuild.pl theoden_vc71.xml
perl C:\ACE\autobuild\autobuild.pl theoden_vc71_ipv6_debug.xml
perl C:\ACE\autobuild\autobuild.pl theoden_vc71dr.xml
perl C:\ACE\autobuild\autobuild.pl theoden_vc71sd.xml
call theoden.bat
