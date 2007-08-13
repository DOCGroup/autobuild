cd ..\..\..\
c:\cygwin\bin\svn up
cd configs\autobuild\remedynl

perl C:\ACE\autobuild\autobuild.pl msvc71_d.xml
perl C:\ACE\autobuild\autobuild.pl msvc71_ipv6_debug.xml
perl C:\ACE\autobuild\autobuild.pl msvc71_vc71dr.xml
perl C:\ACE\autobuild\autobuild.pl msvc71_sd.xml
