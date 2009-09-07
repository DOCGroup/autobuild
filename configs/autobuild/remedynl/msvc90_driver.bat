cd ..\..\..\
svn up
cd configs\autobuild\remedynl

perl C:\ACE\autobuild\autobuild.pl msvc90_d.xml
perl C:\ACE\autobuild\autobuild.pl msvc90_ipv6_debug.xml
perl C:\ACE\autobuild\autobuild.pl msvc90_vc90dr.xml
