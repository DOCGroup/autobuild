rem This batch file is used to upload all logfiles manually on buildpc3 in case of a network failure
start d:\putty\pageant.exe d:\putty\privatenokey
sleep 4
set CVS_RSH=plink
pscp D:\ACE\BCB6dd\*.txt D:\ACE\BCB6dd\*.html bugzilla@charanga.cs.wustl.edu:.www-docs/auto_compile_logs/remedy.nl_Win2K_BCB6_Dynamic_Debug
pscp D:\ACE\BCB6ddu\*.txt D:\ACE\BCB6ddu\*.html bugzilla@charanga.cs.wustl.edu:.www-docs/auto_compile_logs/remedy.nl_Win2K_BCB6_Dynamic_Debug_Unicode
pscp D:\ACE\MingW\*.txt D:\ACE\MingW\*.html bugzilla@charanga.cs.wustl.edu:.www-docs/auto_compile_logs/remedy.nl_Win2K_MingW
pscp D:\ACE\BCB6dr\*.txt D:\ACE\BCB6dr\*.html bugzilla@charanga.cs.wustl.edu:.www-docs/auto_compile_logs/remedy.nl_WinNT4_BCB6_Dynamic_Release
pscp D:\ACE\BCB6dru\*.txt D:\ACE\BCB6dru\*.html bugzilla@charanga.cs.wustl.edu:.www-docs/auto_compile_logs/remedy.nl_Win2K_BCB6_Dynamic_Release_Unicode