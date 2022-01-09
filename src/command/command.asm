	SECTION	COMMAND
	PUBLIC	COMND, DISPT
;
;
;
;            =--  COMMAND MODE  --=
;
;
;   THIS ROUTINE GETS AND PROCESSES COMMANDS
;
COMND:	LXI	SP,TOP_OF_STACK	;SET STACK POINTER
	CALL	PROMPT		;PUT PROMPT ON SCREEN
	CALL	READ_LINE	;INIT TO GET COMMAND LINE
	CALL	PROCESS_COMMAND	;PROCESS THE LINE
	JMP	COMND		;OVER AND OVER

;
;
;
;
;      FIND AND PROCESS COMMAND
;
PROCESS_COMMAND:	EQU	$	;PROCESS THIS COMMAND LINE
			LXI	H,START	;PREP SO THAT HL WILL PT TO CUTER LATER
			PUSH	H	;PLACE PTR TO CUTER ON STACK FOR LATER DISPT
			CALL	FIND_NON_BLANK	;SCAN PAST BLANKS
			JZ	ERROR_HANDLER		;NO COMMAND?
			XCHG		;HL HAS FIRST CHR
			IF STRINGS = TRUE
			LDAX	H
			CPI	'?'
			JNZ	+
			LXI	H, HELP
			XTHL
			RET
			ENDIF
+:			LXI	D,COMTAB	;POINT TO COMMAND TABLE
			CALL	FIND_CMD	;SEE IF IN PRIMARY TABLE
			CZ	FIND_CUSTOM_CMD	;TRY CUSTOM ONLY IF NOT PRIMARY COMMAND
; **** DROP THRU TO DISPT ***


;
; THIS ROUTINE DISPTACHES TO THE ADDR AT CONTENTS OF HL.
; Assumed that previous HL was pushed to the stack, and
; we restore the previous value before calling the routine.
;
DISP0:	EQU	$	;HERE TO EITHER DISPATCH OR DO ERROR
	JZ	ERROR_HANDLER		;NOT IN EITHER TABLE
	INX	D	;PT DE TO ADDR OF RTN
	XCHG		;HL=ADDR OF ADDR OF RTN
