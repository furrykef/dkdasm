## What this project is
A complete, commented disassembly of the arcade version of Donkey Kong. It is intended to easily be used by humans for any purpose.

At least, that's what we're aiming for. As it is, we've got quite a ways to go.


## What this project is not
We do not aim to modify the game in any way, not even to fix bugs (and there are a few!). Nothing stops you from making a fork and making whatever modifications you like, however, and in fact making this possible and practical is part of our aim.


## Donkey Kong hardware
Donkey Kong has two main processors: a Z80 CPU and an i8035 microcontroller sound CPU. (Technically, the sound CPU is an MB8884, but it is essentially the same chip.) The sound CPU handles all music and several sound effects, but the sounds of Mario walking and jumping and the "boom" sound effect are handled entirely using discrete logic, and so cannot be modified by software.


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
