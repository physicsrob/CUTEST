	include src/const.asm
	include src/entry.asm
	include src/macros.asm
	include src/config_pseudoports.asm
	include src/console.asm
	IFDEF USEVDM
	include src/vdm.asm
	ENDIF
	include src/startup.asm
	include src/command.asm
	include src/cassette.asm
	include src/memory.asm