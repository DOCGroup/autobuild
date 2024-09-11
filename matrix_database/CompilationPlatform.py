import os
import sys
import string
import fileinput
import re
import math
import time
from utils import *


# represents one instance of one project
class ACE_TAO_Compilation:
    def __init__(self, name, skipped, num_errors, num_warnings):
        self.name = name
        self.skipped = skipped
        self.num_errors = num_errors
        self.num_warnings = num_warnings


class CompilationPlatform:
    def __init__(self, db_file):
        self.valid_db_file = 1
        self.db_file = db_file
        self.name = ""
        self.raw_file = ""
        self.compilation_results = []
        self.start_time = ""
        self.end_time = ""
        self.processDBFile()
        # print "platform ", self.name, self.raw_file, self.start_time,
        # self.end_time

    def processDBFile(self):
        try:
            fh = open(self.db_file, "r")
        except IOError:
            print("ERROR: Cannot open db file", self.db_file)
            return

        self.name = fh.readline().strip()
        self.raw_file = fh.readline().strip()
        self.start_time = fh.readline().strip()
        self.end_time = fh.readline().strip()
        # print "processDBFile ", self.db_file, self.name, self.raw_file,
        # self.start_time, self.end_time
        line = fh.readline().strip()
        parse_error = 0
        while line:
            splits = line.split(";")
            length = len(splits)
            skipped = 0
            num_errors = -1
            num_warnings = -1
            if splits[0] == "":
                parse_error = 1
                break
            name = splits[0]
            if length == 1:
                name = name.strip()
                skipped = 1
            elif length == 3:
                num_errors = int(splits[1])
                num_warnings = int(splits[2])
            else:
                parse_error = 1
            # print "compilation_result: ", line
            self.compilation_results.append(
                ACE_TAO_Compilation(
                    name, skipped, num_errors, num_warnings))
            line = fh.readline().strip()
        if (parse_error == 1 or self.name == "" or self.raw_file == "" or self.start_time ==
                "" or self.end_time == "" or len(self.compilation_results) == 0):
            print("ERROR: invalid db file: ", self.db_file)
            self.valid_db_file = 0

        fh.close()
