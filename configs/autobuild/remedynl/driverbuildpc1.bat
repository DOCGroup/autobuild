cd ..\..\..\
cvs -z9 up -P -d
cd configs\autobuild\remedynl
rem perl D:\autobuild\autobuild.pl MingWGCC31.xml
perl D:\autobuild\autobuild.pl CygwinGCC2_95_3_5.xml BCB6DynamicRelease.xml BCB6DynamicDebugWChar.xml BCB6DynamicDebug.xml
dobuildpc1
