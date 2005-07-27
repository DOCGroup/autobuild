@setlocal

set PATH=%PATH%;c:\tools\pstools;c:\tornado2.2\host\x86-win32\bin
pskill -t tgtsvr.exe
perl c:\ACE\autobuild\autobuild.pl aragon_vxworks-pcPentiumXSharedLib-gnu.xml

@endlocal
