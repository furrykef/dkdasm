# Convert a Donkey Kong romset to run on Donkey Kong 3
# This only rearranges the ROM data and renames ROMs so MAME can load it as a dkong3 set.
# It doesn't modify any actual code or data.
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
        prom1 += prom1
        prom2 = inzip.read('c-2j.bpr')
        prom2 += prom2
        prom3 = inzip.read('v-5e.bpr')
        snd1 = b'\0'*0x2000
        snd2 = b'\0'*0x2000
        adr = b'\0'*0x20

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


if __name__ == '__main__':
    sys.exit(main())
