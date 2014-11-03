# Donkey Kong hacking kit

## What are these ASM files?
A complete, commented disassembly of the arcade version of Donkey Kong. It is intended to easily be used by humans for any purpose.

At least, that's what we're aiming for. As it is, we've got quite a ways to go.

In these files, we do not aim to modify the game in any way, not even to fix bugs (and there are a few!). Nothing stops you from making a fork and making whatever modifications you like, however, and in fact making this possible and practical is part of our aim.


## How do I use this stuff?
Well, at the moment, it's not very usable at all. But the documentation is on [the wiki](http://github.com/furrykef/dkdasm/wiki).


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
* Jeff Willms (phase 1)
* Kef Schecter (phase 2)
* An anonymous contributor (most of the initial work on phase 1)

i8035 code contributors:
* Kef Schecter

We would also like to thank the MAME team and other emulator authors for their insights that have made this project possible.
