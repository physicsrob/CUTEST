;
;
;           ENTR COMMAND
;
;   THIS ROUTINE GETS VALUES FROM THE KEYBOARD AND ENTERS
; THEM INTO MEMORY.  THE INPUT VALUES ARE SCANNED FOLLOWING
; A STANDARD 'read_line' INPUT SO ON-SCREEN EDITING MAY TAKE
; PLACE PRIOR TO THE LINE TERMINATOR.  A SLASH '/'
; ENds THE ROUTINE AND RETURNS CONTROL TO THE COMMAND MODE.
;
ENTER:	call	get_hex_arg	;SCAN OVER CHARS AND GET ADDRESS
	push	H	;SAVE ADDRESS
;
ENLOP:	call	write_crlf
	mvi	B,':'
	call	SOUT	;DSPLY THE COLON
	call	read_line	;INIT AND PROCESS A LINE
;
;
ENLO1:	mvi	C,3	;NO MORE THAN THREE SPACES BETWEEN VALUES
	call	find_non_blank1	;SCAN TO NEXT VALUE
	jz	ENLOP	;LAST ENTRY FOUND START NEW LINE
;
	cpi	'/'	;COMMAND TERMINATOR?
	jz	COMND	;if SO...
	call	hex_str_to_hl	;CONVERT VALUE
	cpi	':'	;ADDRESS TERMINATOR?
	jz	ENLO3	;GO PROCESS if SO
	mov	A,L	;GET LOW PART AS CONVERTED
	pop	H	;GET MEMORY ADDRESS
	mov	M,A	;PUT IN THE VALUE
	inx	H
	push	H	;BACK GOES THE ADDRESS
	jmp	ENLO1	;CONTINUE THE SCAN
;
ENLO3:	xthl		;PUT NEW ADDRESS ON STACK
	inx	D	;MOVE SCAN PAST TERMINATOR
	jmp	ENLO1
