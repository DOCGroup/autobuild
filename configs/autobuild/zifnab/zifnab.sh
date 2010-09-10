svn up /builds/autobuild

ssh -o ConnectTimeout=15 root@192.168.69.102 reboot
ssh -o ConnectTimeout=15 root@192.168.69.146 reboot

sh /builds/autobuild/configs/autobuild/zifnab/clang-builds.sh &

perl /builds/autobuild/autobuild.pl -V /builds/autobuild/configs/autobuild/zifnab/cosmic.xml &
perl /builds/autobuild/autobuild.pl -V /builds/autobuild/configs/autobuild/zifnab/Snow_Leopard_Static_Host_Fast.xml

perl /builds/autobuild/autobuild.pl -V /builds/autobuild/configs/autobuild/zifnab/iPad_3.2_Hardware.xml &
#Sleep an hour to give this build a head start.
sleep 300
# Slower build needs to come second
perl /builds/autobuild/autobuild.pl -V /builds/autobuild/configs/autobuild/zifnab/iPhone_3.1.2_Hardware.xml 
