#!/bin/sh

SCOREBOARD=/export/web/www/scoreboard
DB_FILE_DIR=$SCOREBOARD/compilation_matrix_db
OLD_NUMBER_DAYS=+3
LIST_FILENAME=available_db_files.log

cd $DB_FILE_DIR

rm $LIST_FILENAME

find . -name '*.db' -ctime $OLD_NUMBER_DAYS -exec rm {} \;

ls *.db > $LIST_FILENAME.tmp

mv $LIST_FILENAME.tmp $LIST_FILENAME

