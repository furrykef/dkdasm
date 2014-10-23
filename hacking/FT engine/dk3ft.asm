Start:
        sei
        ldx     #$ff
        txs
        ; fall through to Main

Main:
        jsr     GetSongID
@play_song:
        sta     CurSongID
        tay                         ; save song ID in Y
        ldx     #0                  ; use NTSC playback
        tya                         ; put song ID back in A
        jsr     ft_music_init
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


.segment "FOOTER"
.word VblankISR                     ; NMI
.word Start                         ; Reset
.word Start                         ; BRK
