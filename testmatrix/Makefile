SCOREBOARD_CONFIG_DIR=/home/isisbuilds/autobuild/configs/scoreboard

all : ace-list tsprdsh

ace-list : $(SCOREBOARD_CONFIG_DIR)/ace.xml
	./test-list-extract $< > $@

ace_future-list : $(SCOREBOARD_CONFIG_DIR)/ace_future.xml
	./test-list-extract $< > $@

tao-list : $(SCOREBOARD_CONFIG_DIR)/tao.xml
	./test-list-extract $< > $@

tao_future-list : $(SCOREBOARD_CONFIG_DIR)/tao_future.xml
	./test-list-extract $< > $@

misc-list : $(SCOREBOARD_CONFIG_DIR)/misc.xml
	./test-list-extract $< > $@

tsprdsh : tsprdsh.o
