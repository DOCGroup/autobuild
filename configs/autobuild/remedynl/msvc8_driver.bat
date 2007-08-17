cd ..\..\..\
svn up
cd configs\autobuild\remedynl

perl C:\ACE\autobuild\autobuild.pl msvc8_cidlc.xml
perl C:\ACE\autobuild\autobuild.pl msvc8_version.xml
perl C:\ACE\autobuild\autobuild.pl msvc8_d.xml
