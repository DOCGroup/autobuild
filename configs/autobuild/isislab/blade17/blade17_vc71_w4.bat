rem $Id$
rem perl C:\ACE\autobuild\autobuild.pl blade17_vc71.xml

cd C:\ACE\autobuild
set CVS_RSH=c:\cygwin\bin\ssh
c:\cygwin\bin\cvs -q -d :ext:isisbuilds@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d

perl autobuild.pl  configs\autobuild\isislab\blade17\blade17_vc71_w4.xml
