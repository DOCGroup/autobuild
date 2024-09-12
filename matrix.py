#!/usr/bin/env python3

import sys
import argparse
import json
from pathlib import Path
import enum

from testmatrix.HTMLScoreboard import write_html_matrix
from testmatrix.matrix import Builds, Matrix


if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser(
        description='Generate a test status matrix from autobuild output')
    arg_parser.add_argument('builds_dir', type=Path,
        help='Directory with autobuild/scoreboard build contents')
    arg_parser.add_argument('prefix')
    args = arg_parser.parse_args()

    builds = Builds(args.builds_dir)
    matrix = Matrix(builds)
    matrix.dump()

    write_html_matrix(matrix, args.prefix)
