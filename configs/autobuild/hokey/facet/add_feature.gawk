#!/bin/gawk -f
# $Id$
# Author:  Dante Cannarozzi

# Purpose: 
# Automate the process of adding features to the facet builds.  Since
# the facet-*.xml files are pretty much exactly the same, we want to
# be able to add new "features" easily.  The only real difference
# between the files is the log_root and the 
# -Duse_feature_<some feature>=t passed to Ant. 

# Use: 
# Reads in a template for the xml file from facet_template.xml
# Takes a feature to enable
# Outputs (to standard out) a new file that will build the feature

# Example:
# ./add_feature ttl
# will use the default template enable the ttl feature
#
# ./add_feature myfacet_template.xml ttl
# will read myfacet_template.xml and enable the ttl feature

BEGIN {
    # check the command line args
    if (ARGC < 2) {
	print "";
	print "Error: you must specify at least a feature to enable";
	print "Usage:";
	print "add_feature [template file] <feature>";
	print "The template file is optional, and uses facet_template.xml by default";
	print "";
	print "Examples:";
	print "add_feature ttl";
	print "add_feature facet_template.xml ttl";
	print "";
	exit;
    }

    # Anything on the cmd line not in the form of VAR=VALUE is treated
    # as a file to be processed. We want to be able to specify a feature
    # as well as a template file to use (or optionally use the default)
    # so we do some trickery to avoid the problem

    # use the default template
    if (ARGC == 2) {
	print "Using the default template" > "/dev/stderr";
	feature = ARGV[1];
	FILENAME = ARGV[1] = "facet_template.xml";
    } 
    # user specifies a template
    else {
	print "Using the template " ARGV[1] > "/dev/stderr";
	feature = ARGV[2];
	ARGC = 2;
    }

    logfile = "hokey_facet/" feature;
    
}

# match on every line in the file
{
    # replace the cvs Id tag
    sub(/\$Id.*\$/,"\$Id\$");

    # gsub matches all instances of the pattern
    gsub(/\#logfile\#/,logfile);
    gsub(/\#feature\#/,feature);
    # print the (modified) line out
    print;
}
