#!/usr/bin/python

from Platform import *
from utils import *


def WriteDBLogFiles(builds):
    for m in range(0, len(builds)):
       builds[m].writeDBLog()

def ReadDBLogFiles(lsfile):
    fh = open(lsfile, "r")
    builds = []
    for dbfile in fh.readlines():
        file = removeNewLine(dbfile)
        if file != "":
           build = Platform("", "", file)
           if build.valid_db_file == 1:
              builds.append (build)
    fh.close()
    return builds


