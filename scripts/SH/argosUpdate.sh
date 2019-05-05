#!/bin/sh

# -----------------------------------------------------------------------------------------------
# Things to know beforehand:
#     1) course_info.csv holds the "new" ARGOS report information. course_info_old.csv holds the
#          old course information
# 
#     2) That file is from ARGOS, and is given to the server from ITS 
# -----------------------------------------------------------------------------------------------
# Flow of the ARGOS auto import, generalized so that it is the same for Server and Local testing
#     1) Receive the new file from ITS directly into the home directory
#     2) Check if any changes have been made
#     3) If not, exit. Else, separate the data into old and new changes
#     4) Delete old data, insert new data
#     5) Remove old ARGOS CSV file, rename new CSV file to course_info_old.csv 
# 
# -----------------------------------------------------------------------------------------------
# Relevant files:
#   parseCSVinsert.php : Converts our CSV files to a usable format, then inserts the data into the database
#   parseCSVdelete.php : Same as insert, but it deletes
#   unique_to_old.csv  : Holds the CSV data on items unique to the old version of the ARGOS report
#   unique_to_new.csv  : Same as old, but it holds the new data
# -----------------------------------------------------------------------------------------------


#Point to /argos/course_info.csv and /argos/course_info_old.csv


# Server version
#old="/var/www/html/argos/course_info_old.csv"
#new="/var/www/html/argos/course_info.csv"

# Local version
 old="C:/xampp/htdocs/SchedulingApp/argos/course_info_old.csv"
 new="C:/xampp/htdocs/SchedulingApp/argos/course_info.csv"

# -----------------------------------------------------------------------------------------------


#Point to /argos/unique_to_old.csv and /argos/unique_to_new.csv

# Server version
#unique_to_old="/var/www/html/argos/unique_to_old.csv"
#unique_to_new="/var/www/html/argos/unique_to_new.csv"

# Local version
 unique_to_old="C:/xampp/htdocs/SchedulingApp/argos/unique_to_old.csv"
 unique_to_new="C:/xampp/htdocs/SchedulingApp/argos/unique_to_new.csv"

#Ensure they exist
touch $new
touch $unique_to_old
touch $unique_to_new

#Ensure they're empty
>$unique_to_old
>$unique_to_new


# -----------------------------------------------------------------------------------------------

# This is our default header that we will tack on to the data. This is done to sanitize the comparison in case something is broken with the header in one of the files
header='"Term Code","Term Description","Full/Part Term Description","Course CRN","Course Subject","Course Number","Course Sequence Number","Building Name","Room Number","Course Start Time","Course End Time","Course Start Date","Course End Date","Sunday Indicator","Monday Indicator","Tuesday Indicator","Wednesday Indicator","Thursday Indicator","Friday Indicator","Saturday Indicator","Course Maximum Enrollment","Course Enrollment"'

# -----------------------------------------------------------------------------------------------


if [[ -s $new ]]
then
    # Remove the possibility of conflicting header styles by getting rid of them completely
    printf "%s\n" "$(tail -n +2 $old)" > $old
    printf "%s\n" "$(tail -n +2 $new)" > $new
    

    # We may have to remove the () from the sorts when moved into production
    # Got conflicting results when tried on the C9 bash environment and a windows environment
    comm -2 -3 <(sort $old) <(sort $new) > $unique_to_old # Put items unique to the old version of the class times/locations here
    comm -1 -3 <(sort $old) <(sort $new) > $unique_to_new # Put items unique to the new version of the class times/locations here


    if [[ -s $unique_to_old ]]; # There were items we need to delete
    then
        # -----------------------------------------------------------------------------------------------
        
        
        # Point to '/argos/classesToDelete.csv'
        # Local version
         deleteCSV="C:/xampp/htdocs/SchedulingApp/argos/classesToDelete.csv"
        
        # Server version
        #deleteCSV="/var/www/html/argos/classesToDelete.csv"
        
        # -----------------------------------------------------------------------------------------------
        
        
        # Need the following in the header of the classesToDelete.csv files for associative array headers
        echo $header > $deleteCSV;
        cat $unique_to_old >> $deleteCSV
        
        
        # -----------------------------------------------------------------------------------------------
        
        # Point to '/scripts/PHP/parseCSVdelete.php'
        # Local version
        deletePHP="C:/xampp/htdocs/SchedulingApp/scripts/PHP/parseCSVdelete.php"
        
        # Server version
        #deletePHP="/var/www/html/scripts/PHP/parseCSVdelete.php"
        
        # -----------------------------------------------------------------------------------------------
                
        php $deletePHP $deleteCSV
    fi
        
    if [[ -s $unique_to_new ]]; # There were items we need to add
    then
        
        # -----------------------------------------------------------------------------------------------
        # Point to '/argos/classesToInsert.csv'
        # Local version
        insertCSV="C:/xampp/htdocs/SchedulingApp/argos/classesToInsert.csv"
        
        # Server version
        #insertCSV="/var/www/html/argos/classesToInsert.csv"
        # -----------------------------------------------------------------------------------------------

        # Need the following in the header of the uniqueInsert.csv files for associative array headers
        echo $header > $insertCSV;
        cat $unique_to_new >> $insertCSV
        
        
        # -----------------------------------------------------------------------------------------------
        # Point to '/scripts/PHP/parseCSVinsert.php'
        # Local version
        insertPHP="C:/xampp/htdocs/SchedulingApp/scripts/PHP/parseCSVinsert.php"
        
        # Server version
        #insertPHP="/var/www/html/scripts/PHP/parseCSVinsert.php"
        # -----------------------------------------------------------------------------------------------

        php $insertPHP $insertCSV
        
        # Remove old file, rename new file to old
        rm $old
        mv $new $old
        
        
        # Since at the time of writing this we have no idea if the header block will look like the $header variable or slightly different,
        # we decided to get rid of the possibility completely by removing the first of it and then cat the one we have
        
        # -----------------------------------------------------------------------------------------------
        # Local version
        temp="C:/xampp/htdocs/SchedulingApp/argos/temp.csv"
        
        # Server version
        # temp="/var/www/html/argos/temp.csv"
        # -----------------------------------------------------------------------------------------------        
        
        touch $temp
        echo $header > $temp
        cat $old >> $temp
        cat $temp > $old
        rm $temp
        
    else
        echo "Nothing to update";
        rm $new
        # Do nothing, there were no changes in ARGOS
    fi
    
    
else # Something messed up big time! Empty course_info.csv file causes this.
    echo "Error: Empty incoming data!";
fi
