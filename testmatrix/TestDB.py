#!/usr/bin/python

import MySQLdb;
import mx.DateTime.Parser as Parser
from utils import *
from TestDBConfig import *
from Platform import *


def SaveBuildResults2DB (builds):
    builds_no_dup = []
    db = TestDB()
    for m in range(0, len(builds)):
      if db.BuildLogLoaded(builds[m].name, builds[m].raw_file) == 1:
         print "********* Already saved", builds[m].name, builds[m].raw_file
      else:
         print "********* Save build", builds[m].name
         builds_no_dup.append (builds[m])
    if len(builds_no_dup) > 0 :
      db.FillTable(builds_no_dup)
												       
class TestDB:
        def __init__ (self):
                self.table_created = 0
	        self.build_filled = 0
		self.test_filled = 0
		self.test_ids = {}
		self.build_ids = {}
		self.build_instance_ids = {}
		self.build_config = BuildConfig()
	        self.curs = self.Connect()
	
	def Connect (self):
		db = MySQLdb.connect(DBConfig.hostname, DBConfig.username, DBConfig.password, DBConfig.dbname);
                curs = db.cursor();
                return curs
		  
        def CreateTables (self):
		if self.table_created == 0:           
                   query = "CREATE TABLE IF NOT EXISTS build(build_id SMALLINT NOT NULL AUTO_INCREMENT, build_name VARCHAR(50) NOT NULL, os VARCHAR(20), 64bit TINYINT, compiler VARCHAR(20), debug TINYINT, optimized TINYINT, static TINYINT, minimum TINYINT, PRIMARY KEY(build_id));"
                   self.curs.execute(query)
                   query = "CREATE TABLE IF NOT EXISTS build_instance(build_instance_id INT NOT NULL AUTO_INCREMENT, build_id SMALLINT NOT NULL, start_time DATETIME, end_time DATETIME, insert_time DATETIME, baseline VARCHAR(20), log_fname VARCHAR(200), PRIMARY KEY(build_instance_id));"
                   self.curs.execute(query)
                   query = "CREATE TABLE IF NOT EXISTS test(test_id SMALLINT NOT NULL AUTO_INCREMENT, test_name VARCHAR(100) NOT NULL, PRIMARY KEY(test_id));" 
                   self.curs.execute(query)
                   query = "CREATE TABLE IF NOT EXISTS test_instance(test_id SMALLINT NOT NULL, build_instance_id INT NOT NULL, status VARCHAR(1), duration_time INT, PRIMARY KEY(test_id, build_instance_id));"
                   self.curs.execute(query)
                   self.table_created = 1
                else:
		   print "CreateTable: already created"

        def FillTable (self, builds):
	        if (self.build_filled == 0):
                   self.AddBuilds(builds)
                   self.build_filled = 1
                self.AddBuildInstances(builds)
                if (self.test_filled == 0):
                   self.AddTests(builds)
                   self.test_filled = 1
                self.AddTestInstances(builds)

        def AddBuilds (self, builds):
