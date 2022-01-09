	include config/constants.asm
	include entry.asm
	include macros.asm
	include config/pseudoports.asm
	include config/commands.asm
	include console/console.asm
	IFDEF USEVDM
	include vdm.asm
	ENDIF
	include startup.asm
	include command/command.asm
	include cassette.asm
	include memory.asm