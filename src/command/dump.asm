;
;
;
;
;           DUMP COMMAND
;
;     THIS ROUTINE DUMPS CHARACTERS FROM MEMORY TO THE
;  CURRENT OUTPUT DEVICE.
;  ALL VALUES ARE DESPLAYED AS ASCII HEX.
;
;  THE COMMAND FORM IS AS FOLLOWS:
;
;        DUMP  addr1  addr2
;
;    THE VALUES FROM addr1 TO addr2 ARE THEN OUTPUT TO THE
;  OUTPUT DEVICE.  IF ONLY addr1 IS SPECIFIED THEN THE
;  VALUE AT THAT ADDRESS IS OUTPUT.
;
;  IF WHILE DUMPING, THE MODE KEY IS PRESSED, THE DUMP WILL
;  BE TERMINATED.  IF THE SPACE BAR IS PRESSED, THE DUMP
;  WILL BE TEMPORARILY SUSPENDED UNTIL ANY KEY IS PRESSED.
;
	PUBLIC	dump_cmd_record

dump_cmd_record:
	db 'DU'
	dw DUMP

DUMP:	equ	$	;SET UP REGS TO DUMP SPECIFIED AREA
	call	get_hex_arg	;GET START addr (RequIRED)
	push	H	;SAVE THE START addr
	call	GET_OPT_HEX_ARG	;GET OPTIONAL END addr, HL=THIS OR START addr
	pop	D	;DE=START addr
	xchg		;DE=END addr, HL=START addr NOW
;
DLOOP:	call	write_crlf
	call	write_hex_pair	;OUTPUT ADDRESS
	call	BOUT	;ANOTHER SPACE TO KEEP IT PretTY
	mvi	C,16	;VALUES PER LINE
;
DLP1:	mov	A,M	;GET THE CHR
	push	B	;SAVE VALUE COUNT
	call	HBOUT	;SEND IT OUT WITH A BLANK
	mov	A,H	;CRNT ADDR
	cmp	D	;VERSUS ENDING ADDR
	jc	DLP1A	;NOT DONE YET
	mov	A,L	;TRY LOW ORDER BYTE
	cmp	E
	jnc	COMND	;ALL DONE WHEN CRNT REACHES ENDING

DLP1A:	equ	$	;HERE TO KEEP DUMPING
	pop	B	;VALUES PER LINE
	inx	H
	dcr	C	;BUMP THE LINE COUNT
	jnz	DLP1	;NOT ZERO IF MORE FOR THIS LINE
	jmp	DLOOP	;DO A LFCR BEFORE THE NEXT

HBOUT:	call	write_hex
	call	SINP	;SEE IF WE SHD ESCAPE FM DUMP
	jz	BOUT	;NO--ADD THE SPACE THEN
	ani	7FH	;MAKE SURE ITS CLEAR OF PARITY
	jz	COMND	;EITHER MODE (OR CTL-@)
	cpi	' '	;IS IT SPACE
	jnz	BOUT	;NO--IGNORE THE CHAR
WTLP1:	call	SINP	;ON SPACE, WAIT FOR ANY OTHER CHAR
	jz	WTLP1	;JUST LOOP AFTER A SPACE UNTIL ANY KEY PRESSED
BOUT:	mvi	B,' '
	jmp	SOUT	;PUT IT OUT