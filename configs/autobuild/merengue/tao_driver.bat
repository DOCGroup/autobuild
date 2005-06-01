rem $Id$

cd ..\..\..\
set CVS_RSH=plink
cvs -q -d :ext:bugzilla@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\tao_win2003

call tao_vc8.bat

