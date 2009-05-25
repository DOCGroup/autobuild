cd ..\..\..\
\cygwin\bin\svn up
cd configs\autobuild\remedynl
perl C:\ACE\autobuild\autobuild.pl msvc8_wince6_x86_host.xml
c:\cygwin\bin\bash --login /cygdrive/c/ACE/autobuild/configs/autobuild/remedynl/cegcc_cygwin.sh
perl C:\ACE\autobuild\autobuild.pl msvc8_wince6_x86_d.xml
