cd ..\..\..\
set CVS_RSH=ssh
cvs -d :ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\remedynl
rem set MSYS_ROOT=d:\msys
rem %MSYS_ROOT%\bin\sh --login -i -c "cd /d/ACE/autobuild/configs/autobuild/remedynl; perl D:/ACE/autobuild/autobuild.pl MingW.xml"
perl c:/ACE/autobuild/autobuild.pl MingW.xml
