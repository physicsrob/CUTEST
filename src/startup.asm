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
	IN	SENSE	;GET SWITCHES
;
	mov	B,A	;SAVE IT
	ani	3	;MAKE IT A VALID PORT
	sta	DFLTS+1	;set DEFAULT OUTPUT PORT
	
	ifdef USEVDM 
	ora	A	;SEE if THIS THE VDM
	jnz	startup_b	;NO--DO NOT RESET VDM
	
	lxi	SP,TOP_OF_STACK	;set UP THE STACK FOR call
	call	ERASE_SCREEN	;(REG A ASSUMED TO COME BACK ZERO)
	endif

startup_b:	
	mov	A,B	;FM SENSE SWITCHES
	rar
	rar		;NEXT 2 BITS ARE INPUT PORT
	ani	3	;VALID PORT
	sta	DFLTS	;THIS IS DEFAULT INPUT PORT
	cpi	3	;IS THIS ONE A USER PORT
startup_d:
	lhld	DFLTS	;PICK UP DEFAULT PORTS
	shld	IPORT	;FORCE PORTS TO DEFAULT
	
	ifdef setup_0
	setup_0
	endif
	ifdef setup_1
	setup_1
	endif
	ifdef setup_2
	setup_2
	endif
	ifdef setup_3
	setup_3
	endif

; 	if STRINGS = TRUE
; 	ifdef BANNER
; display_banner: \
; 	jmp +
; BANNER_STR: \
; 	db BANNER
; 	db 0
; +:	lxi	H, BANNER_STR
; 	call	write_line
; 	endif
; 	endif

COMN1:	equ	$	;HERE TO TURN OFF TAPES, THEN COMMAND MODE
	xra	A
	OUT	TAPPT	;BE SURE TAPES ARE OFF

	;
	; Setup command table
	;
	; TODO make a memset util
	; Reset command tab to zeros
	lxi H, COMMAND_TAB
	lxi D, COMMAND_TAB_LEN
	mvi B, 0
	call memset
	call load_cmd_tab
