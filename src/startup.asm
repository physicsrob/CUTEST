;
;
;
;                START UP SYSTEM
;
;   CLEAR SCREEN AND THE FIRST 256 BYTES OF GLOBAL RAM
;  THEN ENTER THE COMMAND MODE.
;
STRTA:	xra	A
	mov	C,A
	; Clear memory STARTing at DFLTS pointer
	; which is after custom user input/output rouTINEs.
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
	jnz	STRTB	;NO--DO NOT RESET VDM
	
	lxi	SP,TOP_OF_STACK	;set UP THE STACK FOR call
	call	ERASE_SCREEN	;(REG A ASSUMED TO COME BACK ZERO)
	endif
	
STRTB:	equ	$	;FINISH OFF THIS PORT THEN DO NEXT
	lxi	H,0	;USE FOR CLEARING USER ADDRESSES
	cpi	3	;IS IT A USER PORT
	jz	STRTC	;YES-- DO NOT CLEAR IT
	shld	USER_OUT_PTR	;NO--CLEAR addr
STRTC:	equ	$	;OUTPUT PORT ALL set
	mov	A,B	;FM SENSE SWITCHES
	rar
	rar		;NEXT 2 BITS ARE INPUT PORT
	ani	3	;VALID PORT
	sta	DFLTS	;THIS IS DEFAULT INPUT PORT
	cpi	3	;IS THIS ONE A USER PORT
	jz	STRTD	;YES--DO NOT CLEAR IT THEN
	shld	USER_INP_PTR	;NO--FORCE USER ADDRESS ZERO
STRTD:	equ	$	;1ST TIME INITIALIZATION ALL DONE NOW
	lhld	DFLTS	;PICK UP DEFAULT PORTS
	shld	IPORT	;FORCE PORTS TO DEFAULT
SRST:	equ	$	;RESET SERIAL PORT
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

	if STRINGS = TRUE
	ifdef BANNER
DISPLAY_BANNER: \
	jmp +
BANNER_STR: \
	db BANNER
	db 0
+:	lxi	H, BANNER_STR
	call	write_line
	endif
	endif

COMN1:	equ	$	;HERE TO TURN OFF TAPES, THEN COMMAND MODE
	xra	A
	OUT	TAPPT	;BE SURE TAPES ARE OFF

