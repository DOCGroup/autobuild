rem $Id$
rem perl C:\ACE\autobuild\autobuild.pl merengue_vc71.xml

cd ..\..\..\
set PATH="c:\Program Files\CollabNet Subversion\";%PATH%
svn up
cd configs\autobuild\merengue

call cidlc.bat
call merengue_vc71.bat
