#!/usr/bin/python

# ******************************************************************
#      Author: Heather Drury
#              Justin Michel
#        Date: 3/25/2004
#         $Id$
# ******************************************************************

import os, sys, string, fileinput, re, math, time
from utils import *
from DBConfig import *

#patterns for log file
compile_error = re.compile(r'error',re.IGNORECASE)
test_error = re.compile(r'Error|ERROR|fatal|EXCEPTION|ACE_ASSERT|Assertion|Mismatched free|are definitely lost in loss record|Invalid write of size|Invalid read of size|pure virtual ')
ace_test_start = re.compile (r'Running')
build_begin = re.compile(r'#################### Begin');
build_end   = re.compile(r'#################### End');

#ASSUMPTION
# each test start signfified by "auto_run_tests:" and ends with "auto_run_tests_finished:"
test_start = re.compile (r'auto_run_tests:')
test_finished = re.compile (r'auto_run_tests_finished:')

# represents one instance of one test
class ACE_TAO_Test:
	def __init__ (self, name, result, time, flag): 
		self.name = name
		self.result = int(result)
		self.time = float(time)
		self.passFlag = flag

class TestMatrix:
	def __init__ (self, num_platforms):
		self.name = "Test Matrix for ACE/TAO"
		# max number of tests = 500, just for initialization of array
		self.max_tests = 1000
		self.testResults =[[0]*num_platforms for row in range(self.max_tests)]
		for n in range (0, self.max_tests): 
			for m in range (0, num_platforms): 
				self.testResults[n][m] = SKIP 
		self.testNames = []
		self.fileNames = [] 

	def getTestResults (self, build_num):
		npass = 0
		nfail = 0
		nskip = 0
		for n in range (0, len(self.testNames)): 
			if self.testResults[n][build_num] == SKIP:
				nskip = nskip+1
			if self.testResults[n][build_num] == FAIL:
				nfail = nfail+1
			if self.testResults[n][build_num] == PASS:
				npass = npass+1
		return npass, nfail, nskip

	def getAllTestResults (self, nbuilds):
		npass = 0
		nfail = 0
		nskip = 0
		print "***", ntests, nplatforms
		for m in range (0, nbuilds): 
			a, b, c = self.computeTestResults(m)
			npass = npass + a
			nfail = nfail + b
			nskip = nskip + c
		return npass, nfail, nskip

	def addTestResult (self, build_num, name, result):
		if len(self.testNames) >= self.max_tests:
			print "Error: exceeded maximum number of tests"
		if name not in self.testNames:
			# test is not yet added, so add it
			self.testNames.append(name)
		else:
			pass
		# idx is index corresponding to this test 
		idx = self.testNames.index(name)
		self.testResults[idx][build_num] = result

		# get filename for later HTML writing
		splits = name.split("/") 
		fname = ""
		if len(splits) == 1:
			fname = name 
		else:
			l = len(splits)
			fname = splits [l-2]		
		self.fileNames.append(fname)

