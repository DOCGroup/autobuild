#!/usr/bin/python2.1

import sys
from TestDB import *
from TestDBFileHandle import*

lsfile = sys.argv[1]
dbname = sys.argv[2]
builds = ReadTestDBFiles(lsfile)
SaveTestResults2DB (builds, dbname)
													  
