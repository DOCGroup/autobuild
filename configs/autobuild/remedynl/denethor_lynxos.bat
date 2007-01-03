@setlocal
cd ..\..\..\

"c:\program files\subversion\bin\svn" up
cd configs\autobuild\remedynl
set PATH=%PATH%;C:\LynuxWorks\4p2p0\bin;
c:\perl\bin\perl c:\ACE\autobuild\autobuild.pl denethor_lynxos.xml
@endlocal
