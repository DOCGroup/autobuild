cd ..\..\..\
\cygwin\bin\svn up
cd configs\autobuild\remedynl
rem perl C:\ACE\autobuild\autobuild.pl msvc8_wince6_x86_host.xml
perl C:\ACE\autobuild\autobuild.pl cegcc_mingw_idlstubs.xml
c:\cygwin\bin\bash --login /cygdrive/c/ACE/autobuild/configs/autobuild/remedynl/cegcc_cygwin_cegcc.sh
c:\cygwin\bin\bash --login /cygdrive/c/ACE/autobuild/configs/autobuild/remedynl/cegcc_cygwin.sh
rem perl C:\ACE\autobuild\autobuild.pl msvc8_wince6_x86_d.xml
