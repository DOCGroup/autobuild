#! /bin/bash


TMDIR=$HOME/nightly/matrix_database
DB_LOCK=$TMDIR/DATABASE_TEST_INSERTION.LOCK

if [ $# -ne 2 ]; then
  echo "usage: $0 <Listdbfiles> <database name>"
  echo "       Listdbfiles - absolute filename of the file containing the"
  echo "                     list of the db files"
  exit 1
fi

DBFILELIST=$1
DATABASE_NAME=$2

if [ -f $DB_LOCK ]; then
   echo "Another database update hasn't finished"
   exit 1
fi

touch $DB_LOCK

/usr/bin/python2.1 $TMDIR/SaveTestsToDB.py $DBFILELIST $DATABASE_NAME

rm -f $DB_LOCK
			       
