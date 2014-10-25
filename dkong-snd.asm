; This is a disassembly of Donkey Kong's sound code.
; This runs on the i8035 (really an MB8884), not the Z80!
; This chip uses the MCS-48 instruction set.
; MCS-48 cheat sheet: http://www.nyx.net/~lturner/instruct_set.html
; MCS-48 manual: https://archive.org/details/IntelMcs48FamilyOfSingleChipMicrocomputersUsersManual
; Initial disassembly produced by MAME 0.152.
;
; It's worth noting that this sound CPU does not control all of the game's sound.
; It primarily controls music; many sound effects are done using discrete logic,
; and cannot be modified via software.
;
; Port map
; --------
; BUS:  not used
; P1:   DAC (out)
; P2:   plays spring when bit 5 is clear on read; for writes, see below (in/out)
; T0:   play "scored points" jingle (in)
; T1:   play falling sound effect (in)
;
; P2 writes
; ---------
; Bit 7: reset volume decay if set (keep on for no decay)
; Bit 6: if clear, External Data Memory reads compressed sample ROM
; Bit 5: seems unused
; Bit 4: "status code to main cpu" (according to MAME) -- I don't think the game uses this (@TODO@ -- verify)
; Bits 2-0: Selects 256-byte page for sample ROM reads
;
; An external interrupt will play the death music.
;
; Data memory map
; ---------------
; $08-17: stack
; $18 (r0'): updated while triangle channel is playing
; $1d (r5'): updated while triangle channel is playing (poking will reset phase while triangle is playing)
; $1e (r6'): triangle channel frequency LSB
; $1f (r7'): triangle channel frequency MSB
; $20: number of tune currently playing
;
; As is standard for the MCS-48 series, $00-07 are r0-r7 and $18-1f are r0'-r7'
;
; External data memory map
; ------------------------
; $00-FF: read from gorilla roar sample (P2 bit 6 must be clear)
; $20: number of tune to play (P2 bit 6 must be set)
;
; The value read from $20 is the value written to REG_MUSIC in the main program, but with the lower four bits inverted.
; So if the Z80 writes 02 to REG_MUSIC, the i8035 will get 0D on at $20.
;
; T, the system timer, is used to decide when to stop playing sound and fetch data for the next iteration of the loop.
;
; Sound channels
; --------------
; Most of the music and sound effects use two sound channels. We'll call them A and B.
; During play, channel B is used for sound effects, while channel A is used for music.
; Outside of play, both are used for music.
; Both channels use wavetables. Which tables are used depends on the routine, but they're all triangle waves.
;
; These channels are played by a loop that runs at about 11,765 Hz.
; In every iteration of the loop, it increments the channel's counter by the frequency.
; The highest six bits of this counter are the output of that channel for that iteration.
;
; To convert frequency in Hz to our frequency value, multiply by 65536/11765 = 5.5704.
; So if you want to play a 440 Hz tone, the number stored would be 440*5.5704 = 2450 = $992.
; To convert from frequency values to Hz, divide by 5.5704. 2450 / 5.5704 = 439.82.
;
; There is no per-channel volume control. The DAC itself can apply volume decay; see description of P2.
;
; Sound channel registers (RB0 = channel A; RB1 = channel B):
;   * r4: counter LSB
;   * r5: counter MSB
;   * r6: frequency LSB
;   * r7: frequency MSB
;
; Glossary
; --------
; DM: Data Memory (used by MOV)
; PM: Program Memory (used by MOVP/MOVP3)
; XDM: External Data Memory (used by MOVX)
; r0': r0 prime (r0 in RB1 as opposed to RB0)
;
; Miscellaneous
; -------------
; The program is remarkably stable. You can play with regs or vars all you like in the debugger, and it will often correct itself.
; If it doesn't, setting PC = 0 should be sufficient to get it to behave normally again.
;
; Patterns to document in appropriate places
; ------------------------------------------
; 00-15: music patterns using the pattern data in $300-4ff
; 80-ff: has to do with digital audio samples
;   * fa: unused "Nice!/Hey!/Thanks!" sample
;   * fc: unused "Help!" sample
;   * fd: DK roar (once, not three times like usual)

; Program execution begins here
; -----------------------------
000: 55      strt t
001: 04 52   jmp  $052          ; jump to main


; Play death music (interrupt handler)
; ------------------------------------
; This tune has three parts.
; The first part is a rapid series of descending notes. It's generated mathematically, like a sound effect,
; so we'll call it the SFX part.
; The second part is a brief melody using the music engine, so we'll call it the melodic part.
003: C5      sel  rb0
004: A5      clr  f1
005: 8A 40   orl  p2,#$40
007: 8A 80   orl  p2,#$80
009: B9 02   mov  r1,#$02       ; run through loop 1 twice
00B: BA 40   mov  r2,#$40       ; r2 and r3 control the frequency
00D: BB 40   mov  r3,#$40

; start of loop 1 (this loop plays the first two notes of SFX part)
00F: FA      mov  a,r2
010: 77      rr   a
011: 77      rr   a
012: 53 3F   anl  a,#$3F
014: 6A      add  a,r2
015: AA      mov  r2,a
016: AB      mov  r3,a
017: 34 00   call $100
019: FB      mov  a,r3
01A: 97      clr  c
01B: 67      rrc  a
01C: 6B      add  a,r3
01D: AB      mov  r3,a
01E: 34 00   call $100
020: E9 0F   djnz r1,$00F       ; loop back

; start of loop 2 (plays rest of SFX part)
022: FA      mov  a,r2
023: 47      swap a
024: 00      nop
025: 53 0F   anl  a,#$0F
027: 37      cpl  a
028: 17      inc  a
029: 6A      add  a,r2
02A: 07      dec  a
02B: AA      mov  r2,a
02C: AB      mov  r3,a
02D: 03 D8   add  a,#$D8        ; A < $28?
02F: E6 3C   jnc  $03C          ; yes; jump to melodic part
031: 34 00   call $100
033: FB      mov  a,r3
034: 97      clr  c
035: 67      rrc  a
036: 6B      add  a,r3
037: AB      mov  r3,a
038: 34 00   call $100
03A: 04 22   jmp  $022          ; loop back

; play melodic part of death music
03C: D5      sel  rb1
03D: 23 2B   mov  a,#$2B
03F: 34 81   call $181
041: 14 45   call $045
043: 04 52   jmp  $052          ; jump to main

045: 80      movx a,@r0
046: 37      cpl  a
047: B4 33   call $533          ; fetch from page 5
049: C6 51   jz   $051          ; return if zero
04B: 53 F0   anl  a,#$F0        ; is high nybble of A set?
04D: 96 51   jnz  $051          ; return if so
04F: 04 45   jmp  $045          ; loop back if not
051: 83      ret


; Main
; ----
; The program can (and does) jump here at any time regardless of whether it's inside a subroutine.
; Since the stack is a circular buffer, the stack never overflows.

; Initialize program
052: 05      en   i
053: 85      clr  f0
054: A5      clr  f1

; Clear number of tune
055: B8 20   mov  r0,#$20
057: B0 00   mov  @r0,#$00

; Clear channel B frequency
059: D5      sel  rb1
05A: 27      clr  a
05B: AE      mov  r6,a
05C: AF      mov  r7,a
05D: C5      sel  rb0

; No decay
; (Fall noise when DK falls will be too quiet if this is NOPped out)
05E: 8A 80   orl  p2,#$80

; signal end of interrupt?
060: 14 73   call $073

; start of main loop
062: 26 74   jnt0 $074          ; if T0, play "scored points" jingle
064: A5      clr  f1            ; ???
065: 0A      in   a,p2          ; Is bit 5 of p2 clear?
066: 37      cpl  a
067: B2 A8   jb5  $0A8          ; yes; play spring noise

; Clear channel A frequency
069: 27      clr  a
06A: AE      mov  r6,a
06B: AF      mov  r7,a

; Clear r1 (why?)
06C: A9      mov  r1,a

06D: B4 35   call $535          ; check for music to play and play any
06F: 14 73   call $073          ; signal any interrupts as handled
071: 04 62   jmp  $062          ; loop back


; This "routine" just signals any interrupts as handled
073: 93      retr


; Play "scored points" jingle
; ---------------------------
074: B8 20   mov  r0,#$20
076: F0      mov  a,@r0
077: 03 05   add  a,#$05
079: C6 69   jz   $069
07B: F0      mov  a,@r0
07C: 03 09   add  a,#$09
07E: C6 69   jz   $069
080: B8 08   mov  r0,#$08
082: A5      clr  f1
083: B5      cpl  f1
084: D4 1A   call $61A

; start of loop
086: D4 38   call $638
088: 8A 80   orl  p2,#$80
08A: C6 62   jz   $062          ; if zero, jump to program's main loop
08C: B9 03   mov  r1,#$03
08E: 34 3F   call $13F
090: B4 35   call $535
092: E9 8E   djnz r1,$08E
094: B9 04   mov  r1,#$04
096: B4 35   call $535
098: E9 96   djnz r1,$096
09A: FA      mov  a,r2
09B: 03 F9   add  a,#$F9
09D: A9      mov  r1,a
09E: C6 86   jz   $086
0A0: 9A 7F   anl  p2,#$7F
0A2: B4 35   call $535
0A4: E9 A2   djnz r1,$0A2
0A6: 04 86   jmp  $086          ; loop back


; Play spring noise
; -----------------
0A8: BB 20   mov  r3,#$20
0AA: 34 15   call $115
0AC: FB      mov  a,r3
0AD: 77      rr   a
0AE: 77      rr   a
0AF: 53 3F   anl  a,#$3F
0B1: 6B      add  a,r3
0B2: AB      mov  r3,a
0B3: 26 74   jnt0 $074
0B5: E6 AA   jnc  $0AA
0B7: 34 15   call $115
0B9: FB      mov  a,r3
0BA: 77      rr   a
0BB: 77      rr   a
0BC: 53 3F   anl  a,#$3F
0BE: 6B      add  a,r3
0BF: AB      mov  r3,a
0C0: 26 74   jnt0 $074
0C2: E6 B7   jnc  $0B7
0C4: 04 62   jmp  $062
0C6: BA 08   mov  r2,#$08
0C8: B9 FF   mov  r1,#$FF
0CA: 8A 80   orl  p2,#$80
0CC: A5      clr  f1
0CD: B5      cpl  f1
0CE: FA      mov  a,r2
0CF: AB      mov  r3,a
0D0: 34 31   call $131
0D2: 34 31   call $131
0D4: FA      mov  a,r2
0D5: 97      clr  c
0D6: 67      rrc  a
0D7: 6A      add  a,r2
0D8: F6 62   jc   $062
0DA: AB      mov  r3,a
0DB: 34 31   call $131
0DD: 34 31   call $131
0DF: 34 31   call $131
0E1: FA      mov  a,r2
0E2: AB      mov  r3,a
0E3: 34 31   call $131
0E5: 34 31   call $131
0E7: FA      mov  a,r2
0E8: 97      clr  c
0E9: 67      rrc  a
0EA: 97      clr  c
0EB: 67      rrc  a
0EC: 6A      add  a,r2
0ED: AA      mov  r2,a
0EE: 04 CE   jmp  $0CE

; junk
0F0: FF
0F1: FF
0F2: FF
0F3: FF
0F4: FF
0F5: FF
0F6: FF
0F7: FF
0F8: FF
0F9: FF
0FA: FF
0FB: FF
0FC: FF
0FD: FF
0FE: FF
0FF: FF

; Called from death music routine
; plays a single note of the SFX part
100: B8 03   mov  r0,#$03       ; call $123 three times
102: 34 23   call $123
104: E8 02   djnz r0,$102
106: B8 03   mov  r0,#$03       ; call $10D (silence) three times
108: 34 0D   call $10D
10A: E8 08   djnz r0,$108
10C: 83      ret

; Silence channels A and B
; ------------------------
10D: 27      clr  a
10E: AE      mov  r6,a
10F: AF      mov  r7,a
110: D5      sel  rb1
111: AE      mov  r6,a
112: AF      mov  r7,a
113: C4 7B   jmp  $67B

; called from spring routine
115: FB      mov  a,r3
116: 47      swap a
117: E7      rl   a
118: 53 1F   anl  a,#$1F
11A: AF      mov  r7,a
11B: FB      mov  a,r3
11C: 47      swap a
11D: E7      rl   a
11E: 53 E0   anl  a,#$E0
120: AE      mov  r6,a
121: A4 35   jmp  $535

; called from routine at $100
123: FB      mov  a,r3
124: 77      rr   a
125: 77      rr   a
126: AE      mov  r6,a
127: 53 3F   anl  a,#$3F
129: AF      mov  r7,a
12A: FE      mov  a,r6
12B: 53 C0   anl  a,#$C0
12D: AE      mov  r6,a
12E: D5      sel  rb1
12F: C4 7B   jmp  $67B

131: FB      mov  a,r3
132: 77      rr   a
133: 77      rr   a
134: AE      mov  r6,a
135: 53 3F   anl  a,#$3F
137: AF      mov  r7,a
138: FE      mov  a,r6
139: 53 C0   anl  a,#$C0
13B: AE      mov  r6,a
13C: D5      sel  rb1
13D: A4 35   jmp  $535

; Seems to be used to give notes a brief pitch shift
13F: FE      mov  a,r6
140: 6F      add  a,r7
141: E6 44   jnc  $144
143: 1F      inc  r7
144: 6F      add  a,r7
145: E6 48   jnc  $148
147: 1F      inc  r7
148: AE      mov  r6,a
149: 83      ret

; Called from $57d music routine (songs using decay)
; In:
;   A = address of playlist in page 5
;   RB = 1
14A: AB      mov  r3,a
14B: D5      sel  rb1           ; can get here from $15c
14C: FB      mov  a,r3
14D: 1B      inc  r3
14E: C5      sel  rb0
14F: B4 33   call $533          ; fetch from page 5
151: C6 9E   jz   $19E          ; return if hit end of playlist
153: F2 9F   jb7  $19F          ; jump if pattern is digital sample
155: A8      mov  r0,a
156: D4 1A   call $61A          ; init pattern
158: D4 38   call $638
15A: D4 4B   call $64B
15C: C6 4B   jz   $14B          ; loop back if zero
15E: B9 03   mov  r1,#$03       ; loop three times
160: 8A 80   orl  p2,#$80       ; reset decay
162: 34 3F   call $13F          ; pitch adjust channel A
164: D5      sel  rb1           ; set channel B
165: 34 3F   call $13F          ; pitch adjust channel B
167: D4 7B   call $67B          ; output sound
169: E9 62   djnz r1,$162       ; loop; RB = 0 here
16B: B9 04   mov  r1,#$04       ; call $67b four times
16D: D5      sel  rb1
16E: D4 7B   call $67B
170: E9 6D   djnz r1,$16D       ; loop; RB = 0 here
172: FA      mov  a,r2
173: 03 F9   add  a,#$F9        ; A -= 7 (adjusts duration for above $67b calls)
175: A9      mov  r1,a
176: C6 58   jz   $158
178: 9A 7F   anl  p2,#$7F       ; enable decay
17A: D5      sel  rb1
17B: D4 7B   call $67B
17D: E9 7A   djnz r1,$17A       ; loop; RB = 0 here
17F: 24 58   jmp  $158

; Called from music routine at $581 (non-BGM songs without decay)
; This is the same as the above routine, but without the pitch shifting and decay.
181: AB      mov  r3,a
182: D5      sel  rb1
183: FB      mov  a,r3
184: 1B      inc  r3
185: C5      sel  rb0
186: B4 33   call $533          ; fetch from page 5
188: C6 9E   jz   $19E          ; return if hit end of playlist
18A: F2 9F   jb7  $19F          ; jump if pattern is digital sample
18C: A8      mov  r0,a
18D: D4 1A   call $61A
18F: D4 38   call $638
191: D4 4B   call $64B
193: C6 82   jz   $182          ; loop back if zero
195: FA      mov  a,r2
196: A9      mov  r1,a
197: D5      sel  rb1
198: D4 7B   call $67B
19A: E9 97   djnz r1,$197
19C: 24 8F   jmp  $18F
19E: 83      ret

; This has to do with digital samples
19F: BE 80   mov  r6,#$80
1A1: A4 A2   jmp  $5A2

; junk
1A3: FF
1A4: FF
1A5: FF
1A6: FF
1A7: FF
1A8: FF
1A9: FF
1AA: FF
1AB: FF
1AC: FF
1AD: FF
1AE: FF
1AF: FF
1B0: FF
1B1: FF
1B2: FF
1B3: FF
1B4: FF
1B5: FF
1B6: FF
1B7: FF
1B8: FF
1B9: FF
1BA: FF
1BB: FF
1BC: FF
1BD: FF
1BE: FF
1BF: FF
1C0: FF
1C1: FF
1C2: FF
1C3: FF
1C4: FF
1C5: FF
1C6: FF
1C7: FF
1C8: FF
1C9: FF
1CA: FF
1CB: FF
1CC: FF
1CD: FF
1CE: FF
1CF: FF
1D0: FF
1D1: FF
1D2: FF
1D3: FF
1D4: FF
1D5: FF
1D6: FF
1D7: FF
1D8: FF
1D9: FF
1DA: FF
1DB: FF
1DC: FF
1DD: FF
1DE: FF
1DF: FF
1E0: FF
1E1: FF
1E2: FF
1E3: FF
1E4: FF
1E5: FF
1E6: FF
1E7: FF
1E8: FF
1E9: FF
1EA: FF
1EB: FF
1EC: FF
1ED: FF
1EE: FF
1EF: FF
1F0: FF
1F1: FF
1F2: FF
1F3: FF
1F4: FF
1F5: FF
1F6: FF
1F7: FF
1F8: FF
1F9: FF
1FA: FF
1FB: FF
1FC: FF
1FD: FF
1FE: FF
1FF: FF

; Triangle wavetable used by routine at $240
200: 00 03 06 09 0C 0F 12 15 18 1B 1E 21 24 27 2A 2D
210: 30 33 36 39 3C 3F 42 45 48 4B 4E 51 54 57 5A 5D
220: 60 5D 5A 57 54 51 4E 4B 48 45 42 3F 3C 39 36 33
230: 30 2D 2A 27 24 21 1E 1B 18 15 12 0F 0C 09 06 03

; This routine has to do with playing the wavetables found elsewhere on this page.
; This is nearly identical to the main body of $67b except for which tables are used.
; The purpose seems to be to use a louder triangle for sound effects.
240: FC      mov  a,r4
241: 6E      add  a,r6
242: AC      mov  r4,a
243: FD      mov  a,r5
244: 7F      addc a,r7
245: AD      mov  r5,a
246: 77      rr   a
247: 77      rr   a
248: 53 3F   anl  a,#$3F        ; use quieter triangle wavetable
24A: A3      movp a,@a
24B: A8      mov  r0,a
24C: C5      sel  rb0
24D: FC      mov  a,r4
24E: 6E      add  a,r6
24F: AC      mov  r4,a
250: FD      mov  a,r5
251: 7F      addc a,r7
252: AD      mov  r5,a
253: 77      rr   a
254: 77      rr   a
255: 43 C0   orl  a,#$C0        ; use louder triangle wavetable
257: A3      movp a,@a
258: D5      sel  rb1
259: 68      add  a,r0
25A: 39      outl p1,a          ; output to DAC
25B: 16 5F   jtf  $25F
25D: 44 40   jmp  $240
25F: C5      sel  rb0
260: 83      ret

; junk
261: FF
262: FF
263: FF
264: FF
265: FF
266: FF
267: FF
268: FF
269: FF
26A: FF
26B: FF
26C: FF
26D: FF
26E: FF
26F: FF
270: FF
271: FF
272: FF
273: FF
274: FF
275: FF
276: FF
277: FF
278: FF
279: FF
27A: FF
27B: FF
27C: FF
27D: FF
27E: FF
27F: FF
280: FF
281: FF
282: FF
283: FF
284: FF
285: FF
286: FF
287: FF
288: FF
289: FF
28A: FF
28B: FF
28C: FF
28D: FF
28E: FF
28F: FF
290: FF
291: FF
292: FF
293: FF
294: FF
295: FF
296: FF
297: FF
298: FF
299: FF
29A: FF
29B: FF
29C: FF
29D: FF
29E: FF
29F: FF
2A0: FF
2A1: FF
2A2: FF
2A3: FF
2A4: FF
2A5: FF
2A6: FF
2A7: FF
2A8: FF
2A9: FF
2AA: FF
2AB: FF
2AC: FF
2AD: FF
2AE: FF
2AF: FF
2B0: FF
2B1: FF
2B2: FF
2B3: FF
2B4: FF
2B5: FF
2B6: FF
2B7: FF
2B8: FF
2B9: FF
2BA: FF
2BB: FF
2BC: FF
2BD: FF
2BE: FF
2BF: FF

; Triangle wavetable, louder than others. Used by routine at $240
2C0: 00 05 0A 0F 14 19 1E 23 28 2D 32 37 3C 41 46 4B
2D0: 50 55 5A 5F 64 69 6E 73 78 7D 82 87 8C 91 96 9B
2E0: 9F 9B 96 91 8C 87 82 7D 78 73 6E 69 64 5F 5A 55
2F0: 50 4B 46 41 3C 37 32 2D 28 23 1E 19 14 0F 0A 05


; Pages 3 and 4: pattern data
; ---------------------------
; Format:
;   * If the value is $00, end the pattern.
;   * Else, if bit 7 is clear, the byte is the duration for all following notes until another duration code is read.
;   * Else, for channel A:
;     * Bits 0-3 set the note (A, A#, B, C ...)
;     * Bits 4-5 set the octave (higher values choose lower octaves)
;     * Bit 6 indicates the next byte is a note to play on channel B.
;
; Channel B notes follow the same format, except bits 6-7 are ignored.
;
; This format means it is impossible to play a note on channel B without also playing one on channel A,
; and the channels cannot have separate durations.

; Pattern $00, empty
300: 00

; Pattern $01, barrels BGM
301: 2A 80 1C 84 0E 88 8A 88 00

; Pattern $02, pie factory BGM
302: 16 84 0B 84 84 00

; Pattern $03, empty
310: 00

; Pattern $04, rivets BGM
311: 18 84 0C 80 80 00

; Pattern $05, running out of time
317: 10 B8 B4 B0 00

; Pattern $06, hammer time
31C: 12 90 09 90 90 12 90 90 94 90 94 90 94 09 94 94
32C: 12 94 94 98 94 98 94 00

; Pattern $07, empty
334: 00

; Pattern $08, scored points
335: 09 B0 B2 B4 12 BA B6 00

; Pattern $09, melodic part of death music
33D: 0E A4 1C E8 90 D8 88 38 E0 80 00

; Pattern $0a, DK climbing ladders
348: 60 CA 82 20 CC 84 40 D0 86 CA 82 08 DA 89 D9 89
358: DA 89 D9 89 DA 89 D9 89 DA 89 D9 89 08 DA 89 D9
368: 89 DA 89 D9 89 DA 89 D9 89 DA 89 D9 89 7F DA 8A
378: 00

; Pattern $0b, empty
379: 00

; Pattern $0c, unused mischievous cutscene music
37A: 24 88 82 88 82 12 D8 88 D6 88 D8 82 D6 82 D6 88
38A: 88 D6 82 82 24 DA 87 D9 83 DA 87 D7 83 09 D8 88
39A: D7 88 D8 88 D7 88 D8 82 D7 82 D8 82 D7 82 48 D8
3AA: 88 00

; Pattern $0d, empty
3AC: 00

; Pattern $0e, empty
3AD: 00

; Pattern $0f, unused happy cutscene music
3AE: 20 E8 88 82 E2 88 10 82 A4 20 DC 88 82 84 18 E0
3BE: 87 08 A2 20 E4 88 E7 82 E8 88 EA 82 20 EA 88 EC
3CE: 82 88 82 EC 88 82 F0 90 88 EC 88 82 10 84 AA E8
3DE: 8C AA 20 E7 92 8A 10 84 A4 E2 8C A4 00

; Pattern $10, How High Can You Get?
3EB: 1B E2 88 09 A4 12 82 A8 12 88 A4 E2 82 A4 12 E0
3FB: 80 09 82 83 86 88 8A 8C 24 D0 88 00

; Pattern $11, Rescued Pauline (odd level)
407: 20 80 DC 98 E0 9A E2 9C 20 90 E4 88 10 E3 90 A4
417: 20 88 DA 8A EA 84 10 E8 8A A4 20 84 E2 82 E2 87
427: 16 E8 88 0A A3 10 E4 82 A0 15 C8 80 2B CA 83 40
437: CB 80 00

; Pattern $12, Rescued Pauline (unused variant)
43A: 10 E8 A4 E8 A4 E6 A2 E6 A2 E4 A0 E4 A0 E2 9C E2
44A: 9C 10 E0 90 A0 E4 88 A0 E4 80 A0 E4 88 A8 20 EA
45A: 96 E8 90 40 F0 80 00

; Pattern $13, Rescued Pauline (even level)
461: 10 E8 A4 E8 A4 E6 A2 E6 A2 E4 A0 E4 A0 E2 9C E2
471: 9C 20 E0 90 10 88 08 A0 A2 20 E4 90 E0 88 20 E2
481: 92 10 8A 08 A2 A4 20 E6 92 E2 8A 20 E8 88 10 82
491: A8 EA 88 A8 E6 82 A4 E8 80 2B 83 40 80 00

; Pattern $14, completed rivet stage
49F: 0A E8 A4 EA A6 14 EC A8 28 E8 A4 0A E8 A4 EA A6
4AF: 14 EC A8 28 E8 A4 00

; Pattern $15, DK is about to fall
4B6: 0A E0 98 E0 98 3C E0 98 12 88 84 88 84 88 84 88
4C6: 84 88 84 88 84 00

; junk
4CC:  FF FF FF FF
4D0:  FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
4E0:  FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
4F0:  FF FF FF FF FF FF FF FF

; Fetch from page 4
4F8: A3      movp a,@a
4F9: 83      ret

; junk
4FA: FF FF FF FF FF FF


; Song table
; ----------
; Used by routine at $535
;
; Codes for each song:
;   * If code is $00, play nothing
;   * Else, if bit 7 is set, it's the code for "rivet removed"
;   * Else, if bit 4 is set, use playlist table at $510 and play using volume decay
;   * Else, if bit 5 is set, use playlist table at $520 and play using no decay
;   * Else, if bit 6 is set, it's the hammer hit sound effect
;   * Else, it's an index straight into the pattern table, not a playlist table (used only for in-game music)
;
; Bits 4 and 5 aren't mere flags. When they are set (and bits 6 and 7 are not), the value is a page 5 pointer straight into the playlist table.
;
; In addition, all bits except 0 and 2 are set with "rivet removed" ditty.
; If all bits are 0, no music is played
500: 00      db $00             ; %00000000  0: No music
501: 20      db $20             ; %00100000  1: Music when DK climbs ladder
502: 10      db $10             ; %00010000  2: How high can you get?
503: 05      db $05             ; %00000101  3: Running out of time
504: 06      db $06             ; %00000110  4: Hammer music
505: 12      db $12             ; %00010010  5: Music after beating even-numbered rivet levels
506: 40      db $40             ; %01000000  6: Hammer hit
507: 16      db $16             ; %00010110  7: Music for completing a non-rivet stage
508: 01      db $01             ; %00000001  8: Music for barrel stage
509: 02      db $02             ; %00000010  9: Music for pie factory
50A: 00      db $00             ; %00000000  A: Music (or lack thereof) for elevator stage
50B: 04      db $04             ; %00000100  B: Music for rivet stage
50C: 14      db $14             ; %00010100  C: Music after beating odd-numbered rivet levels
50D: FA      db $fa             ; %11111010  D: Used when rivet removed
50E: 1E      db $1e             ; %00011110  E: Music when DK is about to fall in rivet stage
50F: 2D      db $2d             ; %00101101  F: DK roars

; Playlist table for $57d songs
; -----------------------------
; For instance, $516 will play patterns $14, $83, $fe, etc. until it hits $00.
; FE 85 FE 85 FE 00 plays three gorilla roars
510: 10      db $10             ; How high can you get?
511: 00      db $00
512: 13      db $13             ; Rescued Pauline (even level)
513: 00      db $00
514: 11      db $11             ; Rescued Pauline (odd level)
515: 00      db $00
516: 14      db $14             ; Completed non-rivet stage
517: 83      db $83
518: FE      db $fe
519: 85      db $85
51A: FE      db $fe
51B: 85      db $85
51C: FE      db $fe
51D: 00      db $00
51E: 15      db $15             ; DK about to fall
51F: 00      db $00

; Playlist table for $581 songs
; -----------------------------
; $522 through $52a seem to be unused
520: 0A      db $0a             ; DK climbs ladder
521: 00      db $00
522: 95      db $95             ; unused
523: FE      db $fe
524: 85      db $85
525: FE      db $fe
526: 85      db $85
527: FE      db $fe
528: 00      db $00
529: 00      db $00
52A: 00      db $00
52B: 09      db $09             ; death music
52C: 00      db $00
52D: FE      db $fe             ; gorilla roar during intro
52E: 84      db $84
52F: FE      db $fe
530: 83      db $83
531: FE      db $fe
532: 00      db $00


; Fetch from page 5
; -----------------
; A routine called from other pages to get data from this page
533: A3      movp a,@a
534: 83      ret


; Part of the program's main loop
; -------------------------------
535: D5      sel  rb1
536: B8 20   mov  r0,#$20       ; load A with inverted number of tune to play
538: 80      movx a,@r0
539: 37      cpl  a             ; uninvert tune number
53A: 53 0F   anl  a,#$0F        ; clear high nybble

; Check whether this the tune is already playing
; (i.e., compare $20 with the song ID we're about to put in $20)
53C: 20      xch  a,@r0         ; fetch old value as we store the new one
53D: 37      cpl  a             ; invert old value
53E: 17      inc  a
53F: 60      add  a,@r0
540: 96 64   jnz  $564          ; $20 != old value of $20; the song has changed

; The song has not changed; continue current song
542: B6 BD   jf0  $5BD          ; if F0, continue fall noise
544: 46 BA   jnt1 $5BA          ; if T1, start fall noise
546: F0      mov  a,@r0         ; get the song ID again
547: A3      movp a,@a          ; look up playlist at $500
548: C6 5D   jz   $55D          ; if zero (silence), go to $67B
54A: F2 5F   jb7  $55F          ; jump if "rivet removed"
54C: 34 3F   call $13F
54E: E9 5D   djnz r1,$55D
550: FF      mov  a,r7
551: 96 56   jnz  $556
553: FE      mov  a,r6
554: C6 75   jz   $575
556: FA      mov  a,r2
557: 03 F8   add  a,#$F8
559: A9      mov  r1,a
55A: 27      clr  a             ; clear channel B frequency
55B: AE      mov  r6,a
55C: AF      mov  r7,a
55D: C4 7B   jmp  $67B

55F: 27      clr  a             ; clear channel B frequency
560: AE      mov  r6,a
561: AF      mov  r7,a
562: C4 7B   jmp  $67B


; Start song
; ----------
; Uses RB1
; @r0 contains the ID of the song to play
564: F0      mov  a,@r0
565: A3      movp a,@a
566: C6 5F   jz   $55F          ; go to $55f if 'song' is silence
568: F2 8C   jb7  $58C          ; "rivet removed" jingle
56A: 92 7D   jb4  $57D          ; music using volume envelopes
56C: B2 81   jb5  $581          ; DK climbs ladder or DK roars
56E: D2 E5   jb6  $5E5          ; hammer hit

; If we get here, it must be stage theme, hammer theme, or running out of time theme
; In other words, background music during gameplay
570: 8A 80   orl  p2,#$80
572: A8      mov  r0,a
573: D4 1A   call $61A
575: D4 38   call $638
577: C6 64   jz   $564
579: B9 08   mov  r1,#$08
57B: C4 7B   jmp  $67B


; Play tune that uses volume decay
; --------------------------------
57D: 34 4A   call $14A
57F: 04 52   jmp  $052


; Play tune that does not use volume decay
; ----------------------------------------
581: 34 81   call $181
583: 04 52   jmp  $052          ; jump to main

; @TODO@ -- not used?
585: C5      sel  rb0
586: BE 80   mov  r6,#$80
588: F4 06   call $706
58A: 04 52   jmp  $052          ; jump to main

58C: 76 91   jf1  $591
58E: C5      sel  rb0
58F: 04 74   jmp  $074

591: B0 08   mov  @r0,#$08
593: A4 46   jmp  $546

595: D5      sel  rb1
596: FB      mov  a,r3
597: 1B      inc  r3
598: C5      sel  rb0
599: A3      movp a,@a
59A: C6 9E   jz   $59E
59C: 96 A2   jnz  $5A2
59E: 14 45   call $045
5A0: 04 52   jmp  $052

; Has to do with digital samples
5A2: D2 B6   jb6  $5B6
5A4: 97      clr  c
5A5: F7      rlc  a
5A6: 97      clr  c
5A7: F7      rlc  a
5A8: A9      mov  r1,a
5A9: 23 80   mov  a,#$80
5AB: 62      mov  t,a
5AC: 16 AE   jtf  $5AE
5AE: 16 B2   jtf  $5B2
5B0: A4 AE   jmp  $5AE

5B2: E9 A9   djnz r1,$5A9
5B4: A4 95   jmp  $595

5B6: F4 06   call $706
5B8: A4 95   jmp  $595


; Play fall noise
; ---------------
5BA: 95      cpl  f0
5BB: BB F0   mov  r3,#$F0
5BD: FB      mov  a,r3          ; can get here from $542
5BE: E7      rl   a
5BF: E7      rl   a
5C0: 47      swap a
5C1: 53 03   anl  a,#$03
5C3: 96 C6   jnz  $5C6
5C5: 17      inc  a
5C6: 37      cpl  a
5C7: 17      inc  a
5C8: 6B      add  a,r3
5C9: AB      mov  r3,a
5CA: 03 E0   add  a,#$E0
5CC: F6 D7   jc   $5D7
5CE: 85      clr  f0
5CF: 27      clr  a
5D0: AE      mov  r6,a
5D1: AF      mov  r7,a
5D2: B8 20   mov  r0,#$20
5D4: A0      mov  @r0,a
5D5: C4 7B   jmp  $67B
5D7: FB      mov  a,r3
5D8: 47      swap a
5D9: E7      rl   a
5DA: 53 1F   anl  a,#$1F
5DC: AF      mov  r7,a
5DD: FB      mov  a,r3
5DE: 47      swap a
5DF: E7      rl   a
5E0: 53 E0   anl  a,#$E0
5E2: AE      mov  r6,a
5E3: C4 7B   jmp  $67B
5E5: B0 04   mov  @r0,#$04
5E7: C5      sel  rb0
5E8: F9      mov  a,r1
5E9: F2 ED   jb7  $5ED
5EB: 04 C6   jmp  $0C6
5ED: D5      sel  rb1
5EE: A4 46   jmp  $546

; junk
5F0: FF      mov  a,r7
5F1: FF      mov  a,r7
5F2: FF      mov  a,r7
5F3: FF      mov  a,r7
5F4: FF      mov  a,r7
5F5: FF      mov  a,r7
5F6: FF      mov  a,r7
5F7: FF      mov  a,r7
5F8: FF      mov  a,r7
5F9: FF      mov  a,r7
5FA: FF      mov  a,r7
5FB: FF      mov  a,r7
5FC: FF      mov  a,r7
5FD: FF      mov  a,r7
5FE: FF      mov  a,r7
5FF: FF      mov  a,r7


; Frequency table used by routine at $65d
; ---------------------------------------
; These seem to be the 12 notes of an octave
; Note that these are big endian!
600: 2800
602: 2A61
604: 2CE6
606: 2F91
608: 3266
60A: FFFF
60C: 3565
60E: 3892
610: 3BEF
612: 3F75
614: 4346
616: 4746
618: 4B83


; Start playing a pattern
; -----------------------
; In: r0 = pattern ID
61A: BB 00   mov  r3,#$00
61C: B9 30   mov  r1,#$30
61E: B1 FF   mov  @r1,#$FF

; Skip patterns until r3 points to the song we want.
; Skip N patterns, where N is r0.
; $00 indicates end of pattern, so we loop until we've counted N nulls.
620: D4 27   call $627          ; fetch byte from pattern data
622: 96 20   jnz  $620          ; keep reading until we hit end-of-pattern
624: E8 20   djnz r0,$620       ; repeat until we've skipped N songs
626: 83      ret


; Fetch a byte from the pattern data
; ----------------------------------
; In:
;   r3 = pointer to song data
;   $30 = page selector. r3 points to page 3 if zero, else page 4
; Out:
;   A = fetched byte
627: B9 30   mov  r1,#$30       ; r1 = address of page selector

; The pointer in r3 will be zero in two cases. Either we have yet to fetch any data or we hit the end of page 3.
; In the former case, $30 will be $ff, so it will be incremented to $00, meaning r3 points to page 3.
; Otherwise, it will be incremented to $01, meaning r3 points to page 4.
629: FB      mov  a,r3
62A: 96 2D   jnz  $62D
62C: 11      inc  @r1           ; increment page selector

62D: F1      mov  a,@r1         ; if page selector is zero...
62E: 96 34   jnz  $634          ; ...then use page 4 and return
630: FB      mov  a,r3          ; else use page 3 and return
631: 1B      inc  r3
632: E3      movp3 a,@a
633: 83      ret
634: FB      mov  a,r3
635: 1B      inc  r3
636: 84 F8   jmp  $4F8          ; fetch from page 4 and return


; Load note
; ---------
638: D4 27   call $627          ; fetch byte from pattern data
63A: C6 5C   jz   $65C          ; return if zero

; If bit 7 is clear, it's a duration
63C: F2 46   jb7  $646
63E: AA      mov  r2,a
63F: D4 27   call $627          ; fetch next byte from pattern data

; If bit 7 of this byte is also clear... well, it doesn't matter because it won't be.
; It never is with the original pattern data, and I don't think this code would have any effect anyway.
641: F2 46   jb7  $646          ; branch always taken with standard pattern data
643: A9      mov  r1,a
644: D4 27   call $627          ; fetch next byte from pattern data

; A now contains a note ID
646: A8      mov  r0,a
647: D4 5D   call $65D          ; get frequency of note
649: F8      mov  a,r0
64A: 83      ret


; We get here after a note was loaded for channel A.
; Now we have to determine whether to play a note for channel B.
64B: D2 54   jb6  $654          ; if channel B flag set, jump
64D: D5      sel  rb1           ; else silence channel B
64E: BE 00   mov  r6,#$00
650: BF 00   mov  r7,#$00
652: C5      sel  rb0
653: 83      ret

; Channel B flag was set; load frequency
654: D4 27   call $627          ; fetch byte from pattern data
656: D5      sel  rb1
657: A8      mov  r0,a
658: D4 5D   call $65D          ; get frequency of note
65A: C5      sel  rb0
65B: F8      mov  a,r0          ; put note ID back in A
65C: 83      ret

; In: r0 = note ID
65D: F8      mov  a,r0          ; get note ID
65E: 53 0F   anl  a,#$0F        ; low nybble is the table index
660: E7      rl   a             ; indexing into 16-bit table
661: AC      mov  r4,a
662: A3      movp a,@a          ; load frequency MSB
663: AF      mov  r7,a
664: FC      mov  a,r4          ; get note ID back
665: 17      inc  a
666: A3      movp a,@a          ; load frequency LSB
667: AE      mov  r6,a
668: F8      mov  a,r0

; Loop N times where N is the first two bits of high nybble
; (i.e., shift the pitch N octaves down)
669: 53 30   anl  a,#$30
66B: 47      swap a
66C: AC      mov  r4,a

; Start of loop
; This loop divides the frequency by N
66D: FF      mov  a,r7
66E: 97      clr  c
66F: 67      rrc  a
670: AF      mov  r7,a
671: FE      mov  a,r6
672: 67      rrc  a
673: AE      mov  r6,a
674: 1C      inc  r4
675: FC      mov  a,r4          ; r4 == 4?
676: 03 FC   add  a,#$FC
678: 96 6D   jnz  $66D          ; loop if not
67A: 83      ret


; Mixer
; -----
; This is the primary routine used to output channels A and B -- the music engine's inner loop.
; It plays a few samples, then returns after a timer fires to give the rest of the music engine a chance to run.
;
; In:
;   r6-7 = channel A frequency (16-bit; r6 = LSB)
;   r6'-7' = channel B frequency (16-bit; r6 = LSB)
;   RB = 1
; Out:
;   RB = 0

; T will be very low here (often 0 or 1). So this roughly halves the time before timer fires
67B: 42      mov  a,t
67C: 03 80   add  a,#$80
67E: 62      mov  t,a

67F: 76 A2   jf1  $6A2          ; use routine at $240 instead if playing certain sound effects

; Start of loop.
; Timing is critical in this loop! Adding any instructions will lower the sampling rate and therefore the pitch.
; Since instructions take one cycle per byte, with three exceptions, the number of cycles taken
; will be the address of the end of the loop minus the address after the end of the loop plus two.
; $6a0 - $681 + 2 = 34 cycles.
; This is a 6 MHz chip with an internal divisor of 15, so the instruction clock runs at 400 kHz.
; So the loop runs at 400,000 / 34 = 11765 Hz.
; We spend a bit of time outside the loop every now and then, though,
; so the actual playback rate is slightly lower.

; add channel B frequency to channel B counter
681: FC      mov  a,r4
682: 6E      add  a,r6
683: AC      mov  r4,a
684: FD      mov  a,r5
685: 7F      addc a,r7
686: AD      mov  r5,a

; This is to index into the wavetable at $6c0
687: 77      rr   a             ; A >>= 2 (A will have highest 6 bits of counter)
688: 77      rr   a
689: 43 C0   orl  a,#$C0        ; The table is based at $6c0
68B: A3      movp a,@a

; A now contains the output sample from channel B.
; Store it in r0'
68C: A8      mov  r0,a

; Repeat everything we just did, but in RB0
; (Thus doing it for channel A)
68D: C5      sel  rb0
68E: FC      mov  a,r4
68F: 6E      add  a,r6
690: AC      mov  r4,a
691: FD      mov  a,r5
692: 7F      addc a,r7
693: AD      mov  r5,a
694: 77      rr   a
695: 77      rr   a
696: 43 C0   orl  a,#$C0
698: A3      movp a,@a

; Mix channel A output with the channel B output stored in r0'
699: D5      sel  rb1
69A: 68      add  a,r0

; Send the mixed output to the DAC
69B: 39      outl p1,a

; Return when timer fires; else loop back
69C: 16 A0   jtf  $6A0
69E: C4 81   jmp  $681

; Done
6A0: C5      sel  rb0
6A1: 83      ret

6A2: 44 40   jmp  $240

; Fetch from page 6
; Doesn't appear to be used
6A4: A3      movp a,@a
6A5: 83      ret

; junk
6A6: FF      mov  a,r7
6A7: FF      mov  a,r7
6A8: FF      mov  a,r7
6A9: FF      mov  a,r7
6AA: FF      mov  a,r7
6AB: FF      mov  a,r7
6AC: FF      mov  a,r7
6AD: FF      mov  a,r7
6AE: FF      mov  a,r7
6AF: FF      mov  a,r7
6B0: FF      mov  a,r7
6B1: FF      mov  a,r7
6B2: FF      mov  a,r7
6B3: FF      mov  a,r7
6B4: FF      mov  a,r7
6B5: FF      mov  a,r7
6B6: FF      mov  a,r7
6B7: FF      mov  a,r7
6B8: FF      mov  a,r7
6B9: FF      mov  a,r7
6BA: FF      mov  a,r7
6BB: FF      mov  a,r7
6BC: FF      mov  a,r7
6BD: FF      mov  a,r7
6BE: FF      mov  a,r7
6BF: FF      mov  a,r7

; Triangle wavetable used by routine at $67B
6C0: 00 03 06 09 0C 0F 12 15 18 1B 1E 21 24 27 2A 2D
6D0: 30 33 36 39 3C 3F 42 45 48 4B 4E 51 54 57 5A 5D
6E0: 60 5D 5A 57 54 51 4E 4B 48 45 42 3F 3C 39 36 33
6F0: 30 2D 2A 27 24 21 1E 1B 18 15 12 0F 0C 09 06 03


; Page 7: digital sample playback
; -------------------------------
700: 02      db $02
701: 04      db $04
702: 06      db $06
703: 0C      db $0c
704: 14      db $14
705: FF      db $ff

; called from routines at $585 and $5b6
706: A8      mov  r0,a
707: A3      movp a,@a
708: 28      xch  a,r0
709: 17      inc  a
70A: A3      movp a,@a
70B: A9      mov  r1,a
70C: 12 24   jb0  $724
70E: C9      dec  r1
70F: F4 24   call $724
711: 9A 7F   anl  p2,#$7F
713: B8 00   mov  r0,#$00
715: B9 FF   mov  r1,#$FF
717: F4 24   call $724
719: 9A 7F   anl  p2,#$7F
71B: B8 00   mov  r0,#$00
71D: B9 FF   mov  r1,#$FF
71F: F4 24   call $724
721: 8A 80   orl  p2,#$80
723: 83      ret

724: BF 00   mov  r7,#$00
726: 9A BF   anl  p2,#$BF
728: A5      clr  f1
729: 23 B0   mov  a,#$B0        ; prepare to switch XDM to digital sample ROM
72B: 48      orl  a,r0
72C: 3A      outl p2,a          ; switch!
72D: BA 08   mov  r2,#$08
72F: 81      movx a,@r1
730: E9 3B   djnz r1,$73B       ; jump ahead if not zero
732: AB      mov  r3,a
733: C8      dec  r0
734: F8      mov  a,r0
735: F2 BA   jb7  $7BA
737: 43 B0   orl  a,#$B0
739: 3A      outl p2,a
73A: FB      mov  a,r3
73B: 77      rr   a             ; we can get here from $730
73C: AB      mov  r3,a
73D: F2 78   jb7  $778
73F: 76 5B   jf1  $75B
741: 1F      inc  r7
742: FF      mov  a,r7
743: A3      movp a,@a
744: F2 4A   jb7  $74A
746: 37      cpl  a
747: 17      inc  a
748: E4 4E   jmp  $74E
74A: CF      dec  r7
74B: 00      nop
74C: 23 EC   mov  a,#$EC
74E: 6E      add  a,r6
74F: AE      mov  r6,a
750: F6 59   jc   $759
752: 27      clr  a
753: AE      mov  r6,a
754: 39      outl p1,a          ; output to DAC
755: EA AC   djnz r2,$7AC
757: E4 2D   jmp  $72D
759: E4 54   jmp  $754
75B: A5      clr  f1
75C: CF      dec  r7
75D: FF      mov  a,r7
75E: F2 62   jb7  $762
760: E4 64   jmp  $764
762: 27      clr  a
763: AF      mov  r7,a
764: A3      movp a,@a
765: 37      cpl  a
766: 17      inc  a
767: 6E      add  a,r6
768: F6 71   jc   $771
76A: 27      clr  a
76B: AE      mov  r6,a
76C: 39      outl p1,a          ; clear DAC
76D: EA AC   djnz r2,$7AC
76F: E4 2D   jmp  $72D
771: 00      nop
772: AE      mov  r6,a
773: 39      outl p1,a
774: EA AC   djnz r2,$7AC
776: E4 2D   jmp  $72D
778: 76 93   jf1  $793
77A: B5      cpl  f1
77B: CF      dec  r7
77C: FF      mov  a,r7
77D: F2 81   jb7  $781
77F: E4 83   jmp  $783
781: 27      clr  a
782: AF      mov  r7,a
783: A3      movp a,@a
784: 6E      add  a,r6
785: AE      mov  r6,a
786: E6 90   jnc  $790
788: 23 FF   mov  a,#$FF
78A: AE      mov  r6,a
78B: 39      outl p1,a
78C: EA AC   djnz r2,$7AC
78E: E4 2D   jmp  $72D
790: 00      nop
791: E4 8B   jmp  $78B
793: 1F      inc  r7
794: FF      mov  a,r7
795: A3      movp a,@a
796: F2 9C   jb7  $79C
798: 00      nop
799: 00      nop
79A: E4 9F   jmp  $79F
79C: CF      dec  r7
79D: FF      mov  a,r7
79E: A3      movp a,@a
79F: 6E      add  a,r6
7A0: E6 AA   jnc  $7AA
7A2: 23 FF   mov  a,#$FF
7A4: AE      mov  r6,a
7A5: 39      outl p1,a
7A6: EA AC   djnz r2,$7AC
7A8: E4 2D   jmp  $72D
7AA: E4 A4   jmp  $7A4
7AC: FB      mov  a,r3
7AD: C6 B4   jz   $7B4
7AF: 00      nop
7B0: 00      nop
7B1: 00      nop
7B2: E4 3B   jmp  $73B
7B4: 81      movx a,@r1
7B5: C6 BA   jz   $7BA
7B7: FB      mov  a,r3
7B8: E4 3B   jmp  $73B
7BA: 8A 40   orl  p2,#$40
7BC: A5      clr  f1
7BD: 83      ret
7BE: FF      mov  a,r7
7BF: FF      mov  a,r7
7C0: FF      mov  a,r7
7C1: FF      mov  a,r7
7C2: FF      mov  a,r7
7C3: FF      mov  a,r7
7C4: FF      mov  a,r7
7C5: FF      mov  a,r7
7C6: FF      mov  a,r7
7C7: FF      mov  a,r7
7C8: FF      mov  a,r7
7C9: FF      mov  a,r7
7CA: FF      mov  a,r7
7CB: FF      mov  a,r7
7CC: FF      mov  a,r7
7CD: FF      mov  a,r7
7CE: FF      mov  a,r7
7CF: FF      mov  a,r7
7D0: FF      mov  a,r7
7D1: FF      mov  a,r7
7D2: FF      mov  a,r7
7D3: FF      mov  a,r7
7D4: FF      mov  a,r7
7D5: FF      mov  a,r7
7D6: FF      mov  a,r7
7D7: FF      mov  a,r7
7D8: FF      mov  a,r7
7D9: FF      mov  a,r7
7DA: FF      mov  a,r7
7DB: FF      mov  a,r7
7DC: FF      mov  a,r7
7DD: FF      mov  a,r7
7DE: FF      mov  a,r7
7DF: FF      mov  a,r7
7E0: FF      mov  a,r7
7E1: FF      mov  a,r7
7E2: FF      mov  a,r7
7E3: FF      mov  a,r7
7E4: FF      mov  a,r7
7E5: FF      mov  a,r7
7E6: FF      mov  a,r7
7E7: FF      mov  a,r7
7E8: FF      mov  a,r7
7E9: FF      mov  a,r7
7EA: FF      mov  a,r7
7EB: FF      mov  a,r7
7EC: FF      mov  a,r7
7ED: FF      mov  a,r7
7EE: FF      mov  a,r7
7EF: FF      mov  a,r7
7F0: FF      mov  a,r7
7F1: FF      mov  a,r7
7F2: FF      mov  a,r7
7F3: FF      mov  a,r7
7F4: FF      mov  a,r7
7F5: FF      mov  a,r7
7F6: FF      mov  a,r7
7F7: FF      mov  a,r7
7F8: FF      mov  a,r7
7F9: FF      mov  a,r7
7FA: 07      dec  a
7FB: FF      mov  a,r7
7FC: 05      en   i
7FD: FF      mov  a,r7
7FE: 02      out  bus,a
7FF: 00      nop
