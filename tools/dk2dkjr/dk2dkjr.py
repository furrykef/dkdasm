#!/usr/bin/env python
# Convert a Donkey Kong romset to run on Donkey Kong Junior
# This only rearranges the ROM data and renames ROMs so MAME can load it as a dkongjr set.
# It doesn't modify any actual code or data (unless PATCH is True).
# Written for Python 3.4
import os.path
import sys
import zipfile


# @TODO@ -- make this a command-line flag
PATCH = False


def main(argv=None):
    myname = os.path.basename(sys.argv[0])
    if argv is None:
        argv = sys.argv[1:]

    try:
        infilename, outfilename = argv
    except ValueError:
        print("Usage: {0} dkong.zip output.zip".format(myname), file=sys.stderr)

    with zipfile.ZipFile(infilename, 'r') as inzip:
        prg = inzip.read('c_5et_g.bin')
        prg += inzip.read('c_5ct_g.bin')
        prg += inzip.read('c_5bt_g.bin')
        prg += inzip.read('c_5at_g.bin')
        prg += b'\0'*0x2000
        chr1 = inzip.read('v_5h_b.bin')
        chr1 += b'\0'*0x800
        chr2 = inzip.read('v_3pt.bin')
        chr2 += b'\0'*0x800
        spr1 = inzip.read('l_4m_b.bin')
        spr2 = inzip.read('l_4n_b.bin')
        spr3 = inzip.read('l_4r_b.bin')
        spr4 = inzip.read('l_4s_b.bin')
        prom1 = inzip.read('c-2k.bpr')
        prom2 = inzip.read('c-2j.bpr')
        prom3 = inzip.read('v-5e.bpr')
        snd = inzip.read('s_3i_b.bin')
        snd += inzip.read('s_3j_b.bin')

    if PATCH:
        # NOP out the instruction that inverts bits from the 0x20 data port in sound ROM.
        # Otherwise the game will play the wrong sound cues.
        snd[0x539] = b'\x00'

    with zipfile.ZipFile(outfilename, 'w') as outzip:
        write_prg_rom(outzip, prg)
        outzip.writestr('djr1-v.3n', chr1)
        outzip.writestr('djr1-v.3p', chr2)
        outzip.writestr('djr1-v_7c.7c', spr1)
        outzip.writestr('djr1-v_7d.7d', spr2)
        outzip.writestr('djr1-v_7e.7e', spr3)
        outzip.writestr('djr1-v_7f.7f', spr4)
        outzip.writestr('djr1-c-2e.2e', prom1)
        outzip.writestr('djr1-c-2f.2f', prom2)
        outzip.writestr('djr1-v-2n.2n', prom3)
        outzip.writestr('djr1-c_3h.3h', snd)


def write_prg_rom(outzip, prg):
    outzip.writestr('djr1-c_5b_f-2.5b', prg[0x0000:0x1000] + prg[0x3000:0x4000])
    outzip.writestr('djr1-c_5c_f-2.5c', prg[0x2000:0x2800] + prg[0x4800:0x5000] + prg[0x1000:0x1800] + prg[0x5800:0x6000])
    outzip.writestr('djr1-c_5e_f-2.5e', prg[0x4000:0x4800] + prg[0x2800:0x3000] + prg[0x5000:0x5800] + prg[0x1800:0x2000])


if __name__ == '__main__':
    sys.exit(main())
