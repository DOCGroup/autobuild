#!/bin/sh
echo "`date`" > ~/last_run
perl /builds/autobuild/autobuild.pl /builds/autobuild/configs/autobuild/zifnab/Snow_Leopard_Static_Host.xml
perl /builds/autobuild/autobuild.pl /builds/autobuild/configs/autobuild/zifnab/iPhone_3.1.2_Simulator.xml 
perl /builds/autobuild/autobuild.pl /builds/autobuild/configs/autobuild/zifnab/iPhone_3.1.2_Hardware.xml 
sudo shutdown -h now

