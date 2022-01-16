
	include config/constants.asm
	include entry.asm
	include macros.asm
	include config/pseudoports.asm
	include debug.asm
	include utils.asm
	include console/console.asm
	ifdef USEVDM
	include vdm.asm
	endif
	include startup.asm
	include command/command.asm
	include cassette.asm
	include strings.asm
	include memory.asm