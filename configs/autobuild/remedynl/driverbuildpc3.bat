cd ..\..\..\
set CVS_RSH=ssh
cvs -d :ext:jwillemsen@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d
cd configs\autobuild\remedynl
perl D:\ACE\autobuild\autobuild.pl Cygwin.xml
perl D:\ACE\autobuild\autobuild.pl MingW.xml
perl D:\ACE\autobuild\autobuild.pl VC7.xml
perl D:\ACE\autobuild\autobuild.pl BCB6StaticRelease.xml
perl D:\ACE\autobuild\autobuild.pl cbxpreview.xml
perl D:\ACE\autobuild\autobuild.pl cbxdd.xml
	
