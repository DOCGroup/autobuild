REM $Id$

call "C:\Program Files (x86)\Microsoft Visual Studio 9.0\Common7\Tools\vsvars32.bat"

cd "C:\ACE\autobuild"

svn up

perl autobuild.pl configs\autobuild\trian\versioned_namespace.xml
