
	outradix 10

pre    set $
	include config/constants.asm
	MESSAGE "      prev \{$ - pre}"
pre    set $
	include entry.asm
	MESSAGE "      prev \{$ - pre}"
pre    set $
	include macros.asm
	MESSAGE "      prev \{$ - pre}"
pre    set $
	include config/pseudoports.asm
	MESSAGE "      prev \{$ - pre}"
pre    set $
	include debug.asm
	MESSAGE "      prev \{$ - pre}"
pre    set $
	include utils.asm
	MESSAGE "      prev \{$ - pre}"
pre    set $
	;include config/commands.asm
	include console/console.asm
	MESSAGE "      prev \{$ - pre}"
pre    set $
	ifdef USEVDM
	include vdm.asm
	endif
	MESSAGE "      prev \{$ - pre}"
pre    set $
	include startup.asm
	MESSAGE "      prev \{$ - pre}"
pre    set $
	include command/command.asm
	MESSAGE "      prev \{$ - pre}"
pre    set $
	include cassette.asm
	MESSAGE "      prev \{$ - pre}"
pre    set $
	include strings.asm
	MESSAGE "      prev \{$ - pre}"
pre    set $
	include memory.asm