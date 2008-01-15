#!/bin/bash
if [ -e /build/isisbuilds/.enable ]  
then
	rm /build/isisbuilds/.enable
 	svn up $HOME/autobuild
	exec $HOME/autobuild/autobuild.pl $HOME/autobuild/config/autobuild/slug01/slug01.xml 
fi
