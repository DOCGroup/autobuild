rem $Id$

cd C:\autobuild
set CVS_RSH=plink
cvs -q -d :ext:bugzilla@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\equus

call equus_vc71.bat
