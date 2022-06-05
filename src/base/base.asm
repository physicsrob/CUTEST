
	include entry.asm
	include utils.asm
	include console.asm
	ifdef USEVDM
	include vdm.asm
	endif
	include startup.asm
	include command/command.asm
	include cassette.asm
	if TAPE_DRIVER = "CUTS"
	include cuts.asm
	endif
	if TAPE_DRIVER = "TARBELL"
	include tarbell.asm
	endif
	include memory.asm
