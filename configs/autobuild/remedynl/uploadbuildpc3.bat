rem This batch file is used to upload all logfiles manually on buildpc3 in case of a network failure
set CVS_RSH=ssh
scp -C D:\ACE\MingW\*.txt D:\ACE\MingW\*.html bugzilla@charanga.cs.wustl.edu:.www-docs/auto_compile_logs/remedy.nl_Win2K_MingW
