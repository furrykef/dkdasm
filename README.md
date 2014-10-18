# What this project is
A complete, commented disassembly of the arcade version of Donkey Kong. It is intended to easily be used by humans for any purpose.

At least, that's what we're aiming for. As it is, we've got quite a ways to go.


# What this project is not
We do not aim to modify the game in any way, not even to fix bugs (and there are a few!). Nothing stops you from making a fork and making whatever modifications you like, however, and in fact making this possible is part of our aim.


# Contributors
The disassembly process had two main phases.

This project [began life on the Donkey Kong Forum](http://donkeykongforum.com/index.php?topic=383.0). That led to an [entry on the Donkey Kong wiki](http://wiki.donkeykonggenius.com/Donkey_Kong_Code). These listings constitute the first phase of the project, where the bulk of the reverse engineering was done. By the end of the first phase, the purpose of most variables and routines were known.

The second phase [is taking place on the github](http://www.github.com/furrykef/dkdasm) and at the moment is concurrent with the first phase, so there's some merging back and forth. This phase consisted of replacing raw offsets with labels with descriptive names. Not only does this make the source easier to read, it also makes it possible to relocate RAM and ROM, which may be necessary for porting the game to other systems. We also cleaned up the source code in other respects.

Phase one contributors:
* Jeff Wilms
* At least one contributor who wishes to remain anonymous

Phase two contributors:
* Kef Schecter
