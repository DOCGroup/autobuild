REM $Id$

call "C:\Program Files\Microsoft Visual Studio .NET 2003\Common7\Tools\vsvars32.bat"

cd "C:\Documents and Settings\bczar\autobuild"

svn up

perl autobuild.pl configs\autobuild\isislab\blade11\versioned_namespace.xml
