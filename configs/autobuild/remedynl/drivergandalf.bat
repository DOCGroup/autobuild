cd ..\..\..\
set CVS_RSH=ssh
cvs -d :ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\remedynl
perl C:\ACE\autobuild\autobuild.pl gandalf_cygwin.xml
perl C:\ACE\autobuild\autobuild.pl gandalf_cbxddu.xml
perl C:\ACE\autobuild\autobuild.pl gandalf_cbxdd.xml
perl C:\ACE\autobuild\autobuild.pl gandalf_cbxsr.xml
perl C:\ACE\autobuild\autobuild.pl gandalf_vc71.xml
perl C:\ACE\autobuild\autobuild.pl gandalf_vc71dr.xml
perl C:\ACE\autobuild\autobuild.pl gandalf_vc71sd.xml
perl C:\ACE\autobuild\autobuild.pl gandalf_cbxddace.xml
perl C:\ACE\autobuild\autobuild.pl gandalf_dmc.xml
