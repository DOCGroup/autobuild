#!/usr/bin/python2.1

# ******************************************************************
#      Author: Heather Drury
#        Date: 2/13/2004
#         $Id$
# ******************************************************************

PASS = 0
FAIL = 1
SKIP = 3

NEW_FORMAT = 1
OLD_FORMAT = 0

ACE_TEST = 0
TAO_TEST = 1

def findString (string, string_array):
        found = 1
	for m in range (0, len(string_array)):
		if string.find(string_array[m]) == 0:
			found = 0
	return found

def ComputePercentage (numerator, denominator):
	perc = 0.0
	try:
		perc = (float(numerator)/float(denominator))*100.0
	except ZeroDivisionError:
		pass
	return perc

