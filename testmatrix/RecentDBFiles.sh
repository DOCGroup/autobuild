#! /bin/bash

# location of the autobuild directory
AUTOBUILD_DIR="$HOME/autobuild"
TEST_MATRIX_DIR="$AUTOBUILD_DIR/testmatrix"

if [ $# -ne 1 ]; then
  echo "usage: $0 <database name>"
  exit 1
fi

DATABASE_NAME=$1
/usr/bin/python $TEST_MATRIX_DIR/RecentDBFiles.py $DATABASE_NAME

