
cd ..\..\..\..\
set CVS_RSH=c:\cygwin\bin\ssh
cvs -q -d :ext:isisbuilds@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\isislab\blade27

call blade27_vc71_minimum_corba.bat
