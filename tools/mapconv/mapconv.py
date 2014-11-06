#!/usr/bin/env python
# Convert a TMX file into a file usable by our custom loader
# @TODO@ -- consider LZF or LZJB format
# A good LZF compressor and decompressor is here: https://code.google.com/p/lzfx/source/browse/trunk/lzfx.c
# Written for Python 3.4
import argparse
import sys
import xml.etree.ElementTree


USE_RLE = True
USE_ZLIB = False


BLANK_TILE = 0x10


FLAG_HFLIP = 1 << 0
FLAG_VFLIP = 1 << 1


class TmxError(Exception):
    pass


class Sprite(object):
    def __init__(self, graphic, palette, x, y, hflip, vflip):
        self.graphic = graphic
        self.palette = palette
        self.x = x
        self.y = y
        self.hflip = hflip
        self.vflip = vflip


def main(argv=None):
    myname = os.path.basename(sys.argv[0])
    if argv is None:
        argv = sys.argv[1:]

    parser = argparse.ArgumentParser(description="Convert a TMX file for use with custom DK level loader")
    parser.add_argument('tmxfile')
    parser.add_argument('outfile')
    args = parser.parse_args(argv)

    try:
        tmx_root = xml.etree.ElementTree.parse(args.tmxfile).getroot()
    except OSError as e:
        print(e, file=sys.stderr)
        return 1

    try:
        tilemap, sprite_list = processTmx(tmx_root)
    except TmxError as e:
        print(e, file=sys.stderr)
        return 1

    if USE_ZLIB:
        import zlib
        tilemap = zlib.compress(tilemap, 9)
    elif USE_RLE:
        tilemap = encodeRle(tilemap)

    # Convert sprite data to byte array
    sprdata = bytearray()
    sprdata.append(len(sprite_list))
    for sprite in sprite_list:
        flags = 0
        if sprite.hflip:
            flags |= FLAG_HFLIP
        if sprite.vflip:
            flags |= FLAG_VFLIP
        sprdata.append(sprite.graphic)
        sprdata.append(sprite.palette)
        sprdata.append(sprite.x)
        sprdata.append(sprite.y)
        sprdata.append(flags)

    with open(args.outfile, "wb") as outfile:
        outfile.write(tilemap)
        outfile.write(sprdata)


def processTmx(root):
    tiles_first_gid = int(root.find(".//tileset[@name='tiles']").get('firstgid'))
    sprites_first_gid = int(root.find(".//tileset[@name='sprites']").get('firstgid'))
    tilemap = getTilemap(tiles_first_gid, root)
    sprite_list = getSpriteList(sprites_first_gid, root)
    return tilemap, sprite_list


def getTilemap(tiles_first_gid, root):
    # The TMXes use 28x32 tilemaps, oriented vertically.
    # These will be converted into 32x28 tilemaps, oriented horizontally.
    # This means we're rotating the map 90 degees left.
    tile_nodes = root.findall(".//tile")
    if len(tile_nodes) == 0:
        raise TmxError("Tile nodes not found. Did you remember to set tile layer format to XML?")
    if len(tile_nodes) != 28*32:
        raise TmxError("There must be exactly one 28x32 tile map.")
    tilemap = bytearray(32*28)
    dst_row = 27
    dst_col = 0
    for tile in tile_nodes:
        id = int(tile.get('gid')) - tiles_first_gid
        if id < 0:
            id = BLANK_TILE
        tilemap[32*dst_row+dst_col] = id
        dst_row -= 1
        if dst_row < 0:
            dst_row = 27
            dst_col += 1
    return tilemap


def getSpriteList(sprites_first_gid, root):
    sprite_list = []
    for obj in root.findall(".//object"):
        raw_id = int(obj.get('gid'))
        graphic = (raw_id & 0x1fffffff) - sprites_first_gid
        palette = 0                                             # @TODO@
        x = int(obj.get('x')) & 0xff
        y = int(obj.get('y')) & 0xff
        hflip = raw_id & 0x8000000 != 0
        vflip = raw_id & 0x4000000 != 0
        sprite_list.append(Sprite(graphic, palette, x, y, hflip, vflip))
    return sprite_list


# RLE is encoded thus: if a byte appears twice in the encoded stream, it is
# followed by a repeat count. E.g., 69 69 03 decodes to 69 69 69 69 69, and
# 69 69 00 decodes to just 69 69.
def encodeRle(data):
    outdata = bytearray()
    prev_byte = None
    for byte in data:
        if byte == prev_byte:
            if repeat_count < 0:
                outdata.append(byte)
                outdata.append(0)                   # initial repeat count byte
            elif repeat_count == 255:
                outdata.append(byte)
                repeat_count = -2                   # will be incremented to -1 afterward
            else:
                # update repeat count byte
                outdata[-1] += 1
            repeat_count += 1
        else:
            outdata.append(byte)
            repeat_count = -1
        prev_byte = byte
    return outdata


if __name__ == '__main__':
    sys.exit(main())
