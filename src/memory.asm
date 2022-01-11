;       S Y S T E M   G L O B A L    A R E A
;
	org    START+1000H	;RAM STARTS 4k AFTER ROM START
;
START_RAM:	equ	$	;START OF SYSTEM RAM
TOP_OF_STACK:	equ	START_RAM+3FFH	;STACK WORKS FM TOP DOWN
;
;
;   PARAMETERS STORED IN RAM
;
USER_INP_PTR:	ds	2	;USER DEFINED INPUT RTN if NON ZERO
USER_OUT_PTR:	ds	2	;USER DEFINED OUTPUT RTN if NON ZERO
DFLTS:	ds	2	;DEFAULT PSUEDO I/O PORTS
IPORT:	ds	1	;CRNT INPUT PSUEDO PORT
OPORT:	ds	1	;CRNT OUTPUT PSUEDO PORT
NCHAR:	ds	1	;CURRENT CHARACTER POSITION
LINE:	ds	1	;CURRENT LINE POSITION
BOT:	ds	1	;BEGINNING OF TEXT DISPLACEMENT
SPEED:	ds	1	;SPEED CONTROL BYTE
ESCFL:	ds	1	;ESCAPE FLAG CONTROL BYTE
TSPD:	ds	1	;CURRENT TAPE SPEED
INPTR:	ds	2	;PTR TO NEXT CHAR POSITION in INLIN
NUCNT:	ds	1	;NUMBER OF NULLS AFTER CRLF 
IGNCR:	ds	1	;IGN CRC ERR FLAG, FF=IGN CRC ERRS, ELSE=NORMAL
;
	ds	10	;ROOM FOR FUTURE EXPANSION
;
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;    T H I S   I S   T H E   H E A D E R   L A Y O U T    *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
THEAD:	ds	5	;NAME
	ds	1	;THIS BYTE MUST BE ZERO
HTYPE:	ds	1	;TYPE
BLOCK:	ds	2	;BLOCK SIZE
LOADR:	ds	2	;LOAD ADDRESS
XEQAD:	ds	2	;AUTO EXECUTE ADDRESS
HSPR:	ds	3	;SPARES
;
HLEN:	equ	$-THEAD	;LENGTH OF HEADER
BLKOF:	equ	BLOCK-THEAD	;OFFSET TO BLOCK SIZE
DHEAD:	ds	HLEN	;A DUMMY HDR FOR COMPARES WHILE READING
;
;
CUSTOM_COMMAND_TAB:	ds	6*4	;ROOM FOR UP TO 6 CUSTOM USER COMMANDS
;
;
FNUMF:	ds	1	;FOR CURRENT FILE OPERATIONS
FCBAS:	ds	7	;1ST FILE CONTROL BLOCK
FCBA2:	ds	7	;2ND FILE CONTROL BLOCK
FBUF1:	ds	2*256	;SYSTEM FILE BUFFER BASE
	ds	1	;"BELL" (X'07') FLAGS START OF INPUT BFR
INLIN:	ds	80	;ROOM FOR THE INPUT LINE
USARE:	equ	$	;START OF USER AREA
;
;   REMEMBER THAT THE STACK WORKS ITS WAY DOWN-FROM
;   THE END OF THIS 1K RAM AREA.
;
; -*-
