cd ..\..\..\
set CVS_RSH=plink
cvs -q -d :ext:bugzilla@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\merengue
perl C:\ACE\autobuild\autobuild.pl merengue_vc71.xml
