@setlocal

set PATH=%PATH%;c:\tools\pstools;c:\tornado2.2\host\ppc603-win32\bin
rem pskill -t tgtsvr.exe
rem start tgtsvr.exe 10.2.128.65 -n P4 -V -m 61685760 -B wdbrpc -R C:\ -RW -redirectIO -C
c:\perl\bin\perl c:\ACE\autobuild\autobuild.pl vx551_win_ppc603_test.xml
rem pskill -t tgtsvr.exe

@endlocal
