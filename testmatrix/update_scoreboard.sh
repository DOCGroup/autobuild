#!/bin/sh

# Purpose: Update the scoreboard and test matrix
# Original author: Byron Harris
# Modified : Aug 17 2004 : Trevor Fields

# Directory where the build log directories are
LOG_DIR="/project/taotmp/scoreboard/html"

# location of the autobuild directory
AUTOBUILD_DIR="$HOME/autobuild"
TEST_MATRIX_DIR="$AUTOBUILD_DIR/testmatrix"

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


  # file with the list of builds
  BUILD_LIST=$TEST_MATRIX_DIR/ace-list

  # beginning of the name of the test matrix
  # the name will have ".matrix.html" appended to it
  TEST_MATRIX=ace_detailed

  # generate the list of files
  perl ./test-list-extract.pl -i $SCOREBOARD_CONFIG_DIR/ace.xml > $BUILD_LIST

  # generate the matrix
  ./buildMatrix $BUILD_LIST $TEST_MATRIX


  BUILD_LIST=$TEST_MATRIX_DIR/ace_future-list
  TEST_MATRIX=ace_future_detailed
  perl ./test-list-extract.pl -i $SCOREBOARD_CONFIG_DIR/ace_future.xml > $BUILD_LIST
  ./buildMatrix $BUILD_LIST $TEST_MATRIX


  BUILD_LIST=$TEST_MATRIX_DIR/tao-list
  TEST_MATRIX=tao_detailed
  perl ./test-list-extract.pl -i $SCOREBOARD_CONFIG_DIR/tao.xml > $BUILD_LIST
  ./buildMatrix $BUILD_LIST $TEST_MATRIX


  BUILD_LIST=$TEST_MATRIX_DIR/tao_future-list
  TEST_MATRIX=tao_future_detailed
  perl ./test-list-extract.pl -i $SCOREBOARD_CONFIG_DIR/tao_future.xml > $BUILD_LIST
  ./buildMatrix $BUILD_LIST $TEST_MATRIX


  cp -f matrix.css $LOG_DIR/matrix.css
}



if [ -d "$LOG_DIR" ]; then

  # Protect against simultaneous attempts to build the
  # test matrix.
  if [ ! -f "$TEST_MATRIX_PROTECTION_FILE" ]; then
    touch "$TEST_MATRIX_PROTECTION_FILE"
    update_local_scoreboard
    rm "$TEST_MATRIX_PROTECTION_FILE"
  else
    echo "Matrix is still being built."
  fi

fi

exit 0

