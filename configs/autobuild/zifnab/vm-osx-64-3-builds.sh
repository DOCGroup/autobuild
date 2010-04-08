#!/bin/sh
echo "`date`" > ~/last_run
perl /builds/autobuild/autobuild.pl -V /builds/autobuild/configs/autobuild/zifnab/Snow_Leopard_Static_Host.xml

ssh -o ConnectTimeout=15 root@192.168.69.102 reboot
sleep 60
ssh wotte@192.168.69.108 /builds/autobuild/configs/autobuild/zifnab/jailbreak.sh
sleep 60

perl /builds/autobuild/autobuild.pl -V /builds/autobuild/configs/autobuild/zifnab/iPhone_3.1.2_Hardware.xml 
perl /builds/autobuild/autobuild.pl -V /builds/autobuild/configs/autobuild/zifnab/iPhone_3.1.2_Simulator.xml 
perl /builds/autobuild/autobuild.pl -V /builds/autobuild/configs/autobuild/zifnab/iPad_3.2_Simulator.xml 
perl /builds/autobuild/autobuild.pl -V /builds/autobuild/configs/autobuild/zifnab/iPhone_4.0_Simulator.xml
sudo shutdown -h now

