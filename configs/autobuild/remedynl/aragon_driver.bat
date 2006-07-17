cd \ace\autobuild
c:\cygwin\bin\svn up
cd configs\autobuild\remedynl
perl c:\ACE\autobuild\autobuild.pl aragon_cb6sr.xml
call aragon_vxworks-pcPentiumXSharedLib-gnu-run.bat
perl c:\ACE\autobuild\autobuild.pl aragon_cb6sr.xml
call aragon_vxworks-pcPentiumX-gnu-run.bat
