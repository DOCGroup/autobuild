#!/bin/bash
if [ -e /data/isisbuilds/.enable ]  
then
	rm /data/isisbuilds/.enable
 	svn up $HOME/autobuild
	exec $HOME/autobuild/autobuild.pl $HOME/autobuild/config/autobuild/brick1/brick1.xml 
fi
