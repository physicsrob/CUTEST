
	include entry.asm
	include utils.asm
	include console.asm
	ifdef USEVDM
	include vdm.asm
	endif
	include startup.asm
	include command/command.asm
	include cassette.asm
	include memory.asm
