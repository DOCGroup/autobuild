#!/usr/bin/env python3

import MySQLdb
import sys
from DBConnection import *


def UpdateBuildTable(db_name):
    curs = DBConnection(db_name).curs
    for k in list(BuildConfig.config.keys()):
        query = "SELECT * from build where build_name='%s';" % k
        # print query
        result = curs.execute(query)
        if result != 0:
            v = BuildConfig.config[k]
            query = "UPDATE build set hostname='%s', os='%s', 64bit=%d, compiler='%s', debug=%d, optimized=%d, static=%d, minimum=%d where build_name='%s';" % (
                v[0], v[1], v[2], v[3], v[4], v[5], v[6], v[7], k)
            # print query
            curs.execute(query)


if __name__ == '__main__':
    UpdateBuildTable(sys.argv[1])