# Insert to table build
                for m in range (0, len(builds)):
		    self.AddBuild(builds[m].name)
		    
        def AddBuild (self, name):
	        build_id = self.GetBuildId(name)
                #print "GetBuildId", builds[m].name, build_id
                if build_id != 0:
                    self.build_ids[name] = build_id
                else:
		    if BuildConfig.config.has_key(name) == 0:
                        query = "INSERT INTO build VALUES (NULL, '%s', NULL, NULL, NULL, NULL, NULL, NULL, NULL);" % (name)
                    else:
                        config = BuildConfig.config[name]
                        query = "INSERT INTO build VALUES (NULL, '%s', '%s', %d, '%s', %d, %d, %d, %d);" %(name, config[0], config[1], config[2], config[3], config[4], config[5], config[6])
                    #print "AddBuild ", query
                    self.curs.execute(query)
                    self.build_ids[name] = self.curs.insert_id() 
                    #print "AddBuild: insert ", self.curs.insert_id()

        def AddBuildInstances (self, builds):
                for m in range (0, len(builds)):
		   if self.build_ids.has_key(builds[m].name) == 0:
		      self.AddBuild(builds[m].name)
                   query = "INSERT INTO build_instance VALUES (NULL, %d, '%s', '%s', NOW(), NULL, '%s');" % (self.build_ids[builds[m].name], str(Parser.DateTimeFromString(builds[m].start_time)), str(Parser.DateTimeFromString(builds[m].end_time)), builds[m].raw_file)
                   #print "AddBuildInstance ", query              
                   self.curs.execute(query)
                   self.build_instance_ids[builds[m].name] = self.curs.insert_id()             
	
        def AddTests(self, builds):    
                for m in range (0, len(builds[0].test_results)):
                   name = builds[0].test_results[m].name; 
                   self.AddTest(name)

        def AddTest(self, name):
	        test_id = self.GetTestId(name)
		if test_id == 0:
	           query = "INSERT INTO test VALUES (NULL, '%s');" % (name)
                   self.curs.execute(query)
		   #print "AddTest ", query 
	           query = "SELECT LAST_INSERT_ID()"
	           self.curs.execute(query)
		   self.test_ids[name] = self.curs.insert_id()
		   #print "AddTest: insert ", self.curs.insert_id()
		else:
		   self.test_ids[name] = test_id

        def AddTestInstances(self, builds):      
                for m in range (0, len(builds)):
                   for n in range (0, len(builds[m].test_results)):
                      if (builds[m].test_results[n].passFlag == PASS):
                         pass_flag = 'P'
                      elif (builds[m].test_results[n].passFlag == FAIL):
                         pass_flag = 'F'
                      else: 
                         pass_flag = 'S'    
		      if self.test_ids.has_key(builds[m].test_results[n].name) == 0:
		         self.AddTest(builds[m].test_results[n].name)
                      query = "INSERT INTO test_instance VALUES(%d, %d, '%s', '%s');" % (self.test_ids[builds[m].test_results[n].name], self.build_instance_ids[builds[m].name], pass_flag, builds[m].test_results[n].time)
                      #print "AddTestInstances ", query         
                      self.curs.execute(query)

        def BuildLogLoaded(self, build_name, log_fname):
		found = 0
                query = "SELECT * FROM build_instance WHERE log_fname='%s';" % (log_fname)
                result = self.curs.execute(query)
                if result != 0:
                      found = 1 
		#print  "BuildLogLoaded ", query, "found=", found 
                return found
                 
        def GetBuildId(self, build_name):
                build_id = 0
                query = "SELECT build_id FROM build WHERE build_name='%s';" % (build_name)
                #print "GetBuildId  ", query
                ret = self.curs.execute(query)
                if ret == 1:
                   build_id = self.curs.fetchall()[0][0]
                   #print "GetBuildId: ", build_id 
                elif ret > 1:
                   print "ERROR: duplicate entry for build ", build_name
                return build_id
 
                   
        def GetTestId(self, test_name):
                test_id = 0
                query = "SELECT test_id FROM test WHERE test_name='%s';" % (test_name)
                #print "GetTestId  ", query
                ret = self.curs.execute(query)
                if ret == 1:
                   test_id = self.curs.fetchall()[0][0]
                   #print "GetTestId: ", test_id 
                elif ret > 1:
                   print "ERROR: duplicate entry for test ", test_name
                return test_id

        def GetRecentBuildInstance(self):
	        query = "SELECT log_fname FROM  build_instance WHERE NOW() > insert_time - INTERVAL 4 DAY";
	        ret = self.curs.execute(query)
	        if ret > 0:
	          results = self.curs.fetchall()
	          for m in range(0, len(results)): 
                    print txt2DbFname(results[m][0])
    
