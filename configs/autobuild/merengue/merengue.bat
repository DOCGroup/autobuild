cd ..\..\..\
set CVS_RSH=ssh
cvs -d :ext:bugzilla@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\merengue
call merengue_driver.bat
