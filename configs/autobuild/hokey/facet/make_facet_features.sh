#!/bin/sh
# $Id$
# Author: Dante Cannarozzi
#
# Purpose: 
# Create the a series of files to build facet with different features
# enabled
#
# Usage:
# Just run it! Requires add_feature.gawk (which should be in this dir)
#
# Notes:
# A few of the features have dependent features.
# For now that consists of event_pull, which we just enable ttl as
# well and for building the tao-facet-adapter we need 
# correlation_filter and ttl enabled. Do these by hand (using
# add_feature.gawk) 


# be explicit in using the default template
TEMPLATE=facet_template.xml

FEATURES="
 consumer_dispatch
 correlation_filter
 eventtype
 eventvector
 realtime_dispatcher
 rtec_correlation_filter
 source_filter
 supplier_dispatch
 throughput_test
 timestamp
 tracing
 ttl"
for f in $FEATURES 
do
    add_feature.gawk $TEMPLATE $f > facet-$f.xml
done
