#!/bin/sh
#
# $Id$

set -e

# Basic Configuration.  Additional configuration in the ~/.lcovrc file.
LCOV_BIN_DIR=/usr/bin
LCOV=$LCOV_BIN_DIR/lcov
GENHTML=$LCOV_BIN_DIR/genhtml
GCOV=$LCOV_BIN_DIR/gcov

# Temporary coverage info file.
TMP_INFO=tmp.info

# Consolidate coverage info file.
COVERAGE_INFO=coverage.info

TMP_HTML_DIR=Coverage
FINAL_HTML_DIR=/proj/autobuilds/logs/codecoverage/LCOV

COVERAGE_BUILD_DIR=/isisbuilds/ACE_wrappers

cd $COVERAGE_BUILD_DIR

$LCOV --directory $d --capture --output-file $COVERAGE_INFO

# Generate code coverage results web pages.
$GENHTML --output-directory=$TMP_HTML_DIR --frames $COVERAGE_INFO --show-details

mkdir -p $FINAL_HTML_DIR
mv $TMP_HTML_DIR $FINAL_HTML_DIR
