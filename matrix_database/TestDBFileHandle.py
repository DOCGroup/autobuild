#!/usr/bin/python

from TestPlatform import *
from utils import *


def WriteTestDBFiles(builds):
    for m in range(0, len(builds)):
        builds[m].writeDBLog()

def ReadTestDBFiles(lsfile):
    fh = open(lsfile, "r")
    builds = []
    for dbfile in fh.readlines():
        file = trim(dbfile)
        if file != "":
	   build = TestPlatform("", "", file)
	   if build.valid_db_file == 1:
              builds.append (build)
    fh.close()
    return builds




