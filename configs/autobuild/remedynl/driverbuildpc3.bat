cd ..\..\..\
start d:\putty\pageant.exe d:\putty\privatenokey
sleep 4
set CVS_RSH=plink
cvs -d :ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\remedynl
perl D:\ACE\autobuild\autobuild.pl BCB6DynamicDebugMbg.xml