#!/usr/bin/python

# Configuration information for the database accessing.
class DBConfig:
          hostname = ""
	  dbname   = ""
	  username  = ""
	  password  = ""

# Configuration of the *.db files.
class DBFileConfig:
	  # Output directory for the *.db files. 
	  dbdir_w = "/export/web/www/scoreboard/test_matrix_db"

# Configuration of the compilation db files.
class CompilationDBFileConfig:
          # Output directory for the *.db files.
          dbdir_w = "/export/web/www/scoreboard/compilation_matrix_db"

# Edit your build system configuration here. 
# The format of the configuration:
#  'build_name':['hostname', 'os_type', 'is_64bit', 'compiler_type', 'is_debug',
#                'is_optimized', 'is_static', 'is_minimum_corba']
# Note the 'is_64bit', 'is_debug', 'is_optimized', 'is_static' and 'is_minimum_corba'
# are flags, the values are 0 or 1.

class BuildConfig:
          config =  {'Redhat_Enterprise_Linux_3_Debug': ['jane', 'RH_Enterprise_ES', 0, 'g++3.2.3', 1, 0, 0, 0], 
		     'Redhat_Enterprise_Linux_3_Static_Release': ['jane', 'RH_Enterprise_ES', 0, 'g++3.2.3', 0, 0, 1, 0]}
