#!/usr/bin/python2.1

import sys
from CompilationDB import *
from CompilationDBFileHandle import *

lsfile = sys.argv[1]
dbname = sys.argv[2]
builds = ReadCompilationDBFiles(lsfile)
SaveCompilationResults2DB (builds, dbname)
													  