class TestPlatform:
        def __init__(self, name, raw_file, db_file=""):
                self.valid_raw_file = 1
                self.valid_db_file = 1
                self.db_file = db_file
                self.name = name
                self.raw_file = raw_file
                self.compile = PASS
                self.npass = 0
                self.nfail = 0
                self.nskip = 0
                self.ACEtotal = 0
                self.ACEfail = 0
                self.TAOtotal = 0
                self.TAOfail = 0
                self.testMin = 4000.0
                self.testMax = 0.0
                self.timeTotal = 0.0
                self.test_results = []
                self.start_time = ""
                self.end_time = ""
                if self.db_file != "":
                   self.processDBLog()
                else:
                   self.processLog()
                   if (self.start_time == "" or self.end_time == "" or len(self.test_results) == 0):
                      self.valid_raw_file = 0

                #print "platform ", self.name, self.raw_file, self.start_time, self.end_time

        def writeDBLog(self):
                fname = TestDBFileConfig.dbdir_w + "/" + txt2DbFname(self.raw_file)
                tmpfname = fname + ".tmp"
                fh = open(tmpfname, "w")
                fh.write(self.name + "\n")
                fh.write(self.raw_file + "\n")
                fh.write(self.start_time + "\n")
                fh.write(self.end_time + "\n")
                fh.write(str(self.compile) + "\n")
                for n in range(0, len(self.test_results)):
                   test_str = self.test_results[n].name + ";" + str(self.test_results[n].passFlag) + ";" + str(self.test_results[n].time)
                   fh.write (test_str + "\n")
                fh.close()
                os.rename(tmpfname, fname)

        def writeDBLog(self):
                fname = DBFileConfig.dbdir_w + "/" + txt2DbFname(self.raw_file)
                tmpfname = fname + ".tmp"
                fh = open(tmpfname, "w")
                fh.write(self.name + "\n")
                fh.write(self.raw_file + "\n")
                fh.write(self.start_time + "\n")
                fh.write(self.end_time + "\n")
                fh.write(str(self.compile) + "\n")
                for n in range(0, len(self.test_results)):
                   test_str = self.test_results[n].name + ";" + str(self.test_results[n].passFlag) + ";" + str(self.test_results[n].time)
                   fh.write (test_str + "\n")
                fh.close()
                os.rename(tmpfname, fname)

        def processDBLog(self):
                try:
                   fh=open(self.db_file, "r")
                except IOError:
                   print "ERROR: Cannot open db file", self.db_file
                   return

                self.name = trim(fh.readline())
                self.raw_file = trim(fh.readline())
                self.start_time = trim(fh.readline())
                self.end_time = trim(fh.readline())
                self.compile = string.atoi(trim(fh.readline()))
                #print "processDBLog ", self.db_file, self.name, self.raw_file, self.start_time, self.end_time, self.compile
                line = trim(fh.readline())
                parse_error = 0
                while line != "":
                   splits = line.split(";")
                   if len(splits) != 3 or splits[0] == "":
                        parse_error = 1
                        break
                   name = splits[0]
                   passflag = string.atoi(splits[1])
                   time = string.atof(trim(splits[2]))
                   #print "test_result: ", line
                   self.test_results.append(ACE_TAO_Test (name, 0, time, passflag))
                   line = trim(fh.readline())
                   if (parse_error == 1 or self.name == "" or self.raw_file == "" or self.start_time == "" or self.end_time == "" or len(self.test_results) == 0):
                       print "ERROR: invalid db file: ", self.db_file
                       return

                fh.close()

	def addtest (self, name, result, time, flag):
		self.test_results.append(ACE_TAO_Test (name, result, time, flag))

	def testTime (self, name, time):
		if time > self.testMax:
			# Don't count the ACE test as the maximum time test
			if name != "tests/run_test.pl":
				self.testMax = time
		if time < self.testMin:
			self.testMin = time
		self.timeTotal = self.timeTotal + time

	def checkTestTime (self, line):
		tokens = line.split()
		result = 0
		time = 0.0

		# this strips off the "auto_run_tests:, and the time and status
		# leaves the test name plus any arguments
		splits = line.split()
		testname = ""
		for n in range (1, len(splits)-2):
			testname = testname + " " + splits[n]
		if len(tokens) > 2:
			ttime=tokens[2]
			if len(tokens) < 3:
				ttime = "" 
				tresult = "" 
			else:
				ttime = tokens[len(tokens)-2]
				tresult = tokens[len(tokens)-1]
			if ttime != "":
				e,f=ttime.split(":")
				time=int(f.replace('s',''))
				self.testTime (testname, time)

			if tresult != "":
				f,h=tresult.split(":")
				result=h
		return testname, result, time

	def sortByTime (self):
		# Sort test result by test time
		self.test_results.sort (lambda x, y: cmp (x.time, y.time))
		self.test_results.reverse()

	def printResults (self):
		print "\n********************"
		print "Results for build: ", self.name
		print "ACE:"
		print "\tTotal tests run = ", self.ACEtotal
		print "\tTests failed = ", self.ACEfail
		perc = 0.0
		try:
			perc = (float(self.ACEfail)/float(self.ACEtotal))*100.0
		except ZeroDivisionError:
			print "divide by zero attempt"
		print "\tPercentage: %.1f" % perc 
		print "TAO:"
		print "\tTotal tests run = ", self.TAOtotal
		print "\tTests failed = ", self.TAOfail
		try:
			perc = (float(self.TAOfail)/float(self.TAOtotal))*100.0
		except ZeroDivisionError:
			print "divide by zero attempt"
		print "\tPercentage: %.1f" % perc 
		if self.testMin != 4000.0:
			print "Tests:"
			print "\tmin Test = %.1f min" %  (float(self.testMin)/60.0)
			print "\tmax Test = %.1f min" %  (float(self.testMax)/60.0)
			print "\tTotal Test = %.1f min" %  (float(self.timeTotal)/60.0)

	def ACEorTAOTest (self, testname):
		splits = testname.split("/")
		if splits[0] == "TAO":
			testType = TAO_TEST
		else:
			testType = ACE_TEST
		return testType

	def scanForTestFailure (self, fh, stop_strings):
		line = fh.readline()
		fail = 0
		time = 0.0
		testname = ""
		stop = findString (line, stop_strings)
		while line != "" and stop == 1:
			if test_error.search(line):
				fail = 1
			if test_finished.match(line):
				testname, resultCode, time = self.checkTestTime(line)
			line = fh.readline()
			stop = findString (line, stop_strings)
      		        if build_end.match(line):
                           m = line.find('[')
                           n = line.find('UTC')
                           self.end_time = line[m+1:n]
                           break
                return line, fail, time, testname

	def processLog (self):
		try:
			file = open(self.raw_file, "r")
		except IOError:
			print "ERROR: Cannot open file", self.raw_file
			return
		state = 0
		line = file.readline()
                if line == "":
                        print "ERROR: file is empty:", self.raw_file
                        return

		time = 0.0
		# scan thru the file, state=0 while in pre-test stuff and state=1 while in tests 
		while line != "":
			readline = 0
                        if build_begin.match(line):
                           m = line.find('[')
                           n = line.find('UTC')
                           self.start_time = line[m+1:n]
                           line = file.readline()
                           continue
                        if build_end.match(line):
                           m = line.find('[')
                           n = line.find('UTC')
                           self.end_time = line[m+1:n]
                           break
			if test_start.match(line): 
				if (state < 1):
					# we found where tests are starting
					state=state+1
			if state==0:
				# this matches only lines that begin with "Error" or "ERROR" 
				if compile_error.match(line) and self.compile == PASS:
					self.compile = FAIL
			if state==1 and test_start.match(line):
		   		testname = (line.split())[1] 
				stop_strings = ["auto_run_tests:"]
				test_type = self.ACEorTAOTest (testname)
				line, fail, time, testname = self.scanForTestFailure (file, stop_strings)
				self.addtest (testname, 0, time, fail)
				if test_type == TAO_TEST:
					self.TAOtotal = self.TAOtotal + 1
					if fail==1:
						self.TAOfail = self.TAOfail + 1
				elif test_type == ACE_TEST:
					self.ACEtotal = self.ACEtotal + 1
					if fail==1:
						self.ACEfail = self.ACEfail + 1
				readline = 1
			if readline == 0:
				line = file.readline()
		file.close()
