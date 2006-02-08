rem $Id$
rem perl C:\ACE\autobuild\autobuild.pl merengue_vc71.xml

cd C:\ACE\autobuild
set CVS_RSH=plink
cvs -q -d :ext:mxiong@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d

perl autobuild.pl  configs\autobuild\isislab\blade17\blade17_vc71.xml
