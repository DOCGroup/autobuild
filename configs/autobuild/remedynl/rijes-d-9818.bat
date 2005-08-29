cd ..\..\..\
set CVS_RSH=d:\cygwin\bin\ssh
d:\cygwin\bin\cvs -d :ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\remedynl
call rijes-d-9818_driver.bat
