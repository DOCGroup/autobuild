#!/bin/bash
export user=`whoami`
sudo chown $user /build
echo "Starting $1 autobuild run at `date`" > /proj/autobuilds/logs/$1.log
echo "Creating build partition...." >> /proj/autobuilds/logs/$1.log
sudo parted --script /dev/sda mkpartfs primary ext2 10000 35000
echo "Sleeping for 20 seconds to allow kernel time to update partition table..." >> /proj/autobuilds/logs/$1.log
sleep 20
echo "Creating filesystem on new partition" >> /proj/autobuilds/logs/$1.log
sudo mkfs.ext3 /dev/sda4
sudo mkdir /isisbuilds
sudo mount -t ext3 /dev/sda4 /isisbuilds
sudo chown -R $user /isisbuilds
echo "Starting build..." >> /proj/autobuilds/logs/$1.log
perl /proj/autobuilds/data/autobuild/autobuild.pl -v /proj/autobuilds/data/autobuild/configs/autobuild/isislab/emulab/$1.xml 2>&1 >> /proj/autobuilds/logs/$1.log
echo "Syncing logs...." >> /proj/autobuilds/logs/$1.log
cd /proj/autobuilds/logs/$1
#rsync --progress --recursive --delete -z --exclude /ACE_wrappers*/ --exclude /utils*/ --include  *.txt --include *.html --exclude ** ./  bczar@naboo.dre.vanderbilt.edu:/web/users/isisbuilds/auto_compile_logs/isislab/emulab/$1 2>&1 >> /proj/autobuilds/logs/$1
echo "Ending autobuild run at `date`" >> /proj/autobuilds/logs/$1.log
