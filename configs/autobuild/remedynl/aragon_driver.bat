cd \ace\autobuild
c:\cygwin\bin\svn up
cd configs\autobuild\remedynl
perl c:\ACE\autobuild\autobuild.pl aragon_cb6sr.xml
perl C:\ACE\autobuild\autobuild.pl aragon_vxworks64.xml
perl C:\ACE\autobuild\autobuild.pl aragon_vxworks64k.xml
perl C:\ACE\autobuild\autobuild.pl aragon_vxworks65.xml
perl C:\ACE\autobuild\autobuild.pl aragon_vxworks65k.xml
call aragon.bat
