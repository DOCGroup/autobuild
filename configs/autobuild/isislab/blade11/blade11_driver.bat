
cd ..\..\..\..\
set CVS_RSH=c:\cygwin\bin\ssh
cvs -q -d :ext:isisbuilds@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\isislab\blade11

call ace_for_tao.bat
call versioned_namespace.bat
