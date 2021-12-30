	ORG	0C000H
;
;
;   AUTO-STARTUP CODE
;
START:	MOV	A,A	;SHOW THIS IS CUTER (SOLOS=00)
;      THIS BYTE ALLOWS AUTOMATIC POWER ON ENTRY
;      WHEN IN ROM SUPPORTING THIS HARDWARE FEATURE.
INIT:	JMP	STRTA	;SYSTEM RESTART ENTRY POINT
;
;   THESE JUMP POINTS ARE PROVIDED TO ALLOW COMMON ENTRY
; LOCATIONS FOR ALL VERSIONS OF CUTER.  THEY ARE USED
; EXTENSIVELY BY CUTS SYSTEM PROGRAMS AND IT IS RECOMMENDED
; THAT USER ROUTINES ACCESS CUTER ROUTINES THROUGH THESE
; POINTS ONLY!
;
RETRN:	JMP	COMND	;RETURN TO CUTER COMMAND PROCESSOR
FOPEN:	JMP	BOPEN	;CASSETTE OPEN FILE ENTRY
FCLOS:	JMP	PCLOS	;CASSETTE CLOSE FILE ENTRY
RDBYT:	JMP	RTBYT	;CASSETTE READ BYTE ENTRY
WRBYT:	JMP	WTBYT	;CASSETTE WRITE BYTE ENTRY
RDBLK:	JMP	RTAPE	;CASSETTE READ BLOCK ENTRY
WRBLK:	JMP	WTAPE	;CASSETTE WRITE BLOCK ENTRY
;
;     SYSTEM I/O ENTRY POINTS
;
;  THESE FOUR ENTRY POINTS ARE USED TO EITHER INPUT
;  OR OUTPUT TO CUTER PSUEDO PORTS.
;  THESE PSUEDO PORTS ARE AS FOLLOWS:
;
;  PORT   INPUT              OUTPUT
;  ----   -----------------  ---------------------
;   0     KEYBOARD INPUT     BUILT-IN VDM DRIVER
;         ACTUAL PORT 3      PORT C8, MEMORY FROM CC00
;   1     SERIAL PORT        SERIAL PORT
;         ACTUAL PORT 10h    ACTUAL PORT 10h
;
;
;  NOTE: SOUT AND SINP ARE "LDA" INSTRUCTIONS.
;        THIS FACT IS USED TO ALLOW ACCESS TO THE
;        BYTES "OPORT" AND "IPORT" DYNAMICALLY.
;        THESE MUST REMAIN "LDA" INSTRUCTIONS!!!!!
;
SOUT:	LDA	OPORT	;OUTPUT VIA STANDARD OUTPUT PSUEDO PORT
AOUT:	JMP	OUTPR	;OUTPUT VIA PSUEDO PORT SPECIFIED IN REG A
SINP:	LDA	IPORT	;INPUT VIA STANDARD INPUT PSUEDO PORT
AINP:	EQU	$	;INPUT VIA PSUEDO PORT SPECIFIED IN REG A
; -----------END OF SYSTEM ENTRY POINTS----------
;
; AINP CONTINUES HERE -- IF AINP IS NOT THE NEXT CODE, WE NEED TO JMP THERE