DISPT:	EQU	$	;DISPATCH
	MOV	A,M	;LOW BYTE
	INX	H
	MOV	H,M	;HI BYTE
	MOV	L,A	;AND LO, HL NOW COMPLETE
	XTHL		;HL RESTORED AND ADDR ON STACK
	MOV	A,L	;ALWAYS PASS L IN "A" (PRIMARILY FOR SET'S)
	
	; This following RET is a bit confusing since 
	; we're not returning from a subroutine. Instead,
	; we're jumping to the dispatch address which is
	; now top of the stack and HL is now the value
	; pushed to the stack before calling dispatch
	RET		;OFF TO ROUTINE

; --- Find Command Subroutine ---
;
;   This routine searches through a table, pointed to
;  by DE, for a double character match of the string
;  point to by HL. If no match is found the scan ends
;  with the zero flag set, else non-zero set.
;
;  FIND_CUSTOM_CMD -- Search through CUSTOM_COMMAND_TAB
;  FIND_CMD -- Search through table loaded in DE
; -------------------------------
FIND_CUSTOM_CMD:	\
	LXI	D,CUSTOM_COMMAND_TAB	
FIND_CMD:	\
	LDAX	D	; Load
	ORA	A	;TEST FOR TABLE END
	RZ		;NOT FOUND POST THAT AND RETURN
	PUSH	H	;SAVE START OF SCAN ADDRESS
	CMP	M	;TEST FIRST CHR
	INX	D
	JNZ	NCOM
;
	INX	H
	LDAX	D
	CMP	M	;NOW SECOND CHARACTER
	JNZ	NCOM	;GOODNESS
;
	POP	H	;RETURN HL TO PT TO CHAR START
	ORA	A	;FORCE TO NON-ZERO FLAG
	RET		;LET CALLER KNOW
;
;
NCOM:	INX	D	;GO TO NEXT ENTRY
	INX	D
	INX	D
	POP	H	;GET BACK ORIGINAL ADDRESS
	JMP	FIND_CMD	;CONTINUE SEARCH
;
;           COMMAND TABLE
;
;  THIS TABLE DESCRIBES THE VALID COMMANDS FOR CUTER
;
COMTAB: \
	EQU	$	;START OF KNOWN COMMANDS
	GET_COMTAB_ENTRY 0
	GET_COMTAB_ENTRY 1
	GET_COMTAB_ENTRY 2
	GET_COMTAB_ENTRY 3
	GET_COMTAB_ENTRY 4
	GET_COMTAB_ENTRY 5
	GET_COMTAB_ENTRY 6
	GET_COMTAB_ENTRY 7
	GET_COMTAB_ENTRY 8
	GET_COMTAB_ENTRY 9
	GET_COMTAB_ENTRY 10
	GET_COMTAB_ENTRY 11
	GET_COMTAB_ENTRY 12
	GET_COMTAB_ENTRY 13
	GET_COMTAB_ENTRY 14
	GET_COMTAB_ENTRY 15
	DB	0	;END OF TABLE MARK
;
;
;       SECONDARY COMMAND TABLE FOR SET COMMAND
;
SETAB:	DB	'TA'	;SET TAPE SPEED
	DW	TASPD
	DB	'S='	;SET DISPLAY SPEED
	DW	DISPD
	DB	'I='	;SET INPUT PORT
	DW	SETIN
	DB	'O='	;SET OUTPUT PORT
	DW	SETOT
	DB	'CI'	;SET CUSTOM DRIVER ADDRESS
	DW	SETCI
	DB	'CO'	;SET CUSTOM OUTPUT DRIVER ADDRESS
	DW	SETCO
	DB	'XE'	;SET HEADER XEQ ADDRESS
	DW	SETXQ
	DB	'TY'	;SET HEADER TYPE
	DW	SETTY
	DB	'N='	;SET NUMBER OF NULLS
	DW	SETNU
	DB	'CR'	;SET CRC (NORMAL OR IGNORE CRC ERRORS)
	DW	SETCR
	DB	0	;END OF TABLE MARK
; -*-
;
;
;      OUTPUT A CRLF FOLLOWED BY A PROMPT
;
PROMPT: \
	CALL	CRLF
	MVI	B,'>'	;THE PROMPT
	JMP	SOUT	;PUT IT ON THE SCREEN

;
;
; FIND_NEXT_ARG
; This routine will scan until it find the first blank character,
; and then once a blank character is identified, it will continue
; to scan until a non-blank is identified.  This is the first
; character of the next argument in the command.
; Arguments:
;	DE - Set to input buffer
; Returns:
;	zero flag set if it was unable to find another argument
;	zero flag not set if found another argu
; Returns non-zero if it has found another argument.
; 	The address of the argument will be loaded in DE 
FIND_NEXT_ARG:	\
	MVI	C,12	;MAXIMUM COMMAND STRING
-:	LDAX	D
	CPI	BLANK
	JZ	FIND_NON_BLANK	;GOT A BLANK NOW SCAN PAST IT
	INX	D
	CPI	'='	;A EQUAL WILL ALSO STOP US (AT NEXT CHAR)
	JZ	FIND_NON_BLANK	;FOUND, DE PT TO NEXT CHAR
	DCR	C	;NO MORE THAN TWELVE
	JNZ	-
	RET		;GO BACK WITH ZERO FLAG SET
;
;
;  SCAN PAST UP TO 10 BLANK POSITIONS LOOKING FOR
; A NON BLANK CHARACTER.
;
FIND_NON_BLANK:	\
	MVI	C,10	;SCAN TO FIRST NON BLANK CHR WITHIN 10
FIND_NON_BLANK1:	\
	LDAX	D	;GET NEXT CHARACTER
	CPI	SPACE
	RNZ		;WE'RE PAST THEM
	INX	D	;NEXT SCAN ADDRESS
	DCR	C
	RZ		;COMMAND ERROR
	JMP	FIND_NON_BLANK1	;KEEP LOOPING
;
; GET_HEX_ARG
; This routine find the next argument, converts it from hex,
; and stores the results in HL.  On error we call the error handler.
; Arguments:
;   DE - Pointer to input buffer
; Returns:
;   Hex value stored into H/L
GET_HEX_ARG:	\
	CALL	FIND_NEXT_ARG
	JZ	ERROR_HANDLER

;
; HEX_STR_TO_HL
; THIS ROUTINE CONVERTS ASCII DIGITS INTO BINARY FOLLOWING
; A STANDARD HEX CONVERSION.  THE SCAN STOPS WHEN AN ASCII
; SPACE IS ENCOUNTERED.  PARAMETER ERRORS REPLACE THE ERROR
; CHARACTER ON THE SCREEN WITH A QUESTION MARK.
; Arguments:
;    DE - Pointer to string
; Returns:
;    Hex valued into H/L
HEX_STR_TO_HL: \
	LXI	H,0	;CLEAR H & L
-:	LDAX	D	;GET CHARACTER
	CPI	20H	;IS IT A SPACE?
	RZ		;IF SO
	CPI	'/'
	RZ
	CPI	':'
	RZ

	; DAD H Adds HL to HL, thus shifting left one bit	
	; We shift left four bits.
	DAD	H
	DAD	H
	DAD	H
	DAD	H
	CALL	+	;DO THE CONVERSION
	JNC	ERROR_HANDLER	;NOT VALID HEXIDECIMAL VALUE
	ADD	L
	MOV	L,A	;MOVE IT IN
	INX	D	;BUMP THE POINTER
	JMP	-
;
+:	SUI	48	;REMOVE ASCII BIAS
	CPI	10
	RC		;IF LESS THAN 9
	SUI	7	;IT'S A LETTER??
	CPI	10H
	RET		;WITH TEST IN HAND
;
; GET_OPT_HEX_ARG
; THIS ROUTINE WILL SEE IF A FIELD (OPERAND) IS PRESENT.
; IF NOT, THEN HL WILL REMAIN AS THEY WERE ON ENTRY.
; IF IT WAS PRESENT, THEN HL=THAT VALUE IN HEX.
;
GET_OPT_HEX_ARG: \
	CALL	FIND_NEXT_ARG	;SEE IF FIELD IS PRESENT
	RZ		;RETURN LEAVING HL AS THEY WERE ON ENTRY
	CALL	HEX_STR_TO_HL	;FIELD IS THERE, GO GET IT
	RET		;HL= EITHER OPTIONAL FIELD (HEX), OR AS IT WAS
	
; ---Error Handler Subroutine ---
; Both of these labels are for handling a command syntax error.
; 
; ERROR_HANDLER_DE - de contains pointer to the syntax error
; ERROR_HANDLER_HL - hl contains pointer to the syntax error
;
; -------------------------------
ERROR_HANDLER:	\
	CALL	CRLF
	MVI	B,'?'	;SET UP THE ????
	CALL	SOUT	;INDICATE INPUT NOT VALID
	JMP	COMND	;NOW READY FOR NEXT INPUT




	include dump.asm
	include entr.asm
	include exec.asm
	include cassette.asm
	include set.asm
	include custom.asm
	IF STRINGS=TRUE
	include help.asm
	ENDIF
	ENDSECTION COMMAND

