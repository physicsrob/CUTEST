;
;
;              EXECUTE COMMAND
;
;   THIS ROUTINE GETS THE FOLLOWING PARAMETER AND DOES A
; PROGRAM JUMP TO THE LOCATION GIVEN BY IT.  if PROPER
; STACK OPERATIONS ARE USED WITHin THE EXTERNAL PROGRAM
; IT CAN DO A STANDARD 'ret'URN TO THE CUTER COMMAND MODE.
;
;
EXEC:	call	get_hex_arg	;SCAN PAST BLANKS AND GET PARAMETER
EXEC1:	equ	$	;HERE TO GO TO HL
	push	H	;SAVE ON STACK
	lxi	H,START	;LET USER KNOW WHERE WE ARE
	ret		;AND OFF TO USER
