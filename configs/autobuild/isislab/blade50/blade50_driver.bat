
cd ..\..\..\..\
set CVS_RSH=c:\cygwin\bin\ssh
cvs -q -d :ext:bugzilla@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\isislab\blade50

call blade50_vc8.bat


