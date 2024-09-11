#!/usr/bin/env python3

import sys
from CompilationDB import *

if __name__ == '__main__':
    compilationdb = CompilationDB(sys.argv[1])
    compilationdb.GetRecentBuildInstance()
