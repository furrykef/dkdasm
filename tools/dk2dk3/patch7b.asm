; @TODO@ -- implement REG_FLIPSCREEN

IN0:                equ $7c00
IN1:                equ $7c80

; Patch dk3c.7b from a converted DK ROM to run on DK3 hardware
; Written for tniASM 0.45
REG_FLIPSCREEN:     equ $7e82
REG_SPRITE:         equ $7e83
REG_VBLANK_ENABLE:  equ $7e84
REG_DMA:            equ $7e85

incbin "roms/dkong3/dk3c.7b"

forg $0002
org $0002
        ld      (REG_VBLANK_ENABLE), a

forg $006f
org $006f
        ld      (REG_VBLANK_ENABLE), a

; skip check for reboot if bit 6 of IN0/IN1 set
forg $00b0
org $00b0
        jp      $00b5

forg $00db
org $00db
        ld      (REG_VBLANK_ENABLE), a

; dkong3 uses different input for detecting coins
; @TODO@ -- handle both coin switches
forg $17b
org $17b, $17f
        ld      a, (IN1)
        bit     5, a

forg $02a5
org $02a5
        ld      (REG_SPRITE), a

forg $02ba
org $02ba
        ld      (REG_VBLANK_ENABLE), a

; different bits used to detect start buttons
forg $08d5
org $08d5
        ld      b, $20

forg $08e1
org $08e1
        ld      b, $60

; Use IN0, not IN2, for start buttons
forg $08f3
org $08f3
        ld      a, (IN0)

; Player 1 button pressed?
forg $08fb
org $08fb
        cp      $20

; Player 2 button pressed?
forg $0900
org $0900
        cp      $40


; DMA routine for sprites.
; Main body and data table copied from dkong3.
forg $141
org $141, $17a
        xor     a
        ld      (REG_DMA), a
        ld      hl, DmaTbl
        ld      bc, $0d00
        otir
        ld      a, 1
        ld      (REG_DMA), a
        xor     a
        ld      (REG_DMA), a
        ret

DmaTbl:
        db      $7d, $00, $69, $9f, $01, $14, $10, $ad, $00, $70, $8a, $cf, $87
