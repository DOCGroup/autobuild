cd ..\..\..\
set CVS_RSH=ssh
cvs -d :ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\remedynl
rem set MSYS_ROOT=d:\msys
rem %MSYS_ROOT%\bin\sh --login -i -c "cd /d/ACE/autobuild/configs/autobuild/remedynl; perl D:/ACE/autobuild/autobuild.pl MingW.xml"
d:\MSys\opt\perl\5.8.0\bin\MSWin32-x86-multi-thread\perl D:/ACE/autobuild/autobuild.pl MingW.xml
