#!/usr/bin/python

from CompilationPlatform import *
from utils import *


def ReadCompilationDBFiles(lsfile):
    fh = open(lsfile, "r")
    builds = []
    for dbfile in fh.readlines():
        file = trim(dbfile)
        if file != "":
	   build = CompilationPlatform(file)
	   if build.valid_db_file == 1:
              builds.append (build)
    fh.close()
    return builds




