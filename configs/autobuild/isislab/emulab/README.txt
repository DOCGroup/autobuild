This directory contains the builds running at emulab. For each 
build create the xml directory and the .ns file and commit this
to svn. Make sure the file name is not longer then 19 characters 
(without extension).

Add the build to the build22.sh file. This gets executed at 22:00
and triggers all daily builds

. Log in to ops.isislab.vanderbilt.edu as bczar
. Run ./svnup.sh to get the .ns/.xml file on the system

. Go to www.isislab.vanderbilt.edu
. Log in as bczar@dre.vanderbilt.edu 
. Click 'Begin an Experiment' on the left hand side of the screen
. Give the experiment an appropriate name
. specify the full path to the ns file you created in the previous  
section, i.e. 
/proj/autobuilds/data/autobuild/configs/autobuild/isislab/emulab/...
.  Uncheck idle-swap, listing reason as 'autobuild'
.  Select 'Skip Linktest' in the Linktest combo box.
.  Check the box for batch mode experiment
.  Click submit.  The emulab software will then parse the ns file and  
set up the experiment.

At this point, the experiment will begin to swap in.  You can click on  
'My Emulab' and then on the link that appears for the newly created  
experiment, and the 'View Activity Logfile' to ensure that the  
experiment successfully swaps in. When it swaps in, a popup box will  
appear to indicate that it is now active.

 From an active shell on ops.isislab.vanderbilt.edu:
.  ssh node.<experiment name>.autobuilds.isislab.vanderbilt.edu

On this node, you can check two log files to monitor the progress of  
the build:
/isisbuilds/build.txt
/proj/autobuilds/logs/<autobuild file>.log

