#!/bin/sh

#The buildmatrix database for saving the compilation results locally.
DATABASE_NAME=""

# directory of local db files
DB_FILE_DIR=""

# Script directory
SCRIPT_DIRECTORY=""

# File that contains the list of available db files
REMOTE_FILE_LIST=$DB_FILE_DIR/available_db_files.log

# File for preventing multiple instances occuring
PROTECTION_FILE=$DB_FILE_DIR/GETTING_LOCAL_COMPILATION_DB_FILES.LOCK
# List of files to add to the database
FILES_TO_ADD_TO_DB=files_to_add_to_DB
# Full path to the list of files currently in the database
CURRENT_DB_FILES=files_in_DB
# Script that generates list of files currently in the DB
CURRENT_DB_FILES_SCRIPT=RecentCompilationDBFiles.sh
# Script to add the files to the database
ADD_FILES_TO_DB_SCRIPT=SaveCompilationsToDB.sh
# Return value of this program
RETVAL=0


# Check the file lock
if [ -f $PROTECTION_FILE ]; then
    STARTED_TIME=`cat $PROTECTION_FILE`

    if [ -n "$STARTED_TIME" ]; then
        # add 4 hours (60*60*4) to the number of seconds
        LATE_TIME=`expr $STARTED_TIME + 14400`
        CURRENT_TIME=`date +%s`

        if [ $CURRENT_TIME -gt $LATE_TIME ]; then
            echo "Detected stuck retrieval.  Removing the protection file."
            rm "$PROTECTION_FILE"
        else
            echo "Files still being retrieved."
            exit 0;
        fi
        # end of  if [ $CURRENT_TIME -gt $LATE_TIME ]

    else
        # More likely it is a munged attempt than two processes
        # spawned at about the same time.
        echo "Found empty protection file.  Removing."
        rm "$PROTECTION_FILE"
    fi
    exit 1;
fi

# Create the lock file
date +%s > $PROTECTION_FILE

cd $DB_FILE_DIR

if [ ! -r $REMOTE_FILE_LIST ]; then
    echo "File $REMOTE_FILE_LIST does not exist."
    rm "$PROTECTION_FILE"
    exit 1;
fi

# Get the list of files in the Database
cd $SCRIPT_DIRECTORY
$SCRIPT_DIRECTORY/$CURRENT_DB_FILES_SCRIPT $DATABASE_NAME > $DB_FILE_DIR/$CURRENT_DB_FILES
cd $DB_FILE_DIR

# Find the files that are not currently in the database
for file in `cat $REMOTE_FILE_LIST`
do
    if [ `fgrep $file $CURRENT_DB_FILES 2> /dev/null | wc -l` -eq 0 ]; then
        # Add the file to the list of files to add
        echo "$DB_FILE_DIR/$file" >>  $FILES_TO_ADD_TO_DB
    fi
done

# If there are files to add then add them
if [ -r $FILES_TO_ADD_TO_DB ]; then
    cd $SCRIPT_DIRECTORY
    $SCRIPT_DIRECTORY/$ADD_FILES_TO_DB_SCRIPT $DB_FILE_DIR/$FILES_TO_ADD_TO_DB $DATABASE_NAME
fi

rm "$PROTECTION_FILE"

exit $RETVAL;

