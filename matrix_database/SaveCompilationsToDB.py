#!/usr/bin/env python3

import sys
from CompilationDB import *
from CompilationDBFileHandle import *

if __name__ == '__main__':
    lsfile = sys.argv[1]
    dbname = sys.argv[2]
    builds = ReadCompilationDBFiles(lsfile)
    SaveCompilationResults2DB(builds, dbname)
