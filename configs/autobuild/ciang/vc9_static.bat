rem  $Id$
rem perl C:\ACE\autobuild\autobuild.pl blade17_vc71.xml

cd C:\ACE\autobuild
svn up

perl autobuild.pl  configs\autobuild\chiang\vc9_static.xml
