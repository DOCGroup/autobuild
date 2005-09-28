@setlocal

set PATH=%PATH%;c:\tools\pstools;c:\tornado2.2\host\x86-win32\bin
pskill -t tgtsvr.exe
start tgtsvr.exe 10.2.128.61 -n RLM -V -m 61685760 -B wdbrpc -R C:\ -RW -redirectIO -C
perl C:\ACE\autobuild\autobuild.pl legolas_vxworks-ppc603-gnu.xml
pskill -t tgtsvr.exe

@endlocal
