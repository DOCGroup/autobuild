#!/usr/bin/python2.1


import MySQLdb
import sys
from DBConnection import *


def CreateTables(db_name):
                curs = DBConnection(db_name).curs
                query = "CREATE TABLE IF NOT EXISTS build(build_id SMALLINT NOT NULL AUTO_INCREMENT, build_name VARCHAR(100) NOT NULL, os VARCHAR(20), 64bit TINYINT(1), compiler VARCHAR(20), debug TINYINT(1), optimized TINYINT(1), static TINYINT(1), minimum TINYINT(1), PRIMARY KEY(build_id));"
                curs.execute(query)
                query = "CREATE TABLE IF NOT EXISTS build_instance(build_instance_id INT NOT NULL AUTO_INCREMENT, build_id SMALLINT NOT NULL, start_time DATETIME, end_time DATETIME, baseline VARCHAR(20), log_fname VARCHAR(200), test_insert_time DATETIME, compilation_insert_time DATETIME, PRIMARY KEY(build_instance_id));"
                curs.execute(query)
                query = "CREATE TABLE IF NOT EXISTS test(test_id SMALLINT NOT NULL AUTO_INCREMENT, test_name VARCHAR(100) NOT NULL, PRIMARY KEY(test_id));"
                curs.execute(query) 
                query = "CREATE TABLE IF NOT EXISTS test_instance(test_id SMALLINT NOT NULL, build_instance_id INT NOT NULL, status VARCHAR(1), duration_time INT, PRIMARY KEY(test_id, build_instance_id));" 
                curs.execute(query)
                query = "CREATE TABLE IF NOT EXISTS project(project_id SMALLINT NOT NULL AUTO_INCREMENT, project_name VARCHAR(100) NOT NULL, PRIMARY KEY(project_id));"
                curs.execute(query) 
                query = "CREATE TABLE IF NOT EXISTS compilation_instance(project_id SMALLINT NOT NULL, build_instance_id INT NOT NULL, skipped TINYINT(1), num_errors INT, num_warnings INT, PRIMARY KEY(project_id, build_instance_id));"
                curs.execute(query) 
               

CreateTables(sys.argv[1])

