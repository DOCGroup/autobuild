@setlocal

set PATH=%PATH%;c:\tools\pstools;c:\tornado2.2\host\x86-win32\bin
pskill -t tgtsvr.exe
start tgtsvr.exe 10.2.128.65 -n P4 -V -m 61685760 -B wdbrpc -R C:\ -RW -redirectIO -C
perl c:\ACE\autobuild\autobuild.pl aragon_vxworks-pcPentium-gnu.xml
pskill -t tgtsvr.exe

@endlocal
