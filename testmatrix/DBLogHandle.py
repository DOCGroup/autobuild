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
       dbfile = removeNewLine(dbfile)
       if dbfile != "":
          build = Platform("", "", dbfile)
          if build.db_parse_error == 0:  
             builds.append (build)
    fh.close()
    return builds


