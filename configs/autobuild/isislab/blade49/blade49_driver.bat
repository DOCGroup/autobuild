
rem perl C:\ACE\autobuild\autobuild.pl blade49_vc71.xml

cd ..\..\..\
set CVS_RSH=plink
cvs -q -d :ext:bugzilla@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\blade49

call blade49_vc71.bat
