cd ..\..\..\
c:\cygwin\bin\svn up
cd configs\autobuild\remedynl

perl C:\ACE\autobuild\autobuild.pl theoden_vc71.xml
perl C:\ACE\autobuild\autobuild.pl theoden_vc71_ipv6_debug.xml
perl C:\ACE\autobuild\autobuild.pl theoden_vc71dr.xml
perl C:\ACE\autobuild\autobuild.pl theoden_vc71sd.xml
