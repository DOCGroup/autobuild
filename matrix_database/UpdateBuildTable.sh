#! /bin/bash

if [ $# -ne 1 ]; then
  echo "usage: $0 <database name>"
  exit 1
fi
 
DATABASE_NAME=$1
TMDIR=$HOME/nightly/matrix_database
/usr/bin/python2.1 $TMDIR/UpdateBuildTable.py $DATABASE_NAME


