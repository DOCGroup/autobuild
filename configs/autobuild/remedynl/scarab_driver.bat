if exist c:\ACE\.disable goto _Exit

echo Yes > C:\ACE\.disable

cd ..\..\..\
set CVS_RSH=ssh
cvs -d :ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\remedynl
perl C:\ACE\autobuild\autobuild.pl scarab_bcb6dru.xml
perl C:\ACE\autobuild\autobuild.pl scarab_bcb6ddu.xml
perl C:\ACE\autobuild\autobuild.pl scarab_bcb6dr.xml
perl C:\ACE\autobuild\autobuild.pl scarab_bcb6dd.xml
perl C:\ACE\autobuild\autobuild.pl scarab_vc8.xml
perl C:\ACE\autobuild\autobuild.pl scarab_MingW.xml
perl C:\ACE\autobuild\autobuild.pl scarab_MingWTAO.xml
perl C:\ACE\autobuild\autobuild.pl scarab_MingWs.xml

del /f/q C:\ACE\.disable

:_Exit

