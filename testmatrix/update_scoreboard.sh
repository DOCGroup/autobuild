#! /bin/bash

# Purpose: Update the scoreboard and test matrix
# Original author: Byron Harris
# Modified : Aug 17 2004 : Trevor Fields

# Directory where the build log directories are
LOG_DIR="/project/taotmp/scoreboard/html"
TEST_MATRIX_DIR="$HOME/autobuild/testmatrix"

function update_local_scoreboard()
{

  # Update the scoreboard
#  $HOME/autobuild/scoreboard.pl -f $HOME/autobuild/configs/scoreboard/acetao.xml -d $LOG_DIR -o acetao.html

  # change directory to the testmatrix directory
  cd $TEST_MATRIX_DIR

  # build the list of builds
  make


  # list of builds that was updated by the make
  BUILD_LIST=$TEST_MATRIX_DIR/ace-list

  # beginning of the name of the test matrix
  # the name will have ".matrix.html" appended to it
  TEST_MATRIX=ace_detailed

  # generate the matrices
  ./buildMatrix $BUILD_LIST $TEST_MATRIX


  BUILD_LIST=$TEST_MATRIX_DIR/ace_future-list
  TEST_MATRIX=ace_future_detailed
  ./buildMatrix $BUILD_LIST $TEST_MATRIX


  BUILD_LIST=$TEST_MATRIX_DIR/tao-list
  TEST_MATRIX=tao_detailed
  ./buildMatrix $BUILD_LIST $TEST_MATRIX


  BUILD_LIST=$TEST_MATRIX_DIR/tao_future-list
  TEST_MATRIX=tao_future_detailed
  ./buildMatrix $BUILD_LIST $TEST_MATRIX


  cp -f matrix.css $LOG_DIR/matrix.css
}



if [ -d "$LOG_DIR" ]; then

  update_local_scoreboard

fi

exit 0

