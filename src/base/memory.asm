;       S Y S T E M   G L O B A L    A R E A
;
	org    MEM_ADDRESS
;
TOP_OF_STACK:	equ	MEM_ADDRESS + MEM_SIZE - 1
;
;
;   PARAMETERS STORED IN RAM
;
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
inhex_port: ds 1
inhex_sum: ds 1
SETHELP_CMD: ds 2

;
	ds	6	;ROOM FOR FUTURE EXPANSION
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
COMMAND_TAB_LEN: equ 32
COMMAND_TAB:	ds 4*COMMAND_TAB_LEN
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