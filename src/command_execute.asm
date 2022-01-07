;
;
;              EXECUTE COMMAND
;
;   THIS ROUTINE GETS THE FOLLOWING PARAMETER AND DOES A
; PROGRAM JUMP TO THE LOCATION GIVEN BY IT.  IF PROPER
; STACK OPERATIONS ARE USED WITHIN THE EXTERNAL PROGRAM
; IT CAN DO A STANDARD 'RET'URN TO THE CUTER COMMAND MODE.
;
;
EXEC:	CALL	GET_HEX_ARG	;SCAN PAST BLANKS AND GET PARAMETER
EXEC1:	EQU	$	;HERE TO GO TO HL
	PUSH	H	;SAVE ON STACK
	LXI	H,START	;LET USER KNOW WHERE WE ARE
	RET		;AND OFF TO USER
;
;
;
;
;   THIS ROUTINE GETS A NAME OF UP TO 5 CHARACTERS
;  FROM THE INPUT STRING.  IF THE TERMINATOR IS A
;  SLASH (/) THEN THE CHARACTER FOLLOWING IS TAKEN
;  AS THE CASSETTE UNIT SPECIFICATION.
;
;
NAME0:	EQU	$	;ENTER HERE TO SET HL TO THEAD
	LXI	H,THEAD	;PT WHERE TO PUT NAME
NAME:	CALL	FIND_NEXT_ARG	;SCAN OVER TO FIRST CHRS
	MVI	B,6
;
NAME1:	LDAX	D	;GET CHARACTER
	CPI	' '	;NO UNIT DELIMITER
	JZ	NFIL
	CPI	'/'	;UNIT DELIMITER
	JZ	NFIL
	MOV	M,A
	INX	D	;BUMP THE SCAN POINTER
	INX	H
	DCR	B
	JNZ	NAME1	;NAME IS OK, FALL THRU TO 'ERR1' IF NOT
;
;     CUTER ERROR HANDLER
;
ERR1:	XCHG		;GET SCAN ADDRESS
ERR2:	MVI	M,'?'	;FLAG THE ERROR
	LDA	OPORT	;SEE IF VIA VDM DRIVER
	ORA	A
	JZ	COMND	;YES--VDM SCREEN NOW HAS THE ?
	CALL	CRLF
	MVI	B,'?'	;SET UP THE ????
	CALL	SOUT	;INDICATE INPUT NOT VALID
	JMP	COMND	;NOW READY FOR NEXT INPUT
;
;
;
;  HERE WE HAVE SCANNED OFF THE NAME. ZERO FILL IN FOR
;  NAMES LESS THAN FIVE CHARACTERS.
;
NFIL:	MVI	M,0	;PUT IN AT LEAST ONE ZERO
	INX	H
	DCR	B
	JNZ	NFIL	;LOOP UNTIL B IS ZERO
;
	CPI	'/'	;IS THERE A UNIT SPECIFICATION?
	MVI	A,1	;PRETEND NOT
	JNZ	DEFLT
	INX	D	;MOVE PAST THE TERMINATOR
	CALL	FIND_NON_BLANK	;GO GET IT
	SUI	'0'	;REMOVE ASCII BIAS
;
DEFLT:	EQU	$	;CNVRT TO INTERNAL BIT FOR TAPE CONTROL
	ANI	1	;JUST BIT ZERO
	MVI	A,TAPE1	;ASSUME TAPE ONE
	JNZ	STUNT	;IF NON ZERO, IT IS ONE
	RAR		;ELSE MAKE IT TAPE TWO
STUNT:	STA	FNUMF	;SET IT IN
	RET
