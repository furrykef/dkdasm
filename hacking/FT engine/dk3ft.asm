.segment "CODE"

Start:
        sei
        ldx     #$ff
        txs

        ; Silence all channels
        lda     #$00
        tax
@init_channels:
        sta     $4000,x
        cmp     #$13
        bne     @init_channels
        lda     #$0f
        sta     $4015
        lda     #$40
        sta     $4017

        ; Give the Z80 time to clear (or set) our input before we begin.
        ; Dunno if it's necessary or not, but it can't hurt.
        ldx     #0
@wait:
        dex
        bne     @wait

        ; fall through to Main

Main:
        jsr     GetSongID
@play_song:
        sta     CurSongID
        tay                         ; save song ID in Y
        ldx     #0                  ; use NTSC playback
        tya                         ; put song ID back in A
        jsr     ft_music_init       ; load song (A = song ID, X = NTSC/PAL)
@play_frame:
        jsr     WaitForVblank
        jsr     ft_music_play
        lda     var_PlayerFlags     ; is the song done?
        beq     Main                ; next song if so
        jsr     GetSongID           ; has the song changed?
        cmp     CurSongID
        bne     @play_song          ; change song if so
        jmp     @play_frame         ; play next frame of this song if not


; Out: A = song ID
GetSongID:
        ; The 2a03 is notoriously glitchy when reading $4016 during DPCM playback.
        ; I'm not sure if that bug is restricted to the NES or if it applies here,
        ; but better safe than sorry. So we'll we wait until two consecutive reads match.
        lda     $4016
@loop:
        sta     tmp                 ; tmp := previous read
        lda     $4016
        cmp     tmp
        bne     @loop
        rts


WaitForVblank:
        lda     #0
        sta     VblankFlag
@loop:
        lda     VblankFlag
        beq     @loop
        rts


VblankISR:
        pha
        lda     #1
        sta     VblankFlag
        pla
        rti


.segment "BSS"
tmp:            .res 1
CurSongID:      .res 1
VblankFlag:     .res 1


.segment "FOOTER"
.word VblankISR                 ; NMI
.word Start                     ; Reset
.word Start                     ; BRK


.include "driver.s"
