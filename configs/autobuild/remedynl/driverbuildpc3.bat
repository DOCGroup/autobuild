cd ..\..\..\
set CVS_RSH=ssh
cvs -d :ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\remedynl
perl C:\ACE\autobuild\autobuild.pl Cygwin.xml
REM perl C:\ACE\autobuild\autobuild.pl MingW.xml
perl C:\ACE\autobuild\autobuild.pl vc7.xml
perl C:\ACE\autobuild\autobuild.pl BCB6StaticRelease.xml
perl C:\ACE\autobuild\autobuild.pl cbxpreview.xml
perl C:\ACE\autobuild\autobuild.pl cbxdd.xml
	
