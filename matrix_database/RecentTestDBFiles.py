#!/usr/bin/python2.1

from TestDB import *

testdb = TestDB(sys.argv[1])
testdb.GetRecentBuildInstance()
