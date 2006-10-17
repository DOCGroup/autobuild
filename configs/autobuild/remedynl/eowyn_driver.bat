cd \ace\autobuild
c:\cygwin\bin\svn up
cd configs\autobuild\remedynl
perl c:\ACE\autobuild\autobuild.pl eowyn_cross_host_vc71.xml
call eowyn_vxworks-ppc603-gnu.bat
