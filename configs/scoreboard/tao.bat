@Echo off
setlocal

cvs -r -Q checkout -P autobuild > run.log
cd autobuild
perl -w scoreboard.pl -o ../html -c configs/scoreboard/acetao.xml > ../run.log
perl -w scoreboard.pl -d ../html -i configs/scoreboard/index.xml > ../run.log
perl -w scoreboard.pl -d ../html -f configs/scoreboard/ace.xml -o ace.html >> ../run.log
perl -w scoreboard.pl -d ../html -f configs/scoreboard/ace_future.xml -o ace_future.html >> ../run.log
perl -w scoreboard.pl -d ../html -f configs/scoreboard/tao.xml -o tao.html >> ../runlog
perl -w scoreboard.pl -d ../html -f configs/scoreboard/tao_future.xml -o tao_future.html >> ../run.log
perl -w scoreboard.pl -d ../html -f configs/scoreboard/misc.xml -o misc.html >> ../run.log
perl -w scoreboard.pl -d ../html -z >> ../run.log
cd ..
move run.log html\log.txt