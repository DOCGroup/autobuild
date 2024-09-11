#!/usr/bin/env python3

import sys
from TestDB import *
from TestDBFileHandle import *

if __name__ == '__main__':
    lsfile = sys.argv[1]
    dbname = sys.argv[2]
    builds = ReadTestDBFiles(lsfile)
    SaveTestResults2DB(builds, dbname)
