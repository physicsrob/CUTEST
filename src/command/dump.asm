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
;        DUMP  ADDR1  ADDR2
;
;    THE VALUES FROM ADDR1 TO ADDR2 ARE THEN OUTPUT TO THE
;  OUTPUT DEVICE.  IF ONLY ADDR1 IS SPECIFIED THEN THE
;  VALUE AT THAT ADDRESS IS OUTPUT.
;
;  IF WHILE DUMPING, THE MODE KEY IS PRESSED, THE DUMP WILL
;  BE TERMINATED.  IF THE SPACE BAR IS PRESSED, THE DUMP
;  WILL BE TEMPORARILY SUSPENDED UNTIL ANY KEY IS PRESSED.
;
	PUBLIC	DUMP
DUMP:	EQU	$	;SET UP REGS TO DUMP SPECIFIED AREA
	CALL	GET_HEX_ARG	;GET START ADDR (REQUIRED)
	PUSH	H	;SAVE THE START ADDR
	CALL	GET_OPT_HEX_ARG	;GET OPTIONAL END ADDR, HL=THIS OR START ADDR
	POP	D	;DE=START ADDR
	XCHG		;DE=END ADDR, HL=START ADDR NOW
;
DLOOP:	CALL	CRLF
	CALL	ADOUT	;OUTPUT ADDRESS
	CALL	BOUT	;ANOTHER SPACE TO KEEP IT PRETTY
	MVI	C,16	;VALUES PER LINE
;
DLP1:	MOV	A,M	;GET THE CHR
	PUSH	B	;SAVE VALUE COUNT
	CALL	HBOUT	;SEND IT OUT WITH A BLANK
	MOV	A,H	;CRNT ADDR
	CMP	D	;VERSUS ENDING ADDR
	JC	DLP1A	;NOT DONE YET
	MOV	A,L	;TRY LOW ORDER BYTE
	CMP	E
	JNC	COMND	;ALL DONE WHEN CRNT REACHES ENDING

DLP1A:	EQU	$	;HERE TO KEEP DUMPING
	POP	B	;VALUES PER LINE
	INX	H
	DCR	C	;BUMP THE LINE COUNT
	JNZ	DLP1	;NOT ZERO IF MORE FOR THIS LINE
	JMP	DLOOP	;DO A LFCR BEFORE THE NEXT