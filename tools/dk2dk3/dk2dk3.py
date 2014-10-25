# Convert a Donkey Kong romset to run on Donkey Kong 3
# This only rearranges the ROM data and renames ROMs so MAME can load it as a dkong3 set.
# It doesn't modify any actual code or data.
#
# Note that dkc1-v.5e is unchanged from DK3.
# There's no need to burn it if you're modifying a DK3 board.
#
# Written for Python 3.4
import os
import sys
import zipfile


def main(argv=None):
    myname = os.path.basename(sys.argv[0])
    if argv is None:
        argv = sys.argv[1:]

    try:
        infilename, outdir = argv
    except ValueError:
        print("Usage: {0} dkong.zip out-dir".format(myname), file=sys.stderr)
        return 1

    with zipfile.ZipFile(infilename, 'r') as inzip:
        prg1 = inzip.read('c_5et_g.bin')
        prg1 += inzip.read('c_5ct_g.bin')
        prg2 = inzip.read('c_5bt_g.bin')
        prg2 += inzip.read('c_5at_g.bin')
        prg3 = b'\0'*0x2000
        prg4 = b'\0'*0x2000
        chr1 = inzip.read('v_5h_b.bin') + b'\0'*0x800
        chr2 = inzip.read('v_3pt.bin') + b'\0'*0x800
        spr1 = inzip.read('l_4m_b.bin') + b'\0'*0x800
        spr2 = inzip.read('l_4n_b.bin') + b'\0'*0x800
        spr3 = inzip.read('l_4r_b.bin') + b'\0'*0x800 
        spr4 = inzip.read('l_4s_b.bin') + b'\0'*0x800
        prom1 = inzip.read('c-2k.bpr')
        prom2 = inzip.read('c-2j.bpr')
        prom3 = inzip.read('v-5e.bpr')
        snd1 = b'\0'*0x2000
        snd2 = b'\0'*0x2000
        adr = b'\xfd\xfd\xfd\xfd\xfb\xfb\xfb\xfb\xf7\xf7\xf7\xf7\xdf\xbf\xfe\xfe\xef\xef\xef\xef\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff'

    prom1, prom2 = conv_proms(prom1, prom2)

    # Create outdir if it does not exist
    # This is not recursive; it cannot create dirs that lead to it
    try:
        os.mkdir(outdir)
    except OSError:
        pass

    writefile(outdir +'/dk3c.7b', prg1)
    writefile(outdir +'/dk3c.7c', prg2)
    writefile(outdir +'/dk3c.7d', prg3)
    writefile(outdir +'/dk3c.7e', prg4)
    writefile(outdir +'/dk3v.3n', chr1)
    writefile(outdir +'/dk3v.3p', chr2)
    writefile(outdir +'/dk3v.7c', spr1)
    writefile(outdir +'/dk3v.7d', spr2)
    writefile(outdir +'/dk3v.7e', spr3)
    writefile(outdir +'/dk3v.7f', spr4)
    writefile(outdir +'/dkc1-c.1d', prom1)
    writefile(outdir +'/dkc1-c.1c', prom2)
    writefile(outdir +'/dkc1-v.2n', prom3)
    writefile(outdir +'/dk3c.5l', snd1)
    writefile(outdir +'/dk3c.6h', snd2)
    writefile(outdir +'/dkc1-v.5e', adr)


def writefile(filename, data):
    with open(filename, 'wb') as f:
        f.write(data)


def conv_proms(prom1_in, prom2_in):
    prom1_out = []
    prom2_out = []
    for nyb1, nyb2 in zip(prom1_in, prom2_in):
        byte = (nyb2 << 4) | nyb1

        # Get raw RGB values
        r = (byte & 0b11100000) >> 5
        g = (byte & 0b00011100) >> 2
        b = (byte & 0b00000011)

        # Convert to 4-bit values
        r = (r << 1) | 1
        g = (g << 1) | 1
        b = (b << 2) | 3

        # Convert to 12-bit color
        color = (r << 8) | (g << 4) | b

        # Convert to DK3 format
        prom1_out.append((color & 0xfff) >> 4)
        prom2_out.append(color & 0x0f)

    return bytes(prom1_out), bytes(prom2_out)

if __name__ == '__main__':
    sys.exit(main())
