#!/usr/bin/python2.1

import sys
from CompilationDB import *
compilationdb = CompilationDB(sys.argv[1])
compilationdb.GetRecentBuildInstance()
