#!/usr/bin/env python
# Based on the old graphics ripper for the defunct Kong DX emulator
# Written for Python 3.4
import sys
import zipfile

from PIL import Image


# Note: needs trailing slash
ROMSET = '../../roms/dkong.zip'


TILES_PER_ROW = 16
SPRITES_PER_ROW = 8


black = (0, 0, 0)
red = (0xff, 0, 0)
darkblue = (0, 0, 0xb4)
blue = (0, 0, 0xff)
babyblue = (0xa4, 0xa5, 0xff)
peach = (0xff, 0xc2, 0x62)
orange = (0xff, 0x79, 0)
lt_orange = (0xff, 0xc2, 0)
brown = (0xc5, 0, 0)
tan = (0xe6, 0xa5, 0x62)
purple = (0xff, 0x55, 0xb4)
cyan = (0x00, 0xff, 0xff)
white = (0xff, 0xff, 0xff)
transparent = (0, 0, 0, 0)

pal_grey = (black,
            (0x88, 0x88, 0x88),
            (0xcc, 0xcc, 0xcc),
             white)

pal_unknown = pal_grey

pal_girder = (black,
              (0xFF, 0x2c, 0x62),
              (0xa4, 0, 0),
              cyan)

pal_mario = (black, peach, red, blue)
pal_paultop = (black, white, orange, purple)
pal_pauline = (black, darkblue, white, purple)
pal_barrel = (black, blue, orange, peach)
pal_dktop = (black, brown, peach, white)
pal_dkbody = (black, brown, peach, orange)
pal_oilbarl = (black, white, cyan, blue)
pal_fire = (black, lt_orange, red, white)
pal_spring = (black, babyblue, cyan, red)
pal_elevbox = (black, lt_orange, red, black)
pal_dktile = (black, orange, peach, white)
pal_rivet = (black, blue, cyan, lt_orange)
pal_pie = (black, tan, lt_orange, blue)

tile_palettes = [
    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,
    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,
    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,
    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,
    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,
    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,
    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,
    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,
    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,
    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_unknown, pal_unknown, pal_unknown,
    pal_dktile,  pal_dktile,  pal_dktile,  pal_dktile,  pal_dktile,  pal_dktile,  pal_dktile,  pal_dktile,
    pal_dktile,  pal_dktile,  pal_dktile,  pal_dktile,  pal_dktile,  pal_dktile,  pal_dktile,  pal_dktile,
    pal_dktile,  pal_dktile,  pal_dktile,  pal_dktile,  pal_dktile,  pal_dktile,  pal_dktile,  pal_dktile,
    pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,
    pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,
    pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,
    pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,
    pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,
    pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,
    pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,
    pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,
    pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,
    pal_rivet,   pal_dktile,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_rivet,
    pal_rivet,   pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,
    pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,
    pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,
    pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,
    pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,
    pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,
    pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,
    pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,  pal_girder,
    pal_girder,  pal_girder,  pal_girder,  pal_grey,    pal_girder,  pal_girder,  pal_dktile,   pal_mario,
]

tile_files = [
    "v_5h_b.bin",
    "v_3pt.bin"
]

