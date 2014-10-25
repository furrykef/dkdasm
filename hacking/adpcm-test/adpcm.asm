.segment "HDR"

.segment "HEADER"
;
.byte 'N', 'E', 'S', 'M', $1A               ; ID
.byte $01                                   ; Version
.byte 1                                     ; Number of songs
.byte 1                                     ; Start song
.word $e000
.word INIT
.word PLAY
.byte "ADPCM demo                     ", 0  ; Name, 32 bytes
.byte "Kef Schecter                   ", 0  ; Artist, 32 bytes
.byte "                               ", 0  ; Copyright, 32 bytes
.word $411A                                 ; NTSC speed
.byte 0, 0, 0, 0, 0, 0, 0, 0                ; Bank values
.word $4E20                                 ; PAL speed
.byte 2                                     ; Flags, dual PAL/NTSC
.byte 0
.byte 0,0,0,0                               ; Reserved


.segment "ZP"

SampleAddr:
SampleAddrLSB:      .res 1
SampleAddrMSB:      .res 1

SampleBytesLeft:
SampleBytesLeftLSB: .res 1
SampleBytesLeftMSB: .res 1

Error:
ErrorLSB:           .res 1
ErrorMSB:           .res 1

StepSize:
StepSizeLSB:        .res 1
StepSizeMSB:        .res 1

StepIndex:          .res 1

.segment "CODE"

INIT:
        ret

; Remember to clear APU regs when we do non-NSF version
PLAY:
        lda     #<SampleData
        sta     SampleAddrLSB
        lda     #>SampleData
        sta     SampleAddrMSB

        lda     #<SampleSize
        sta     SampleBytesLeftLSB
        lda     #>SampleSize
        sta     SampleBytesLeftMSB

        jsr     PlayAdpcm
        ret


; Shift a 16-bit variable right
.macro lsr16    var
        lda     var
        lsr
        sta     var
        lda     var+1
        ror
        sta     var+1
.endmac


; Based on C code from http://svn.annodex.net/annodex-core/libsndfile-1.0.11/src/vox_adpcm.c
; A = nybble to process (high four bytes clear)
; Y must not be modified
.macro HandleAdpcmCode
        sta     Code
        lda     StepIndex
        asl                             ; indexing into table of 16-bit values
        tax
        lda     AdpcmStepTbl,x
        sta     StepSizeLSB
        sta     ShiftedStepSizeLSB
        inx
        lda     AdpcmStepTbl,x
        sta     StepSizeMSB
        sta     ShiftedStepSizeMSB

        lda     #0
        sta     ErrorLSB
        sta     ErrorMSB

        lda     #$04
        bit     Code
        bne     :+
        add16   Error, ShiftedStepSize
:       lsr16   ShiftedStepSize
        lda     #$02
        bit     Code
        bne     :+
        add16   Error, ShiftedStepSize
:       lsr16   ShiftedStepSize
        lda     #$01
        bit     Code
        bne     :+
        add16   Error, ShiftedStepSize
:
        lda     #$08
        bit     Code
        bne     @add_error
        sub16   Delta, Error
        jmp     :+
@add_error:
        add16   Delta, Error
:       ???
.endmac


PlayAdpcm:
        ldy     #0                          ; Y is SampleAddr offset
        sty     StepIndex                   ; clear step index
@loop:
        lda     (SampleAddr), y             ; 5 cycles
        and     #$0f                        ; 2
        HandleAdpcmCode

        ; insert wait loop here

        lda     (SampleAddr),y              ; 5
        lsr                                 ; 2
        lsr                                 ; 2
        lsr                                 ; 2
        lsr                                 ; 2
        HandleAdpcmCode

        ; insert wait loop here

        iny                                 ; 2
        bne     :+                          ; 2
        inc     SampleAddrMSB
:
        ; decrement SampleBytesLeft and quit if zero
        ; 16-bit decrement taken from http://6502org.wikidot.com/software-incdec#toc2
        lda     SampleBytesLeftLSB
        bne     @lsb_nonzero
        lda     SampleBytesLeftMSB
        beq     @done
        dec     SampleBytesLeftMSB
@lsb_nonzero:
        dec     SampleBytesLeftLSB
        jmp     @loop

@done:
        jmp     @done


AdpcmStepTbl:
        .word 16,  17,  19,  21,  23,   25,   28,   31
        .word 34,  37,  41,  45,  50,   55,   60,   66
        .word 73,  80,  88,  97,  107,  118,  130,  143
        .word 157, 173, 190, 209, 230,  253,  279,  307
        .word 337, 371, 408, 449, 494,  544,  598,  658
        .word 724, 796, 876, 963, 1060, 1166, 1282, 1411
        .word 1552

SampleData:
        .incbin "dk-roar-sm.raw"
        .align   256                        ; Better would be to pad with $80
SampleDataEnd:
SampleDataSize = SampleDataEnd - SampleData
