cd $HOME/ACE/GCC

ssh bugzilla@charanga.cs.wustl.edu rm .www-docs/auto_compile_logs/remedy.nl_SuSE81_GCC/* -f

scp -C *.txt *.html bugzilla@charanga.cs.wustl.edu:.www-docs/auto_compile_logs/remedy.nl_SuSE81_GCC