REM $Id$

cd ..\..\..\..\
svn up

call "C:\Program Files (x86)\Microsoft Visual Studio 9.0\Common7\Tools\vsvars32.bat"
perl C:\bczar\autobuild\autobuild.pl configs\autobuild\trian\ciao_no_inline.xml
