#!/usr/bin/python2.1

import sys
import MySQLdb
import _mysql_exceptions
import mx.DateTime.Parser as Parser
from DBConnection import *
from utils import *
from CompilationPlatform import *


def SaveCompilationResults2DB (builds, dbname):
    db = CompilationDB(dbname)
    try:
      db.FillTables(builds)
    except:
      print "ERROR: failed to insert compilation results to database", dbname, sys.exc_type, sys.exc_value
      sys.exit(-1)
 
class CompilationDB:
        def __init__ (self, dbname):
		self.project_ids = {}
		self.build_ids = {}
		self.build_instance_ids = {}
	        self.connection = DBConnection(dbname)
                self.curs = self.connection.curs

        def FillTables (self, builds):
                builds_no_dup = []
                for m in range(0, len(builds)):
                   dbfile_load_status, build_instance_id = self.BuildLogLoaded(builds
[m].name, builds[m].raw_file)
                   if dbfile_load_status == 1:
                      print "********* Already saved compilation results", builds[m].name, builds[m].raw_file
                      continue
                   else:
                      print "********* Save compilation results", builds[m].name, builds[m].raw_file
                      self.AddBuild(builds[m])
                      self.AddBuildInstance(builds[m], dbfile_load_status, build_instance_id)
                      if m == 0:
                         self.AddProjects(builds[m])
                      self.AddCompilationInstance(builds[m])

        def AddBuild (self, build):
	        name = build.name
	        build_id = self.GetBuildId(name)
                #print "GetBuildId", name, build_id
                if build_id != 0:
                    self.build_ids[name] = build_id
                else:
		    if BuildConfig.config.has_key(name) == 0:
                        query = "INSERT INTO build VALUES (NULL, '%s', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);" % (name)
                    else:
                        config = BuildConfig.config[name]
                        query = "INSERT INTO build VALUES (NULL, '%s', '%s', '%s', %d, '%s', %d, %d, %d, %d);" %(name, config[0], config[1], config[2], config[3], config[4], config[5], config[6], config[7])
                    #print "AddBuild ", query
                    self.curs.execute(query)
                    self.build_ids[name] = self.curs.insert_id() 
                    #print "AddBuild: insert ", self.curs.insert_id()

        def AddBuildInstance (self, build, dbfile_load_status, build_instance_id
):
                   if self.build_ids.has_key(build.name) == 0:
                      self.AddBuild(build.name)
                   if dbfile_load_status == -1:
                      query = "INSERT INTO build_instance VALUES (NULL, %d, '%s', '%s', NULL, '%s', NULL, NOW());" % (self.build_ids[build.name], str(Parser.DateTimeFromString(build.start_time)), str(Parser.DateTimeFromString(build.end_time)), build.raw_file)
                      self.curs.execute(query)
                      self.build_instance_ids[build.name] = self.curs.insert_id()
                   else:
                      query = "UPDATE build_instance SET compilation_insert_time=NOW() where build_instance_id=%d;" % (build_instance_id)
                      self.curs.execute(query)
                      self.build_instance_ids[build.name] = build_instance_id
                   #print "AddBuildInstance ", query

        def AddProjects(self, build):    
                for m in range (0, len(build.compilation_results)):
                   name = build.compilation_results[m].name; 
                   self.AddProject(name)

        def AddProject(self, name):
	        project_id = self.GetProjectId(name)
		if project_id == 0:
	           query = "INSERT INTO project VALUES (NULL, '%s');" % (name)
                   self.curs.execute(query)
		   #print "AddProject", query 
		   self.project_ids[name] = self.curs.insert_id()
		   #print "AddProject: insert ", self.curs.insert_id()
		else:
		   self.project_ids[name] = project_id

        def AddCompilationInstance(self, build):      
	        for n in range (0, len(build.compilation_results)):
		   if self.project_ids.has_key(build.compilation_results[n].name) == 0:
		       self.AddProject(build.compilation_results[n].name)
                   if build.compilation_results[n].skipped == 1:
                       query = "INSERT INTO compilation_instance VALUES(%d, %d, 1, NULL, NULL);" % (self.project_ids[build.compilation_results[n].name], self.build_instance_ids[build.name])
                   else:
                       query = "INSERT INTO compilation_instance VALUES(%d, %d, 0, %d, %d);" % (self.project_ids[build.compilation_results[n].name], self.build_instance_ids[build.name], build.compilation_results[n].num_errors, build.compilation_results[n].num_warnings)
                   #print "AddCompilationInstance ", query         
                   try:
		       self.curs.execute(query)
                   except _mysql_exceptions.IntegrityError:
		       print "AddCompilationInstance failed: ", build.compilation_results[n].name, build.raw_file, sys.exc_type, sys.exc_value
		       
	def BuildLogLoaded(self, build_name, log_fname):
                dbfile_load_status = -1
                build_instance_id = -1
                query = "SELECT build_instance_id, compilation_insert_time FROM build_instance WHERE log_fname='%s';" % (log_fname)
                result = self.curs.execute(query)
                if result != 0:
                     build_instance_id = self.curs.fetchall()[0][0]
                     insert_time = str(self.curs.fetchall()[0][1]) 
		     dbfile_load_status = (insert_time != "None")
	        #print  "BuildLogLoaded ", query, "build_instance_id=", build_instance_id, "compilation_loaded=", dbfile_load_status 
                return dbfile_load_status, build_instance_id

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
 
                   
        def GetProjectId(self, project_name):
                project_id = 0
                query = "SELECT project_id FROM project WHERE project_name='%s';" % (project_name)
                #print "GetProjectId", query
                ret = self.curs.execute(query)
                if ret == 1:
                   project_id = self.curs.fetchall()[0][0]
                   #print "GetTestId: ", project_id 
                elif ret > 1:
                   print "ERROR: duplicate entry for project", project_name
                return project_id

        def GetRecentBuildInstance(self):
	        query = "SELECT log_fname FROM  build_instance WHERE compilation_insert_time IS NOT NULL and NOW() < compilation_insert_time + INTERVAL 4 DAY;";
	        ret = self.curs.execute(query)
	        if ret > 0:
	          results = self.curs.fetchall()
	          for m in range(0, len(results)): 
                    print txt2DbFname(results[m][0])
    
