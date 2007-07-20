cd ..\..\..\
svn up
cd configs\autobuild\remedynl
call "C:\Program Files\Intel\Compiler\C++\10.0.026\IA32\Bin\ICLVars.bat"
perl C:\ACE\autobuild\autobuild.pl aragon_icc10_32.xml
