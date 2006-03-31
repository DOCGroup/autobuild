
rem perl C:\ACE\autobuild\autobuild.pl blade49_vc71.xml

cd ..\..\..\..\
set CVS_RSH=c:\cygwin\bin\ssh
cvs -q -d :ext:isisbuilds@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\isislab\blade49

call blade49_vc71.bat
