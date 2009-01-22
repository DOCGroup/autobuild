REM $Id$

cd ..\..\..\..\
svn up
cd configs\autobuild\isislab\blade10

call "C:\Program Files\Microsoft Visual Studio .NET 2003\Common7\Tools\vsvars32.bat"
perl C:\bczar\autobuild\autobuild.pl ciao_no_inline.xml
