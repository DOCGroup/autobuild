#!/bin/sh
#
# $Id$
#

LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH
 
if [ $# -gt 0 ]; then
  config_file="$1"
else
  echo "ERROR: must provide name of configuration"
  exit 1;
fi

if [ "$config_file" = "sol9_spro54" ]; then 
  PATH=/export/home/opt/SUNWspro/bin:$PATH
fi

PATH=/usr/local/bin:$PATH
export PATH

exec /usr/bin/perl $HOME/development/ace/autobuild/autobuild.pl \
                             $HOME/development/ace/autobuild/configs/autobuild/dresystems/${config_file}.xml 2>&1 
