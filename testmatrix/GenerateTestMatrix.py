#!/usr/bin/python2.1

# ******************************************************************
#      Author: Heather Drury
#              Justin Michel
#        Date: 7/06/2004
#         $Id$
# ******************************************************************

from HTMLScoreboard import *
from Platform import *
from utils import *

def ReadLogFiles ():
	fh=open(infile,"r")
	builds = []
	# read in text files containing test results for each platform
	for build in fh.readlines():
		name, file = build.split()
		print "********* BUILD", name
		builds.append (Platform (name, file))
	return builds
	fh.close()	

def SaveBuildResults2HTML (directory, fname):
	# now print the results to an HTML file
	for n in range (0, len(builds)):
		builds[n].HTMLtestResults = HTMLPlatformTestTable(builds[n].name, directory)

		# print out the failed tests
		for m in range (0, len(builds[n].test_results)):
			if builds[n].test_results[m].passFlag == FAIL:
				builds[n].HTMLtestResults.addData2 (n, builds[n].test_results[m].passFlag, \
					builds[n].test_results[m].time, \
					builds[n].test_results[m].name)
		# print out the successful tests
		for m in range (0, len(builds[n].test_results)):
			if builds[n].test_results[m].passFlag == PASS:
				builds[n].HTMLtestResults.addData2 (n, builds[n].test_results[m].passFlag, \
					builds[n].test_results[m].time, \
					builds[n].test_results[m].name)
		builds[n].HTMLtestResults.writeHTML()

# build up test matrix
def BuildTestMatrix (builds, directory, fname, filename):
	testMatrix = TestMatrix (len(builds))
	for n in range (0, len(builds)):
		for m in range (0, len(builds[n].test_results)):
			testMatrix.addTestResult (n, builds[n].test_results[m].name, \
					builds[n].test_results[m].passFlag)

	# write out the HTML
	HTMLtestMatrix = HTMLTestMatrix2 (fname, directory)
	for n in range (0, len(testMatrix.testNames)):
		HTMLtestMatrix.addTestData (testMatrix.testNames [n], testMatrix.testResults[n], \
					testMatrix.fileNames [n], builds)

	totalPass = 0
	totalFail = 0
	totalSkip = 0
	for n in range (0, len(builds)):
		builds[n].npass, builds[n].nfail, builds[n].nskip = testMatrix.getTestResults(n)
		totalPass = totalPass + builds[n].npass
		totalFail = totalFail + builds[n].nfail
		totalSkip = totalSkip + builds[n].nskip
	HTMLtestMatrix.writeBriefs (totalPass, totalFail, totalSkip)

	for n in range (0, len(builds)):
		HTMLtestMatrix.writeBuildSummary (n, builds[n])
	getSummaryResults(HTMLtestMatrix, builds, filename)
	HTMLtestMatrix.writeHTML()
	return testMatrix

# Write one HTML file for each test with each row representing a platform
def WriteTestHTML (testMatrix, builds):
	# print out HTML file for each test with results for all platforms
	for n in range (0, len(builds)):
		print "\tPlatform: ", builds[n].name, builds[n].ACEtotal, builds[n].ACEfail, builds[n].TAOtotal, builds[n].TAOfail
	for m in range (0, len(testMatrix.testNames)):
		fname = testMatrix.fileNames[m] + '.html'
		html = HTMLTestFile (fname)
		for n in range (0, len(builds)):
			html.addData2 (testMatrix.testResults[m][n], builds[n].name)
		html.writeHTML()

def getSummaryResults (HTMLtestMatrix, builds, fname):
	ACEtotal = 0
	TAOtotal = 0
	ACEfail = 0
	TAOfail = 0
	for n in range (0, len(builds)):
		print "\tPlatform: ", builds[n].name, builds[n].ACEtotal, builds[n].ACEfail, builds[n].TAOtotal, builds[n].TAOfail
		ACEtotal = ACEtotal+builds[n].ACEtotal
		TAOtotal = TAOtotal+builds[n].TAOtotal
		ACEfail = ACEfail+builds[n].ACEfail
		TAOfail = TAOfail+builds[n].TAOfail
		ACEpass = ACEtotal-ACEfail
		TAOpass = TAOtotal-TAOfail
		ACEperc = ComputePercentage(ACEpass, ACEtotal)
		TAOperc = ComputePercentage(TAOpass, TAOtotal)
		overall = ComputePercentage((TAOpass+ACEpass), (TAOtotal+ACEtotal))
	print "ACE tests ****", ACEtotal, ACEfail, ACEperc 
	print "TAO tests ****", TAOtotal, TAOfail, TAOperc 
	file = "/tmp/matrix_output." + fname + ".txt"
	fh=open(file,"w")
	str = "# of tests passed: %d\n" % (TAOtotal+ACEtotal)
	fh.write (str)
	str = "# of tests failed: %d\n" % (TAOfail+TAOfail)
	fh.write (str)
	percent='%\n'
	str = "Overall percentage: %.0f" % overall 
	str = str+percent
	fh.write (str)
	fh.close()
#
	fname = outfile + ".TestMatrix"
	HTMLtestMatrix.writeSummary (ACEpass, ACEtotal, ACEperc, TAOpass, TAOtotal, TAOperc)

infile=sys.argv[1]
directory=sys.argv[2]
outfile=sys.argv[3]
builds = ReadLogFiles ()
fname = outfile + ".matrix"
testMatrix = BuildTestMatrix (builds, directory, fname, outfile)
SaveBuildResults2HTML(directory,outfile) 
# there is no standardization of how the test names are created for ACE, TAO, until there is, 
# we shouldn't do this HAD 2.11.04
#WriteTestHTML (testMatrix, builds)
print "Normal execution!"
