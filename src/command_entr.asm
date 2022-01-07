;
;
;           ENTR COMMAND
;
;   THIS ROUTINE GETS VALUES FROM THE KEYBOARD AND ENTERS
; THEM INTO MEMORY.  THE INPUT VALUES ARE SCANNED FOLLOWING
; A STANDARD 'READ_LINE' INPUT SO ON-SCREEN EDITING MAY TAKE
; PLACE PRIOR TO THE LINE TERMINATOR.  A SLASH '/'
; ENDS THE ROUTINE AND RETURNS CONTROL TO THE COMMAND MODE.
;
ENTER:	CALL	GET_HEX_ARG	;SCAN OVER CHARS AND GET ADDRESS
	PUSH	H	;SAVE ADDRESS
;
ENLOP:	CALL	CRLF
	MVI	B,':'
	CALL	SOUT	;DSPLY THE COLON
	CALL	READ_LINE	;INIT AND PROCESS A LINE
	CALL	STUP	;SET UP TO PROCESS INPUT LINE
	; HL now contain a pointer to the line of data
	XCHG		; Move HL to DE
;
;
ENLO1:	MVI	C,3	;NO MORE THAN THREE SPACES BETWEEN VALUES
	CALL	FIND_NON_BLANK1	;SCAN TO NEXT VALUE
	JZ	ENLOP	;LAST ENTRY FOUND START NEW LINE
;
	CPI	'/'	;COMMAND TERMINATOR?
	JZ	COMND	;IF SO...
	CALL	HEX_STR_TO_HL	;CONVERT VALUE
	CPI	':'	;ADDRESS TERMINATOR?
	JZ	ENLO3	;GO PROCESS IF SO
	MOV	A,L	;GET LOW PART AS CONVERTED
	POP	H	;GET MEMORY ADDRESS
	MOV	M,A	;PUT IN THE VALUE
	INX	H
	PUSH	H	;BACK GOES THE ADDRESS
	JMP	ENLO1	;CONTINUE THE SCAN
;
ENLO3:	XTHL		;PUT NEW ADDRESS ON STACK
	INX	D	;MOVE SCAN PAST TERMINATOR
	JMP	ENLO1

