Hi Johnny -

I have set up for CORBAecompact build, if you could follow the  
instructions below to ensure that they are descriptive enough, I'd  
appriciate it!

thanks,
/-Will

.  Log in to ops.isislab.vanderbilt.edu as bczar
.  change directory to /proj/autobuilds/nsfiles
.  create a .ns file for your build (use an existing ns file for  
reference), most importantly setting an appropriate value for tb-set- 
node-startcmd.

.  Go to www.isislab.vanderbilt.edu
.  Log in as bczar@dre.vanderbilt.edu 
.  Click 'Begin an Experiment' on the left hand side of the screen
.  Give the experiment an appropriate name
.  specify the full path to the ns file you created in the previous  
section, i.e. /proj/autobuilds/nsfiles/foo.ns
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

To automatically schedule the experiment, from a shell on  
ops.isislab.vanderbilt.edu as bczar:
. crontab -e
. Schedule a /users/bczar/runbuild.sh for the name of the build  
created on www.isislab.vanderbilt.edu.

