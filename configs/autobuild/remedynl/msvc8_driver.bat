cd ..\..\..\
c:\cygwin\bin\svn up
cd configs\autobuild\remedynl

perl C:\ACE\autobuild\autobuild.pl msvc8_version.xml
perl C:\ACE\autobuild\autobuild.pl msvc8_d.xml
perl C:\ACE\autobuild\autobuild.pl msvc8_r.xml
perl C:\ACE\autobuild\autobuild.pl msvc8_pro_r.xml
