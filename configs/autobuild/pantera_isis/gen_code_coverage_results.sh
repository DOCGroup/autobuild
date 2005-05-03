#!/bin/sh
#
# $Id$

set -e

# Basic Configuration.  Additional configuration in the ~/.lcovrc file.
LCOV_BIN_DIR=$HOME/lcov-1.4/bin
LCOV=$LCOV_BIN_DIR/lcov
GENHTML=$LCOV_BIN_DIR/genhtml

# Temporary coverage info file.
TMP_INFO=tmp.info

# Consolidate coverage info file.
COVERAGE_INFO=coverage.info

TMP_HTML_DIR=Coverage
FINAL_HTML_DIR=/web/users/isisbuilds/Coverage

COVERAGE_BUILD_DIR=/build/bczar/Code_Coverage/ACE_wrappers

cd $COVERAGE_BUILD_DIR

covered_dirs=`find . -name "GNUmakefile.*" | sed -e 's,\./,,' -e 's,/GNUmakefile.*$,,' | uniq`

# Generate code coverage results/information.
for d in $covered_dirs; do
    $LCOV --directory $d --capture --output-file $TMP_INFO
    # We could feed genhtml a list of info files but this consolidated
    # info file approach saves us the hassle of keeping track of
    # individual info files. 
    cat $TMP_INFO >> $COVERAGE_INFO
done

# Generate code coverage results web pages.
$GENHTML --output-directory=Coverage --frames $COVERAGE_INFO

mv $TMP_HTML_DIR/* $FINAL_HTML_DIR
