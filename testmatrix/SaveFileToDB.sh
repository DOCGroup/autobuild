#! /bin/bash


# location of the autobuild directory
AUTOBUILD_DIR="$HOME/autobuild"
TEST_MATRIX_DIR="$AUTOBUILD_DIR/testmatrix"
DB_LOCK=$TEST_MATRIX_DIR/DATABASE_INSERTION.LOCK
# name of the database for saving test results from remote db files.
DATABASE_NAME=testmatrix

if [ $# -ne 1 ]; then
  echo "usage: $0 <Listdbfiles>"
  echo "       Listdbfiles - absolute filename of the file containing the"
  echo "                     list of the db files"
  exit 1
fi

DBFILELIST=$1


if [ -f $DB_LOCK ]; then
   echo "Another database update hasn't finished"
   exit 1
fi

touch $DB_LOCK

/usr/bin/python $TEST_MATRIX_DIR/SaveFileToDB.py $DBFILELIST $DATABASE_NAME

rm -f $DB_LOCK
			       
