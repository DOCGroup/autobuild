#!/usr/bin/python

import sys
from TestDB import *
from DBLogHandle import*

lsfile = sys.argv[1]
dbname = sys.argv[2]
builds =  ReadDBLogFiles(lsfile)
SaveBuildResults2DB (builds, dbname)
													  
