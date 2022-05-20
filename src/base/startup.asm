;
;
;
;                START UP SYSTEM
;
;   CLEAR SCREEN AND THE FIRST 256 BYTES OF GLOBAL RAM
;  THEN ENTER THE COMMAND MODE.
;
startup_a:	xra	A
	mov	C,A
	; Clear memory STARTing at DFLTS pointer
	; which is after custom user input/output routines.
	lxi	H,DFLTS	
;
-:	mov	M,A
	inx	H
	inr	C
	jnz	-
;
; DETERMINE THE DEFAULT PORTS
;     THIS COULD BECOME "mvi A,XX" FOR YOUR SPECIFIC PORTS
	IN	SENSE_PORT	;GET SWITCHES
;
	ani	3	;MAKE IT A VALID PORT
	mov	B,A	;SAVE IT

	sta	DFLTS+1	;SET DEFAULT OUTPUT PORT
	
	ifdef USEVDM 
	ora	A	;SEE if THIS THE VDM
	jnz	startup_b	;NO--DO NOT RESET VDM
	
	lxi	SP,TOP_OF_STACK	;SET UP THE STACK FOR call
	call	ERASE_SCREEN	;(REG A ASSUMED TO COME BACK ZERO)
	endif

startup_b:	
	mov	A,B	;FM SENSE_PORT SWITCHES
	rar
	rar		;NEXT 2 BITS ARE INPUT PORT
	ani	3	;VALID PORT
	sta	DFLTS	;THIS IS DEFAULT INPUT PORT
	cpi	3	;IS THIS ONE A USER PORT
startup_d:
	lhld	DFLTS	;PICK UP DEFAULT PORTS
	shld	IPORT	;FORCE PORTS TO DEFAULT
	
	setup_routine 0
	setup_routine 1
	setup_routine 2
	setup_routine 3

	;
	; Setup command table
	;
	; Reset command tab to zeros
	lxi H, COMMAND_TAB
	lxi D, COMMAND_TAB_LEN
	mvi B, 0
	call memset
	
	lxi h, builtin_cmd_tab
	mvi b, 8
	call register_command_tab


	;
	; Look for extension, and autoexec it
	;
	if AUTOLOAD_EXT = True
	lxi h, EXT_ADDRESS
	mvi a, EXTENSION_ID
	cmp m
	cz EXT_ADDRESS 
	endif

COMN1:
	; Jump here to turn off tapes then command mode
	call cassette_tape_off
