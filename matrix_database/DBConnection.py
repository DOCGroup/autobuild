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
		  
        def CreateTables (self):
                query = "CREATE TABLE IF NOT EXISTS build(build_id SMALLINT NOT NULL AUTO_INCREMENT, build_name VARCHAR(50) NOT NULL, os VARCHAR(20), 64bit TINYINT, compiler VARCHAR(20), debug TINYINT, optimized TINYINT, static TINYINT, minimum TINYINT, PRIMARY KEY(build_id));"
                self.curs.execute(query)
                query = "CREATE TABLE IF NOT EXISTS build_instance(build_instance_id INT NOT NULL AUTO_INCREMENT, build_id SMALLINT NOT NULL, start_time DATETIME, end_time DATETIME, baseline VARCHAR(20), log_fname VARCHAR(200), insert_time DATETIME, test_logged TINYINT, compilation_logged TINYINT,  PRIMARY KEY(build_instance_id));"
                self.curs.execute(query)
                query = "CREATE TABLE IF NOT EXISTS test(test_id SMALLINT NOT NULL AUTO_INCREMENT, test_name VARCHAR(100) NOT NULL, PRIMARY KEY(test_id));" 
                self.curs.execute(query)
                query = "CREATE TABLE IF NOT EXISTS test_instance(test_id SMALLINT NOT NULL, build_instance_id INT NOT NULL, status VARCHAR(1), duration_time INT, PRIMARY KEY(test_id, build_instance_id));"
                self.curs.execute(query)
                query = "CREATE TABLE IF NOT EXISTS project(project_id SMALLINT NOT NULL AUTO_INCREMENT, project_name VARCHAR(100) NOT NULL, PRIMARY KEY(project_id));"
                self.curs.execute(query)
                query = "CREATE TABLE IF NOT EXISTS compilation_instance(project_id SMALLINT NOT NULL, build_instance_id INT NOT NULL, skipped TINYINT, num_errors INT, num_warnings INT, PRIMARY KEY(test_id, build_instance_id));"
                self.curs.execute(query) 
    
