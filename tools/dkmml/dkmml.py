#!/usr/bin/env python
# Written for Python 3.4
import sys
import zipfile

SNDROM_NAME = 's_3i_b.bin'

PATTERN_DATA_OFFSET = 0x300
PATTERN_DATA_MAX_SIZE = 0x1fe

PLAYLIST_A_OFFSET = 0x510
PLAYLIST_B_OFFSET = 0x520
PLAYLIST_SIZE = 0x10

BEGIN_COMMENT = ';'


class MMLError(Exception):
    def __init__(self, msg, lineno=None):
        self.msg = msg
        self.lineno = lineno

    def __str__(self):
        if self.lineno is not None:
            return "Line {0}: {1}".format(self.lineno, self.msg)
        else:
            return self.msg

# Used to read line by line and remember line number
class LineReader(object):
    def __init__(self, file):
        self.file = file
        self.lineno = 0

    def __next__(self):
        self.lineno += 1
        return next(self.file)


def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]

    parser = argparse.ArgumentParser(description="Insert music in MML format into a Donkey Kong ROM.")
    parser.add_argument('mmlname')
    parser.add_argument('inzipname')
    parser.add_argument('outzipname')
    args = parser.parse_args(argv)

    with open(args.mmlname, 'r') as mmlfile:
        try:
            data = read_mml(mmlfile)
        except MMLError as e:
            print(e, file=sys.stderr)
            return 1

    with zipfile.open(args.inzipname, 'r') as inzip:
        snd_rom = inzip.read(SNDROM_NAME)
        patch_rom(snd_rom, PATTERN_DATA_OFFSET, data)

    # Move routine at 0x4f8 to 0x4fe, giving six more bytes to pattern table
    patch_rom(snd_rom, 0x4fe, '\xA3\x83')

    # Patch call to the routine formerly known as 0x4f8
    snd_rom[0x637] = '\xfe'

    # Insert music data
    @XXX@

    with zipfile.open(args.outzipname, 'w') as outzip:
        outzip.writestr(SNDROM_NAME, data)


def read_mml(mmlfile):
    songlist = []
    playlist_a = []
    playlist_b = []
    pattern_names = {'end': 0}
    patterns = [['\0']]
    for line in mmlfile:
        line = preprocess_line(line)
        if len(line) == 0:
            continue
        line = line.split()
        cmd = line[0]
        if line[0] == 'songs':
            songlist = read_songlist(mmlfile)
        elif line[0] == 'playlist_a':
            if len(playlist_a) > 0:
                raise MMLError("Playlist A has already been defined")
            playlist_a = read_playlist(mmlfile)
        elif line[0] == 'playlist_b':
            # @TODO@ -- duplicate code
            if len(playlist_b) > 0:
                raise MMLError("Playlist B has already been defined")
            playlist_b = read_playlist(mmlfile)
        elif line[0] == 'pattern':
            try:
                name = line[1]
            except IndexError:
                raise MMLError("Patterns must have a name")
            if name in pattern_names:
                raise MMLError("Pattern '{0}' has already been defined".format(name))
            pattern_names[name] = len(patterns)
            patterns.append(read_pattern(mmlfile))
        else:
            raise MMLError("Invalid command: {0}".format(line[0]))

    @XXX@


def preprocess_line(line):
    # Remove comment first if present
    comment_pos = line.find(BEGIN_COMMENT)
    if comment_pos != -1:
        line = line[:comment_pos]
    return line.strip().lower()


def patch_rom(romfile, data, offset):
    romfile[offset:offset+len(data)] = data


if __name__ == '__main__':
    sys.exit(main())
