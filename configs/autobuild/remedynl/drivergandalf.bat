cd ..\..\..\
set CVS_RSH=ssh
cvs -d :ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\remedynl
perl C:\ACE\autobuild\autobuild.pl Cygwin.xml
perl C:\ACE\autobuild\autobuild.pl cbxddu.xml
perl C:\ACE\autobuild\autobuild.pl cbxdd.xml
perl C:\ACE\autobuild\autobuild.pl cbxsr.xml
perl C:\ACE\autobuild\autobuild.pl vc71.xml
perl C:\ACE\autobuild\autobuild.pl gandalfvc71dr.xml
perl C:\ACE\autobuild\autobuild.pl gandalfvc71sd.xml
perl C:\ACE\autobuild\autobuild.pl gandalf_cbxddace.xml
