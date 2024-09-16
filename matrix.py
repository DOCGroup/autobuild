#!/usr/bin/env python3

import sys
import argparse
import json
from pathlib import Path
import enum

from testmatrix import Matrix, write_html_files


def opt_or_prop(matrix, args, name):
    opt = getattr(args, name)
    if opt is not None:
        return opt
    prop_name = f'matrix_{name}'
    if prop_name in matrix.props:
        return matrix.props[prop_name]
    sys.exit(f'Need to either pass --{name} VALUE or define <prop {prop_name}="VALUE"/> in the '
        'scoreboard XML file.')


if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser(
        description='Generates a test status matrix from autobuild output.')
    arg_parser.add_argument('builds_dir', type=Path,
        help='Directory with the autobuild/scoreboard build contents')
    arg_parser.add_argument('--title',
        help='Title of the main matrix HTML page. Overrides <prop matrix_title="VALUE"/> in the '
            'scoreboard XML files.')
    arg_parser.add_argument('--basename',
        help='Prefix of all created files. Overrides <prop matrix_basename="VALUE"/> in the '
            'scoreboard XML files.')
    arg_parser.add_argument('--dump-only', action='store_true',
        help='Don\'t create any files, only dump the matrix in the CLI.')
    args = arg_parser.parse_args()

    matrix = Matrix(args.builds_dir)
    matrix.dump()

    if not args.dump_only:
        write_html_files(matrix,
            opt_or_prop(matrix, args, 'title'),
            opt_or_prop(matrix, args, 'basename'))
