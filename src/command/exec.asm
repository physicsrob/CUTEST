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
	PUBLIC	EXEC
EXEC:	call	get_hex_arg	;SCAN PAST BLANKS AND GET PARAMETER
EXEC1:	equ	$	;HERE TO GO TO HL
	push	H	;SAVE ON STACK
	lxi	H,START	;LET USER KNOW WHERE WE ARE
	ret		;AND OFF TO USER
;
;
;
;
;   THIS ROUTINE GETS A NAME OF UP TO 5 CHARACTERS
;  FROM THE INPUT STRING.  if THE TERMINATOR IS A
;  SLASH (/) THEN THE CHARACTER FOLLOWING IS TAKEN
;  AS THE CASSETTE UNIT SPECIFICATION.
;
;
NAME0:	equ	$	;ENTER HERE TO set HL TO THEAD
	lxi	H,THEAD	;PT WHERE TO PUT NAME
NAME:	call	find_next_arg	;SCAN OVER TO FIRST CHRS
	mvi	B,6
;
NAME1:	ldax	D	;GET CHARACTER
	cpi	' '	;NO UNIT DELIMITER
	jz	NFIL
	cpi	'/'	;UNIT DELIMITER
	jz	NFIL
	mov	M,A
	inx	D	;BUMP THE SCAN POINTER
	inx	H
	dcr	B
	jnz	NAME1	;NAME IS OK, FALL THRU TO 'error_handler_DE' if NOT
	jmp	error_handler
;
;
;
;  HERE WE HAVE SCANNED OFF THE NAME. ZERO FILL in FOR
;  NAMES LESS THAN FIVE CHARACTERS.
;
NFIL:	mvi	M,0	;PUT IN AT LEAST ONE ZERO
	inx	H
	dcr	B
	jnz	NFIL	;LOOP UNTIL B IS ZERO
;
	cpi	'/'	;IS THERE A UNIT SPECIFICATION?
	mvi	A,1	;PretEND NOT
	jnz	DEFLT
	inx	D	;MOVE PAST THE TERMINATOR
	call	find_non_blank	;GO GET IT
	sui	'0'	;REMOVE ASCII BIAS
;
DEFLT:	equ	$	;CNVRT TO INTERNAL BIT FOR TAPE CONTROL
	ani	1	;JUST BIT ZERO
	mvi	A,TAPE1	;ASSUME TAPE ONE
	jnz	STUNT	;if NON ZERO, IT IS ONE
	rar		;ELSE MAKE IT TAPE TWO
STUNT:	sta	FNUMF	;set IT IN
	ret
