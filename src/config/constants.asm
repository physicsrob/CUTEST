
;
;
;    S Y S T E M    E Q U A T E S
;
;
BASE_ADDRESS:	equ	0C000H

;          VDM PARAMETERS
;
VDM_MEM:      	equ	0CC00H	;VDM SCREEN MEMORY
VDM_STAT_PORT:	equ	0C8H	;VDM CONTROL PORT
;
;
;            KEYBOARD SPECIAL KEY ASSIGNMENTS
;
;  THESE DEFINITIONS ARE DESIGNED TO ALLOW
;  COMPATABILITY WITH SOLOS(TM). THESE ARE THE
;  SAME KEYS WITH BIT 7 (X'80') STRIPPED OFF.
;
DOWN:	equ	1AH	;CTL Z
UP:	equ	17H	;CTL W
LEFT:	equ	01H	;CTL A
RIGHT:	equ	13H	;CTL S
CLEAR:	equ	0BH	;CTL K
HOME:	equ	0EH	;CTL N
MODE:	equ	00H	;CTL-@
BACKS:	equ	5FH	;BACKSPACE
LF:	equ	10
CR:	equ	13
BLANK:	equ	' '
SPACE:	equ	BLANK
CX:	equ	'X'-40H
ESC:	equ	1BH
;
;          PORT ASSIGNMENTS
;


TAPPT:	equ	0FAH	;TAPE STATUS PORT
TDATA:	equ	0FBH	;TAPE DATA PORT
SENSE:	equ	0FFH	;SENSE SWITCHES

;
;
;          BIT ASSIGNMENT MASKS
;
TFE:	equ	8	;TAPE FRAMING ERROR
TOE:	equ	16	;TAPE OVERFLOW ERROR
TDR:	equ	64	;TAPE DATA READY
TTBE:	equ	128	;TAPE TRANSMITTER BUFFER EMPTY
;
SOK:	equ	1	;SCROLL OK FLAG
;
TAPE1:	equ	80H	;1=TURN TAPE ONE ON
TAPE2:	equ	40H	;1=TURN TAPE TWO ON


STRINGS:      equ    False
BANNER:       equ    'Welcome to CUTEST'
