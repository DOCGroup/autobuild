REM $Id$

call "C:\Program Files\Microsoft Visual Studio .NET 2003\Common7\Tools\vsvars32.bat"

cd "C:\Documents and Settings\bczar\autobuild"

set CVS_RSH=c:\cygwin\bin\ssh
c:\cygwin\bin\cvs -d :ext:isisbuilds@cvs.doc.wustl.edu:/project/cvs-repository -z9 up -P -d

perl autobuild.pl configs\autobuild\isislab\blade11\ace_for_tao.xml
