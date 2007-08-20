rem  $Id$
rem perl C:\ACE\autobuild\autobuild.pl blade17_vc71.xml

cd C:\ACE\autobuild
svn up

perl autobuild.pl  configs\autobuild\isislab\blade17\blade17_vc71.xml
perl autobuild.pl  configs\autobuild\isislab\blade17\blade17_vc71_static.xml
