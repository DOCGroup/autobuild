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
           builds.append (Platform("", "", dbfile))
    fh.close()
    return builds


