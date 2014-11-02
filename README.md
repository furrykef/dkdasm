# Donkey Kong disassembly / hacking project

## What this project is
A complete, commented disassembly of the arcade version of Donkey Kong. It is intended to easily be used by humans for any purpose.

At least, that's what we're aiming for. As it is, we've got quite a ways to go.


## What this project is not
We do not aim to modify the game in any way, not even to fix bugs (and there are a few!). Nothing stops you from making a fork and making whatever modifications you like, however, and in fact making this possible and practical is part of our aim.


## Donkey Kong hardware
This is just a rough overview. More detailed information is in the code.

### Overview
Donkey Kong has two main processors: a Z80 CPU and an i8035 microcontroller sound CPU. Technically, the sound CPU is an MB8884, but it is essentially the same chip.

### Video
The monitor is a typical 256x224 monitor oriented vertically, except Nintendo's monitors inverted the colors, so a standard monitor won't display correct colors. That's not relevant for hacking, though.

The hardware supports up to 96 sprites, with up to 16 sprites per scanline. (Remember that scanlines are vertical due to the monitor's orientation.) All sprites are 16x16 and have three colors, plus transparency. This was top-notch equipment at the time!

On real hardware, a sprite that goes over the edge of the screen will wrap around to the other side of the screen. This never actually happened in the games using this hardware, so emulators may not emulate this functionality.

The graphics have their own ROMs. The game does not use VRAM for graphics data.

### Audio
The i8035 handles all music and several sound effects, but the sounds of Mario walking and jumping and the "boom" sound effect are handled entirely using discrete logic, so software has no control over their sound. (This is why Double Donkey Kong boards have a couple of Donkey Kong Jr. sound effects in Donkey Kong.)

The i8035 has no native sound capabilities. But one of its output ports is connected to a DAC, meaning it can output arbitrary waveforms. The only waveforms the game does output are triangle waves (two channels mixed) and digital samples. Digital samples are only used for DK's roar, but there are two unused voice samples in the ROM.

There are two sound ROMs. s_3i_b.bin is the main program ROM and is what appears in disassembled form in this repository. s_3j_b.bin is a sample ROM that contains only compressed digital samples, though this ROM could be repurposed for other data if you write code to use it.


## Level design tips
Don't make your game too hard! This is was the main flaw of the old D2K: Return of Jumpman hack. Remember that newcomers to your hack have never played it before, whereas you've probably spent hours playtesting your stages. The stage should be quite easy for you, but challenging for new players. Have playtesters record videos and see how they play. Ideally, they'll lose a couple of lives on their first few attempts, but soon get the hang of it.

Remember that the original game had at least one unique concept per stage. The first stage had ramps and barrels; the second stage had conveyors and cement pies; the third stage had elevators and springs; the fourth stage had rivets. Donkey Kong Junior followed this philosophy as well except in its first stage.

You don't necessarily have to implement a new mechanic for every stage, but try to keep things fresh.

Don't forget hammers. Every stage except the elevator stage has two hammers. If you don't include any hammers, make sure it's by choice, not negligence. The same goes for the three bonus items.

Do not put bonus items in locations where it would be pointless to try to get them, either due to excessive risk or because collecting them would take more points off the clock than you'd get as a reward.

Notice the thought that went into the original stages' design. In the barrel stage, it's always the longest ladders that are broken, the implication being they were stretched past their breaking point. The elevators in the elevator stage also likely go in opposite directions for a reason: the intention seems to be they operate in a loop, so that each platform that goes up the left comes down on the right. These considerations can be freely ignored if they make the level more fun; the point is just to consider that the stage design usually has a certain logic to it.

Have a consistent design philosophy.

DK came out in a time games were mostly about getting high scores. However, it also introduced the idea of focusing on how far you can get. Look at how the pie factory and elevator levels allow you to get more points at the risk of not getting as far by choosing a more difficult path.


## Hardware conversions
If you're making a hack, consider targeting Donkey Kong Junior or especially Donkey Kong 3 hardware instead of Donkey Kong. The hardware is nearly the same, but better, and your ROM code won't need many adjustments. How to handle these adjustments is currently an exercise for the reader.

### Donkey Kong Junior
This gives you 24 KB program ROM instead of 16 KB, and 8 KB tile ROM instead of 4 KB.

There are a few downsides:
* Mario's walking and jumping sound effects as well as the "boom" sound will use Donkey Kong Junior's sounds instead of Donkey Kong's, because these sounds are part of the hardware. These still sound acceptable.
* Donkey Kong Junior's sound CPU can't play digital samples without making adjustments to the code, so DK won't roar. Sound is otherwise fine after you NOP out the "cpl a" instruction at $539 (i.e., change this byte to 0). We may create a fix for the digital sample playback in the future, but probably only if there is demand for it.

### Donkey Kong 3
This gives you 32 KB program ROM instead of 16 KB, 8 KB tile ROM instead of 4 KB, and 16 KB sprite ROM instead of 8 KB. It also gives you a 4 MHz CPU instead of 3 MHz.

Donkey Kong 3 also has superior sound hardware: two NES APUs instead of one i8035 and discrete logic. However, this would require replacing the entire sound code. Luckily, this is not too difficult, since NES music tools such as ppmck can be used with little or no modification so long as your code and data fit into 8 KB per APU and use no more than 512 bytes of RAM, including stack. (You might want to trim out any features you're not using to save ROM and RAM space, especially anything relating to expansion audio chips such as VRC6, etc.) As for the Z80 side of things, it would mostly involve changing all the code that uses the $7xxx registers to use DK3's registers.

There is a minor issue in that DIP switches for emulators such as MAME will assume you're adjusting settings for DK3 and not for DK.

#### Sound hardware comparison
There is very little that DK3's audio hardware can't do that DK can. The 2A03 is designed to output square and triangle waves, but it can use the DPCM counter register as a 7-bit DAC. One of the few advantages DK has over DK3 is its DAC is 8-bit, but its sound output is so heavily filtered that the quality isn't really any higher.

Each 2A03 in Donkey Kong 3 has 8 KB ROM and 512 bytes of RAM.

As with controller reads on the NES, this hardware has a bug where reads from the I/O port may be wrong during DPCM playback. Emulators may not emulate this glitch. In any case, this bug can be worked around by reading repeatedly until you get the same value twice.

#### Suggested approaches for sound
You might use one 2A03 primarily for sound effects and one primarily for music. This way you don't have to worry about having to play music and sound effects at the same time, which is good if you want to use a music engine that doesn't support this, such as FamiTracker.

### Mario Bros.
Mario Bros. has more advanced video hardware, giving you 8 colors per tile and 7 colors per sprite instead of 4/tile and 3/sprite. However, there are fewer palettes available.

#### Comparison with DK3 hardware
The Mario Bros. hardware has only 28 KB program ROM space instead of 32 KB.

DK3 and Mario Bros. both allow up to 512 tiles and 256 sprites, so their graphical capacity is the same.

DK3 and Mario Bros. both use a 4 MHz Z80, so their processing capacity is identical.

The sound hardware is basically the same as Donkey Kong's with a faster chip. That means DK's sound ROM can be used with little modification, but you cannot write new music or sound using standard tools such as FamiTracker.

### Summary
* DKJr: The same as DK hardware, but with more ROM space and with DKJr sound effects
* DK3: The most ROM space; two NES APUs for audio (can be used with FamiTracker)
* Mario: Slightly less program ROM space than DK3; sound hardware similar to DK's


## UAQ
Unasked questions: questions nobody has actually asked us, but we thought we'd answer anyway!

Q: I made a hack to the game. Can I distribute it?
A: If you do, it probably would be best to do so in a patch format such as .ips. This is least likely to earn Nintendo's ire.

Q: What license is the code under?
A: The "© 1981 Nintendo" license. ;)

Q: Can I sell a hack I made?
A: Nintendo probably wouldn't like it much. But we are in no legal position to tell you what to do with the code or tools.


## Contributors
The disassembly process for the Z80 code had two main phases.

This project [began life on the Donkey Kong Forum](http://donkeykongforum.com/index.php?topic=383.0). That led to an [entry on the Donkey Kong wiki](http://wiki.donkeykonggenius.com/Donkey_Kong_Code). These listings constitute the first phase of the project, where the bulk of the reverse engineering was done. By the end of the first phase, the purpose of most variables and routines were known.

The second phase [is taking place on the github](http://www.github.com/furrykef/dkdasm) and at the moment is concurrent with the first phase, so there's some merging back and forth. This phase consisted of replacing raw offsets with labels with descriptive names. Not only does this make the source easier to read, it also makes it possible to relocate RAM and ROM, which may be necessary for porting the game to other systems. We also cleaned up the source code in other respects.

Z80 code contributors:
* Jeff Wilms (phase 1)
* Kef Schecter (phase 2)
* An anonymous contributor (most of the initial work on phase 1)

i8035 code contributors:
* Kef Schecter

We would also like to thank the MAME team and other emulator authors for their insights that have made this project possible.
