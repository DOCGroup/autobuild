#!/usr/bin/env python3

from TestDB import *

if __name__ == '__main__':
    testdb = TestDB(sys.argv[1])
    testdb.GetRecentBuildInstance()
