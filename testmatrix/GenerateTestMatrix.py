#!/usr/bin/env python3

# ******************************************************************
#      Author: Heather Drury
#              Justin Michel
#        Date: 7/06/2004
# ******************************************************************

import sys
from pathlib import Path

matrix_database = str(Path(__file__).resolve().parent.parent / 'matrix_database')
if matrix_database not in sys.path:
    sys.path.append(matrix_database)

from HTMLScoreboard import *
from TestPlatform import *
from utils import *
from TestDBFileHandle import *


def ReadLogFiles():
    fh = open(infile, "r")
    builds = []
    # read in text files containing test results for each platform
    for line in fh.readlines():
        name, file = line.split()
        build = TestPlatform(name, file)
        if (build.valid_raw_file == 1):
            print("********* BUILD", name)
            builds.append(build)
        else:
            print("ERROR: invalid log file:", name, file)
    fh.close()
    return builds


def SaveBuildResults2HTML(directory, fname):
    # now print the results to an HTML file
    for n, build in enumerate(builds):
        build.HTMLtestResults = HTMLPlatformTestTable(build.name, directory)

        # print out the failed, then passed tests
        for pass_state in (FAIL, PASS):
            for test_result in build.test_results:
                if test_result.passFlag == FAIL:
                    build.HTMLtestResults.addData2(
                        n,
                        test_result.passFlag,
                        test_result.time,
                        test_result.name)

        build.HTMLtestResults.writeHTML()

# build up test matrix


def BuildTestMatrix(builds, directory, fname, filename):
    testMatrix = TestMatrix(len(builds))
    for n, build in enumerate(builds):
        for test_result in build.test_results:
            testMatrix.addTestResult(n, test_result.name, test_result.passFlag)

    # write out the HTML
    HTMLtestMatrix = HTMLTestMatrix2(fname, directory)
    for n, name in enumerate(testMatrix.testNames):
        HTMLtestMatrix.addTestData(
            name,
            testMatrix.testResults[n],
            testMatrix.fileNames[n],
            builds)

    totalPass = 0
    totalFail = 0
    totalSkip = 0
    for n, build in enumerate(builds):
        build.npass, build.nfail, build.nskip = testMatrix.getTestResults(n)
        totalPass += build.npass
        totalFail += build.nfail
        totalSkip += build.nskip
    HTMLtestMatrix.writeBriefs(totalPass, totalFail, totalSkip)

    for n, build in enumerate(builds):
        HTMLtestMatrix.writeBuildSummary(n, build)
    getSummaryResults(HTMLtestMatrix, builds, filename)
    HTMLtestMatrix.writeHTML()
    HTMLtestMatrix.writeHTMLsummary()
    return testMatrix

# Write one HTML file for each test with each row representing a platform


def WriteTestHTML(testMatrix, builds):
    # print out HTML file for each test with results for all platforms
    for b in builds:
        print("\tPlatform: ", b.name, b.ACEtotal, b.ACEfail, b.TAOtotal, b.TAOfail)
    for m, test_name in enumerate(testMatrix.testNames):
        html = HTMLTestFile(test_name + '.html')
        for n, build in enumerate(builds):
            html.addData2(testMatrix.testResults[m][n], build.name)
        html.writeHTML()


def getSummaryResults(HTMLtestMatrix, builds, fname):
    ACEtotal = 0
    TAOtotal = 0
    ACEfail = 0
    TAOfail = 0
    ACEpass = 0
    TAOpass = 0
    ACEperc = 0
    TAOperc = 0
    overall = 0
    skip = 0
    for b in builds:
        print("\tPlatform: ", b.name, b.ACEtotal, b.ACEfail, b.TAOtotal, b.TAOfail)
        ACEtotal += b.ACEtotal
        TAOtotal += b.TAOtotal
        ACEfail += b.ACEfail
        TAOfail += b.TAOfail
        skip += b.nskip
        ACEpass = ACEtotal - ACEfail
        TAOpass = TAOtotal - TAOfail
        ACEperc = ComputePercentage(ACEpass, ACEtotal)
        TAOperc = ComputePercentage(TAOpass, TAOtotal)
        overall = ComputePercentage((TAOpass + ACEpass), (TAOtotal + ACEtotal))
    print("ACE tests ****", ACEtotal, ACEfail, ACEperc)
    print("TAO tests ****", TAOtotal, TAOfail, TAOperc)
    file = "/tmp/matrix_output." + fname + ".txt"
    fh = open(file, "w")
    percent = '%\n'
    str = "# of ACE tests passed: %d\n" % (ACEtotal)
    fh.write(str)
    str = "# of ACE tests failed: %d\n" % (ACEfail)
    fh.write(str)
    str = "ACE percentage: %.2f" % ACEperc
    str = str + percent
    fh.write(str)
    fh.write("\n")

    str = "# of TAO tests passed: %d\n" % (TAOtotal)
    fh.write(str)
    str = "# of TAO tests failed: %d\n" % (TAOfail)
    fh.write(str)
    str = "TAO percentage: %.2f" % TAOperc
    str = str + percent
    fh.write(str)
    fh.write("\n")

    str = "# of tests passed: %d\n" % (TAOtotal + ACEtotal)
    fh.write(str)
    str = "# of tests failed: %d\n" % (TAOfail + ACEfail)
    fh.write(str)
    str = "# of tests skipped: %d\n" % (skip)
    fh.write(str)

    str = "Overall percentage: %.0f" % overall
    str = str + percent
    fh.write(str)
    fh.close()

    fname = outfile + ".TestMatrix"
    HTMLtestMatrix.writeSummary(
        ACEpass,
        ACEtotal,
        ACEperc,
        TAOpass,
        TAOtotal,
        TAOperc)


if __name__ == '__main__':
    option = int(sys.argv[1])
    if option > 2:
        sys.exit("ERROR: invalid option", option)
    infile = sys.argv[2]
    directory = sys.argv[3]
    outfile = sys.argv[4]
    fname = outfile + ".matrix"
    if len(sys.argv) > 5:
        database_name = sys.argv[5]

    builds = ReadLogFiles()
    testMatrix = BuildTestMatrix(builds, directory, fname, outfile)
    SaveBuildResults2HTML(directory, outfile)

    if option == 1:
        import TestDB
        TestDB.WriteTestDBFiles(builds)
    elif option == 2:
        import TestDB
        TestDB.SaveTestResults2DB(builds, database_name)

    # there is no standardization of how the test names are created for ACE, TAO, until there is,
    # we shouldn't do this HAD 2.11.04
    # WriteTestHTML (testMatrix, builds)
    print("Normal execution!")
