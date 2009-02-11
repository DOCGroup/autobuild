cd ..\..\..\
\cygwin\bin\svn up
cd configs\autobuild\remedynl

perl C:\ACE\autobuild\autobuild.pl msvc8_wince6_host.xml
perl C:\ACE\autobuild\autobuild.pl msvc8_wince6_d.xml
perl C:\ACE\autobuild\autobuild.pl msvc8_wince6_r.xml
perl C:\ACE\autobuild\autobuild.pl msvc8_wince6_pro_r.xml
