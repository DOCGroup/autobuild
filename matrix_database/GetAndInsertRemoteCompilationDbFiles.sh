#!/bin/sh

The buildmatrix database
DATABASE_NAME=""
# Webserver of the remote db files
WEBSERVER=""
# Directory on the webserver where the db files are stored
WEBDIR=""
# Script directory
SCRIPT_DIRECTORY=""

# File on the remote server that contains the list of available db files
REMOTE_FILE_LIST=available_db_files.log

# File for preventing multiple instances occuring
PROTECTION_FILE=/tmp/GETTING_REMOTE_COMPILATION_DB_FILES.LOCK
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


function getfile()
{
   wget --quiet --timestamping --tries=3 --wait=10 "http://$WEBSERVER/$WEBDIR/$1"
}


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

# Directory to hold the downloaded db files
DB_TEMP_DIR=`mktemp -q -d $PROTECTION_FILE.XXXXXX`
if [ $? -ne 0 ]; then
    echo "$0: failed to make temp directory"
    rm "$PROTECTION_FILE"
    exit 1;
fi

cd $DB_TEMP_DIR

# Download the list of db files available on the remote server
getfile $REMOTE_FILE_LIST
if [ ! -r $REMOTE_FILE_LIST ]; then
    echo "File $REMOTE_FILE_LIST was not downloaded properly."
    rm -rf $DB_TEMP_DIR
    rm "$PROTECTION_FILE"
    exit 1;
fi

# Get the list of files in the Database
cd $SCRIPT_DIRECTORY
$SCRIPT_DIRECTORY/$CURRENT_DB_FILES_SCRIPT > $DB_TEMP_DIR/$CURRENT_DB_FILES
cd $DB_TEMP_DIR

# Find the files that are not currently in the database
for file in `cat $REMOTE_FILE_LIST`
do
    if [ `fgrep $file $CURRENT_DB_FILES 2> /dev/null | wc -l` -eq 0 ]; then
        getfile $file
        if [ $? -eq 0 ]; then
            # Add the file to the list of files to add
            echo "$DB_TEMP_DIR/$file" >>  $FILES_TO_ADD_TO_DB
        else
            echo "Failed to retrieve file: $file"
            RETVAL=1
        fi
    fi
done

# If there are files to add then add them
if [ -r $FILES_TO_ADD_TO_DB ]; then
    cd $SCRIPT_DIRECTORY
    $SCRIPT_DIRECTORY/$ADD_FILES_TO_DB_SCRIPT $DB_TEMP_DIR/$FILES_TO_ADD_TO_DB $DATABASE_NAME
fi

rm -rf $DB_TEMP_DIR
rm "$PROTECTION_FILE"

exit $RETVAL;

