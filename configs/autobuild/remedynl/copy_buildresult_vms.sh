#!/bin/sh

export RSYNC_RSH=ssh
chmod ugo+r *.html *.txt
rsync -r --progress --delete -z --exclude *.tar* --exclude /*.tar*/ --exclude /ACE_wrappers*/ --exclude /x54/ --include *.txt --include *.html --exclude ** ./ qnap.remedy.nl::Buildlogs/openvmsia64

