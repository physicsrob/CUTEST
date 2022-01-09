
;
;
;    S Y S T E M    E Q U A T E S
;
;
BASE_ADDRESS:	EQU	0C000H

;          VDM PARAMETERS
;
VDM_MEM:      	EQU	0CC00H	;VDM SCREEN MEMORY
VDM_STAT_PORT:	EQU	0C8H	;VDM CONTROL PORT
;
;
;            KEYBOARD SPECIAL KEY ASSIGNMENTS
;
;  THESE DEFINITIONS ARE DESIGNED TO ALLOW
;  COMPATABILITY WITH SOLOS(TM). THESE ARE THE
;  SAME KEYS WITH BIT 7 (X'80') STRIPPED OFF.
;
DOWN:	EQU	1AH	;CTL Z
UP:	EQU	17H	;CTL W
LEFT:	EQU	01H	;CTL A
RIGHT:	EQU	13H	;CTL S
CLEAR:	EQU	0BH	;CTL K
HOME:	EQU	0EH	;CTL N
MODE:	EQU	00H	;CTL-@
BACKS:	EQU	5FH	;BACKSPACE
LF:	EQU	10
CR:	EQU	13
BLANK:	EQU	' '
SPACE:	EQU	BLANK
CX:	EQU	'X'-40H
ESC:	EQU	1BH
;
;          PORT ASSIGNMENTS
;


TAPPT:	EQU	0FAH	;TAPE STATUS PORT
TDATA:	EQU	0FBH	;TAPE DATA PORT
SENSE:	EQU	0FFH	;SENSE SWITCHES

;
;
;          BIT ASSIGNMENT MASKS
;
TFE:	EQU	8	;TAPE FRAMING ERROR
TOE:	EQU	16	;TAPE OVERFLOW ERROR
TDR:	EQU	64	;TAPE DATA READY
TTBE:	EQU	128	;TAPE TRANSMITTER BUFFER EMPTY
;
SOK:	EQU	1	;SCROLL OK FLAG
;
TAPE1:	EQU	80H	;1=TURN TAPE ONE ON
TAPE2:	EQU	40H	;1=TURN TAPE TWO ON


STRINGS:      EQU    TRUE
BANNER:       EQU    'Welcome to CUTEST'
