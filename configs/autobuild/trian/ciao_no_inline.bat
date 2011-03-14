REM $Id$

cd ..\..\..\..\
svn up
cd configs\autobuild\isislab\blade10

call "C:\Program Files (x86)\Microsoft Visual Studio 9.0\Common7\Tools\vsvars32.bat"
perl C:\bczar\autobuild\autobuild.pl ciao_no_inline.xml
