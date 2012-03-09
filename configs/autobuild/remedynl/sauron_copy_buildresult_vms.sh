#!/bin/sh

export RSYNC_RSH=ssh
chmod ugo+r /nfs/openvms/v82ia64/*.html /nfs/openvms/v82ia64/*.txt
rsync -r --progress --delete -z --exclude *.tar* --exclude /*.tar*/ --exclude /ACE_wrappers*/ --include *.txt --include *.html --exclude ** /nfs/openvms/v82ia64/* qnap.remedy.nl::Qweb/Buildlogs/openvmsia64

