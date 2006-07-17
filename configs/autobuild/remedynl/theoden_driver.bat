cd ..\..\..\
svn up
cd configs\autobuild\remedynl

perl C:\ACE\autobuild\autobuild.pl theoden_bcb2006dr.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2006sr.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2006dd.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2006sd.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2006ddu.xml
perl C:\ACE\autobuild\autobuild.pl theoden_bcb2006dd_ipv6.xml

perl C:\ACE\autobuild\autobuild.pl theoden_cb6sr.xml
perl C:\ACE\autobuild\autobuild.pl theoden_vxworks-simnt-gnu.xml
