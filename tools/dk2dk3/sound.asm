REG_2A03_A_PORT1:   equ $7c00
REG_2A03_A_PORT2:   equ $7c80
REG_2A03_B_PORT:    equ $7d00
REG_2A03_RESET:     equ $7d80


; Init 2A03. Some code taken from DK3
forg ???
org ???, ???
        ld      b, 0
        ld      a, 1
        ld      (REG_2A03_RESET), a
.wait1:
        dec     b
        jr      nz, .wait1
        xor     a
        ld      (REG_2A03_RESET), a
        ; b is already 0
.wait2:
        dec     b
        jr      nz, .wait2
        ld      a, 1
        ld      (REG_2A03_RESET), a

        ; Clear sound registers
        xor     a
        ld      (REG_2A03_A_PORT1), a
        ld      (REG_2A03_A_PORT2), a
        ld      (REG_2A03_B_PORT), a

        ret
