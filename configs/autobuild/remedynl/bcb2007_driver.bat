cd ..\..\..\
svn up
cd configs\autobuild\remedynl

perl C:\ACE\autobuild\autobuild.pl theoden_bcb2007dr.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2007sr.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2007sd.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2007ddu.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2007dds.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2007dd_ipv6.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2007dd.xml
call theoden.bat
