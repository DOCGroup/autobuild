@Echo off
setlocal

cvs -r -Q checkout -P autobuild > run.log
cd autobuild
perl -w scoreboard.pl -o ../html -c configs/scoreboard/acetao.xml > ../run.log
cd ..
move run.log html\log.txt