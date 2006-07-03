rem $Id$

cd C:\bczar\autobuild
set CVS_RSH=plink.exe
cvs -q -d :ext:isisbuilds@cvs.doc.wustl.edu:/project/cvs-repository -z3 up -P -d
cd configs\autobuild\equus

call equus_vc71.bat