spr_palettes = [
    pal_mario,   pal_mario,   pal_mario,   pal_mario,   pal_mario,   pal_mario,   pal_mario,   pal_mario,
    pal_mario,   pal_mario,   pal_mario,   pal_mario,   pal_mario,   pal_mario,   pal_mario,   pal_mario,
    pal_paultop, pal_pauline, pal_pauline, pal_pauline, pal_pauline, pal_barrel,  pal_barrel,  pal_barrel,
    pal_barrel,  pal_oilbarl, pal_oilbarl, pal_oilbarl, pal_unknown, pal_unknown, pal_dktop,   pal_dktop,
    pal_dktop,   pal_dktop,   pal_dktop,   pal_dktop,   pal_dktop,   pal_dkbody,  pal_dkbody,  pal_dkbody,
    pal_dkbody,  pal_dkbody,  pal_dkbody,  pal_dkbody,  pal_dkbody,  pal_dkbody,  pal_dkbody,  pal_dkbody,
    pal_dktop,   pal_dkbody,  pal_dkbody,  pal_dkbody,  pal_dkbody,  pal_dkbody,  pal_dkbody,  pal_dkbody,
    pal_unknown, pal_elevbox, pal_elevbox, pal_spring,  pal_spring,  pal_fire,    pal_fire,    pal_unknown,
    pal_fire,    pal_fire,    pal_fire,    pal_fire,    pal_girder,  pal_elevbox, pal_grey,    pal_unknown,
    pal_unknown, pal_oilbarl, pal_unknown, pal_pie,     pal_pie,     pal_fire,    pal_fire,    pal_unknown,
    pal_spring,  pal_spring,  pal_spring,  pal_unknown, pal_unknown, pal_unknown, pal_unknown, pal_unknown,
    pal_unknown, pal_unknown, pal_unknown, pal_unknown, pal_unknown, pal_unknown, pal_unknown, pal_unknown,
    pal_oilbarl, pal_oilbarl, pal_oilbarl, pal_oilbarl, pal_unknown, pal_unknown, pal_unknown, pal_unknown,
    pal_unknown, pal_unknown, pal_unknown, pal_unknown, pal_unknown, pal_unknown, pal_unknown, pal_unknown,
    pal_unknown, pal_unknown, pal_oilbarl, pal_pauline, pal_pauline, pal_pauline, pal_pauline, pal_pauline,
    pal_mario,   pal_mario,   pal_mario,   pal_grey,    pal_grey,    pal_grey,    pal_grey,    pal_grey,
]

# Convert first color to transparent
spr_palettes = [(transparent,) + palette[1:] for palette in spr_palettes]

top_spr_files = [
    "l_4m_b.bin",
    "l_4r_b.bin",
]

bottom_spr_files = [
    "l_4n_b.bin",
    "l_4s_b.bin"
]


def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]

    ### TILES ###
    tiledata = decode(tile_files)

    # Convert paletted values to RGB values
    tiledata = [tile_palettes[pixel_num//64][color] for pixel_num, color in enumerate(tiledata)]

    num_rows = 256//TILES_PER_ROW
    num_cols = TILES_PER_ROW
    tile_img = Image.new("RGB", (num_cols*8, num_rows*8))
    for offset in range(0, len(tiledata), 64):
        tile_num = offset//64
        for y in range(8):
            for x in range(8):
                # Note that we're rotating each tile 90 degrees right as we do this
                # Hence putting pixels at (7-y, x) instead of (x, y)
                out_row = tile_num // TILES_PER_ROW
                out_col = tile_num % TILES_PER_ROW
                tile_img.putpixel((7-y + out_col*8, x + out_row*8), tiledata[offset+y*8+x])

    tile_img.save("tiles.png")


    ### SPRITES ###
    top_spr_data = decode(top_spr_files)
    bottom_spr_data = decode(bottom_spr_files)

    # Convert paletted values to RGB values
    top_spr_data = [spr_palettes[pixel_num//128][color] for pixel_num, color in enumerate(top_spr_data)]
    bottom_spr_data = [spr_palettes[pixel_num//128][color] for pixel_num, color in enumerate(bottom_spr_data)]

    num_rows = 128//SPRITES_PER_ROW
    num_cols = SPRITES_PER_ROW
    spr_img = Image.new("RGBA", (num_cols*16, num_rows*16))
    for offset in range(0, len(top_spr_data), 64):
        tile_num = offset//64

        # Hack to reverse horizontal order of tiles within sprites
        if tile_num % 2 == 0:
            tile_num += 1
        else:
            tile_num -= 1

        for y in range(8):
            for x in range(8):
                # Note that we're rotating each tile 90 degrees right as we do this
                # Hence putting pixels at (7-y, x) instead of (x, y)
                out_row = tile_num // (SPRITES_PER_ROW*2)
                out_col = tile_num % (SPRITES_PER_ROW*2)
                spr_img.putpixel((7-y + out_col*8, x + out_row*16), top_spr_data[offset+y*8+x])
                spr_img.putpixel((7-y + out_col*8, x+8 + out_row*16), bottom_spr_data[offset+y*8+x])

    spr_img.save("sprites.png")


def decode(file_list):
    outdata = [0] * 0x4000
    bitplane = 0
    with zipfile.ZipFile(ROMSET, 'r') as zf:
        for filename in file_list:
            indata = zf.read(filename)
            for offset, value in enumerate(indata):
                for bit in range(7, -1, -1):
                    outdata[offset*8 + bit] |= (value & 1) << bitplane
                    value >>= 1
            bitplane += 1
    return outdata


if __name__ == '__main__':
    main()
