#!/usr/bin/python2.1

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
#			print "Found string", line
			found = 0
	return found

def ComputePercentage (numerator, denominator):
	perc = 0.0
	try:
		perc = (float(numerator)/float(denominator))*100.0
	except ZeroDivisionError:
		pass
#		print "divide by zero attempt"
	return perc

def trim(line):
        return line.strip();

def txt2DbFname (txtFname):
	splits = txtFname.split("/")
	length = len(splits)
	dbFname = splits[length - 2] + "_" + splits[length - 1]
	dbFname = dbFname.replace(".txt", ".db")
	return dbFname 								
