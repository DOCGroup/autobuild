#!/bin/sh

# Purpose: Update the scoreboard and test matrix
# Original author: Byron Harris
# Modified : Aug 17 2004 : Trevor Fields

# Directory where the build log directories are
LOG_DIR="/export/web/www/scoreboard"

# location of the autobuild directory
AUTOBUILD_DIR="$HOME/autobuild"
TEST_MATRIX_DIR="$AUTOBUILD_DIR/testmatrix"
# Location of database scripts directory
DB_SCRIPT_DIRECTORY="$AUTOBUILD_DIR/matrix_database"


# name of the file used to prevent running the update at the same time
TEST_MATRIX_PROTECTION_FILE="$TEST_MATRIX_DIR/MATRIX_UNDER_CONSTRUCTION"

# location of the scoreboard configuration files
SCOREBOARD_CONFIG_DIR="$AUTOBUILD_DIR/configs/scoreboard"

PERLLIB=$AUTOBUILD_DIR
export PERLLIB

function update_local_scoreboard()
{

  # Update the scoreboard
  #  $HOME/autobuild/scoreboard.pl -f $SCOREBOARD_CONFIG_DIR/acetao.xml -d $LOG_DIR -o acetao.html

  # change directory to the testmatrix directory
  cd $TEST_MATRIX_DIR

  # directory for output the db file
  DBLOGDIR=$LOG_DIR/test_matrix_db

  # create the db log file directory if it does not exist
  if [ ! -d $DBLOGDIR ]; then 
     mkdir -p $DBLOGDIR
  fi

  # file with the list of builds
  BUILD_LIST=$TEST_MATRIX_DIR/ace-list

  # beginning of the name of the test matrix
  # the name will have ".matrix.html" appended to it
  TEST_MATRIX=ace_detailed

  # generate the list of files
  perl ./test-list-extract.pl -i $SCOREBOARD_CONFIG_DIR/ace.xml > $BUILD_LIST

  # generate the matrix and the *.db files
  ./buildMatrix 1 $BUILD_LIST $TEST_MATRIX


  BUILD_LIST=$TEST_MATRIX_DIR/ace_future-list
  TEST_MATRIX=ace_future_detailed
  perl ./test-list-extract.pl -i $SCOREBOARD_CONFIG_DIR/ace_future.xml > $BUILD_LIST
  ./buildMatrix 0 $BUILD_LIST $TEST_MATRIX


  BUILD_LIST=$TEST_MATRIX_DIR/tao-list
  TEST_MATRIX=tao_detailed
  perl ./test-list-extract.pl -i $SCOREBOARD_CONFIG_DIR/tao.xml > $BUILD_LIST
  
  # generate the matrix and the *.db files
  ./buildMatrix 1 $BUILD_LIST $TEST_MATRIX


  BUILD_LIST=$TEST_MATRIX_DIR/tao_future-list
  TEST_MATRIX=tao_future_detailed
  perl ./test-list-extract.pl -i $SCOREBOARD_CONFIG_DIR/tao_future.xml > $BUILD_LIST
  ./buildMatrix 0 $BUILD_LIST $TEST_MATRIX

  
  BUILD_LIST=$TEST_MATRIX_DIR/ciao-list
  TEST_MATRIX=ciao_detailed
  perl ./test-list-extract.pl -i $SCOREBOARD_CONFIG_DIR/ciao.xml > $BUILD_LIST
  ./buildMatrix 0 $BUILD_LIST $TEST_MATRIX

  cp -f matrix.css $LOG_DIR/matrix.css

  # update the list of db files
  $DB_SCRIPT_DIRECTORY/RemoveAndListTestDbFiles.sh
}



if [ -d "$LOG_DIR" ]; then

  # Protect against simultaneous attempts to build the
  # test matrix.
  if [ ! -f "$TEST_MATRIX_PROTECTION_FILE" ]; then
    date +%s > $TEST_MATRIX_PROTECTION_FILE
    update_local_scoreboard
    rm "$TEST_MATRIX_PROTECTION_FILE"
  else
    STARTED_TIME=`cat $TEST_MATRIX_PROTECTION_FILE`

    if [ -n "$STARTED_TIME" ]; then
      # add 4 hours (60*60*4) to the number of seconds
      LATE_TIME=`expr $STARTED_TIME + 14400`
      CURRENT_TIME=`date +%s`

      if [ $CURRENT_TIME -gt $LATE_TIME ]; then
        echo "Detected stuck Matrix generation.  Removing the protection file."
        rm "$TEST_MATRIX_PROTECTION_FILE"
      else
        echo "Matrix is still being built."
      fi
      # end of  if [ $CURRENT_TIME -gt $LATE_TIME ]

    else
      # More likely it is a munged attempt than two processes
      # spawned at about the same time.
      echo "Found empty protection file.  Removing."
      rm "$TEST_MATRIX_PROTECTION_FILE"
    fi 
    # end of  if [ -n $STARTED_TIME ]

  fi
  # end of  if [ ! -f "$TEST_MATRIX_PROTECTION_FILE" ]

fi

exit 0

