#!/usr/bin/python2.1

import MySQLdb
import sys
from utils import *
from DBConfig import *

class DBConnection:
        def __init__ (self, dbname):
                if dbname != "":
                   DBConfig.dbname = dbname
		self.build_instance_ids = {}
	        self.curs = self.Connect()

	def Connect (self):
                try:
		   db = MySQLdb.connect(DBConfig.hostname, DBConfig.username, DBConfig.password, DBConfig.dbname);
                except:
                   print "ERROR: failed to connect to database", DBConfig.dbname, sys.exc_type, sys.exc_value
                   sys.exit(-1)
                curs = db.cursor();
                return curs
		  
    
