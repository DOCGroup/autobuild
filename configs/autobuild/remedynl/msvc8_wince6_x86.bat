cd ..\..\..\
\cygwin\bin\svn up
cd configs\autobuild\remedynl
perl C:\cygwin\home\build\ACE\autobuild\autobuild.pl msvc8_wince6_x86_host.xml
c:\cygwin\bin\bash --login /home/build/ACE/autobuild/configs/autobuild/remedynl/cegcc_cygwin.sh
perl C:\cygwin\home\build\ACE\autobuild\autobuild.pl msvc8_wince6_x86_d.xml
