
#!/bin/sh
echo "`date`" > ~/last_run

perl /builds/autobuild/autobuild.pl -V /builds/autobuild/configs/autobuild/zifnab/Snow_Leopard_Static_Host.xml
perl /builds/autobuild/autobuild.pl -V /builds/autobuild/configs/autobuild/zifnab/iPad_3.2_Simulator.xml 
perl /builds/autobuild/autobuild.pl -V /builds/autobuild/configs/autobuild/zifnab/iPhone_4.0_Simulator.xml
sudo shutdown -h now

