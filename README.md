# Compatibility with SOLOS/CUTER
I've worked hard to maintain compatibility with SOLOS/CUTER software.  The main way in which I did this was preserving the addresses of each entry point.  All the documented entry points in the SOLOS/CUTER manual have corresponding entry points in CUTEST.

# Memory Layout
## Original CUTER
- C000 - C7FF CUTER	    (2k)
- C800 - CBFF CUTER MEMORY  (1k)  
- CC00 - CFFF VDM Memory    (1k)


## Constraints
In order to pack in more feature (like the help menu), CUTEST needs more memory.  Rather than fitting in 2k like CUTER, CUTEST needs 4k.

Must haves:
- 4K of total ROM for CUTEST
- 1K of VDM-1 memory
- 1K of CUTEST memory

In addition, to maintain maximum compatibility, the entry points need to be the same as CUTER, which means the first 1K of CUTEST should be located at C000.

Nice to haves:
- C000 - C7FF CUTEST Base  (to ensure entry point compatibility with CUTER)
- CC00 - CFFF VDM-1 Memory (to ensure compatibility with any software writing directly to the VDM-1)

Unfortunately it's not possible to satisfy both nice-to-haves without breaking the ROM into two 2K chunks.

## Default CUTEST memory layout:

The best compromise to satisfy all of these needs:
- C000 - C7FF CUTEST BASE   (2k)	First 2K of ROM
- C800 - CBFF UNUSED        (1k)  
- CC00 - CFFF VDM Memory    (1k)
- D000 - D7FF CUTEST EXT    (2k)	Second 2K of ROM
- D800 - DFFF CUTEST MEMORY (2k)	CUTEST Memory.  Easily relocatable.

Other configurations are certainly possible, just change the layout in config.asm.



# Assembling
## Requirements

- Macro Assembler As [http://john.ccac.rwth-aachen.de:8000/as/]
- GNU Make _(recommended)_
- GNU objcopy _(recommended)_

To assemble cutest from source, all you need is Macro Assembler As [http://john.ccac.rwth-aachen.de:8000/as/].
The easiest way to assemble is to use the make script include (`Makefile`), but feel free to assemble by hand.

# Assembling
There is a single file, `src/cutest.asm`, which builds both the base image and the extension image.



