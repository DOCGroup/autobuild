#!/usr/bin/python2.1

import sys
from CompilationDB import *
print sys.argv[1]
compilationdb = CompilationDB(sys.argv[1])
compilationdb.GetRecentBuildInstance()
