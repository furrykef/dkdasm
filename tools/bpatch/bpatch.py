#!/usr/bin/env python
# Utility for producing and applying binary patches.
# Written for Python 3.4
import argparse
import sys


def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]

    parser = argparse.ArgumentParser(
        description="Copy part or all of a file and insert it into "
                    "another file."
    )
    parser.add_argument('src')
    parser.add_argument('dest')
    parser.add_argument('-s', '--src-offset', default=0)
    parser.add_argument('-d', '--dest-offset')
    parser.add_argument('-l', '--len', '--size', default=-1)
    args = parser.parse_args(argv)

    truncate = args.dest_offset is None
    if truncate:
        args.dest_offset = 0
        out_mode = 'wb'
    else:
        out_mode = 'r+b'

    with open(args.src, 'rb') as infile:
        infile.seek(args.src_offset)
        data = infile.read(args.len)

    with open(args.dest, out_mode) as outfile:
        outfile.seek(args.dest_offset)
        outfile.write(data)


if __name__ == '__main__':
    sys.exit(main())
