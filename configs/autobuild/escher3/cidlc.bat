cd ..\..\..\
cvs -z9 up -P -d
cd configs\autobuild\escher3
perl ..\..\..\autobuild.pl cidlcstatic.xml
