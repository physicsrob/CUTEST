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
COMND:	lxi	SP,TOP_OF_STACK	;set STACK POINTER
	call	PROMPT		;PUT PROMPT ON SCREEN
	call	read_line	;INIT TO GET COMMAND LINE
	call	PROCESS_COMMAND	;PROCESS THE LINE
	jmp	COMND		;OVER AND OVER

;
;
;
;
;      FIND AND PROCESS COMMAND
;
PROCESS_COMMAND:	equ	$	;PROCESS THIS COMMAND LINE
			lxi	H,START	;PREP SO THAT HL WILL PT TO CUTER LATER
			push	H	;PLACE PTR TO CUTER ON STACK FOR LATER DISPT
			call	FIND_NON_BLANK	;SCAN PAST BLANKS
			jz	ERROR_HANDLER		;NO COMMAND?
			xchg		;HL HAS FIRST CHR
			if STRINGS = TRUE
			ldax	H
			cpi	'?'
			jnz	+
			lxi	H, HELP
			xthl
			ret
			endif
+:			lxi	D,COMTAB	;POINT TO COMMAND TABLE
			call	FIND_CMD	;SEE if in PRIMARY TABLE
			CZ	FIND_CUSTOM_CMD	;TRY CUSTOM ONLY if NOT PRIMARY COMMAND
; **** DROP THRU TO DISPT ***


;
; THIS ROUTINE DISPTACHES TO THE addr AT CONTENTS OF HL.
; Assumed that previous HL was pushed to the stack, and
; we restore the previous value before calling the rouTINE.
;
DISP0:	equ	$	;HERE TO EITHER DISPATCH OR DO ERROR
	jz	ERROR_HANDLER		;NOT in EITHER TABLE
	inx	D	;PT DE TO addr OF RTN
	xchg		;HL=addr OF addr OF RTN
DISPT:	equ	$	;DISPATCH
	mov	A,M	;LOW BYTE
	inx	H
	mov	H,M	;HI BYTE
	mov	L,A	;AND LO, HL NOW COMPLETE
	xthl		;HL RESTORED AND addr ON STACK
	mov	A,L	;ALWAYS PASS L in "A" (PRIMARILY FOR set'S)
	
	; This following ret is a bit confusing since 
	; we're not RETURNing from a Subroutine. Instead,
	; we're jumping to the dispatch ADDRESS which is
	; now top of the stack and HL is now the value
	; pushed to the stack before calling dispatch
	ret		;OFF TO ROUTINE

; --- Find Command Subroutine ---
;
;   This rouTINE searches through a table, pointed to
;  by DE, for a double character match of the string
;  point to by HL. if no match is found the scan ends
;  with the zero flag set, else non-zero set.
;
;  FIND_CUSTOM_CMD -- Search through CUSTOM_COMMAND_TAB
;  FIND_CMD -- Search through table loaded in DE
; -------------------------------
FIND_CUSTOM_CMD:	\
	lxi	D,CUSTOM_COMMAND_TAB	
FIND_CMD:	\
	ldax	D	; Load
	ora	A	;TEST FOR TABLE END
	rz		;NOT FOUND POST THAT AND RETURN
	push	H	;SAVE START OF SCAN ADDRESS
	cmp	M	;TEST FIRST CHR
	inx	D
	jnz	NCOM
;
	inx	H
	ldax	D
	cmp	M	;NOW SECOND CHARACTER
	jnz	NCOM	;GOODNESS
;
	pop	H	;RETURN HL TO PT TO CHAR START
	ora	A	;FORCE TO NON-ZERO FLAG
	ret		;LET callER KNOW
;
;
NCOM:	inx	D	;GO TO NEXT ENTRY
	inx	D
	inx	D
	pop	H	;GET BACK ORIGINAL ADDRESS
	jmp	FIND_CMD	;CONTINUE SEARCH
;
;           COMMAND TABLE
;
;  THIS TABLE DESCRIBES THE VALID COMMANDS FOR CUTER
;
COMTAB: \
	equ	$	;START OF KNOWN COMMANDS
	get_comtab_entry 0
	get_comtab_entry 1
	get_comtab_entry 2
	get_comtab_entry 3
	get_comtab_entry 4
	get_comtab_entry 5
	get_comtab_entry 6
	get_comtab_entry 7
	get_comtab_entry 8
	get_comtab_entry 9
	get_comtab_entry 10
	get_comtab_entry 11
	get_comtab_entry 12
	get_comtab_entry 13
	get_comtab_entry 14
	get_comtab_entry 15
	db	0	;END OF TABLE MARK
;
;
;       SECONDARY COMMAND TABLE FOR set COMMAND
;
setAB:	db	'TA'	;set TAPE SPEED
	dw	TASPD
	db	'S='	;set DISPLAY SPEED
	dw	DISPD
	db	'I='	;set INPUT PORT
	dw	setIN
	db	'O='	;set OUTPUT PORT
	dw	setOT
	db	'CI'	;set CUSTOM DRIVER ADDRESS
	dw	setCI
	db	'CO'	;set CUSTOM OUTPUT DRIVER ADDRESS
	dw	setCO
	db	'XE'	;set HEADER XEQ ADDRESS
	dw	setXQ
	db	'TY'	;set HEADER TYPE
	dw	setTY
	db	'N='	;set NUMBER OF NULLS
	dw	setNU
	db	'CR'	;set CRC (NOrmAL OR IGNORE CRC ERRORS)
	dw	setCR
	db	0	;END OF TABLE MARK
; -*-
;
;
;      OUTPUT A CRLF FOLLOWED BY A PROMPT
;
PROMPT: \
	call	write_crlf
	mvi	B,'>'	;THE PROMPT
	jmp	SOUT	;PUT IT ON THE SCREEN

;
;
; FIND_NEXT_ARG
; This rouTINE will scan until it find the first blank character,
; and then once a blank character is identified, it will continue
; to scan until a non-blank is identified.  This is the first
; character of the next argument in the command.
; Arguments:
;	DE - set to input buffer
; RETURNs:
;	zero flag set if it was unable to find another argument
;	zero flag not set if found another argu
; RETURNs non-zero if it has found another argument.
; 	The ADDRESS of the argument will be loaded in DE 
FIND_NEXT_ARG:	\
	mvi	C,12	;MAXIMUM COMMAND STRING
-:	ldax	D
	cpi	BLANK
	jz	FIND_NON_BLANK	;GOT A BLANK NOW SCAN PAST IT
	inx	D
	cpi	'='	;A equAL WILL ALSO STOP US (AT NEXT CHAR)
	jz	FIND_NON_BLANK	;FOUND, DE PT TO NEXT CHAR
	dcr	C	;NO MORE THAN TWELVE
	jnz	-
	ret		;GO BACK WITH ZERO FLAG set
;
;
;  SCAN PAST UP TO 10 BLANK POSITIONS LOOKING FOR
; A NON BLANK CHARACTER.
;
FIND_NON_BLANK:	\
	mvi	C,10	;SCAN TO FIRST NON BLANK CHR WITHin 10
FIND_NON_BLANK1:	\
	ldax	D	;GET NEXT CHARACTER
	cpi	SPACE
	rnz		;WE'RE PAST THEM
	inx	D	;NEXT SCAN ADDRESS
	dcr	C
	rz		;COMMAND ERROR
	jmp	FIND_NON_BLANK1	;KEEP LOOPING
;
; GET_HEX_ARG
; This rouTINE find the next argument, converts it from hex,
; and stores the results IN HL.  On error we call the error handler.
; Arguments:
;   DE - Pointer to input buffer
; RETURNs:
;   Hex value stored into H/L
GET_HEX_ARG:	\
	call	FIND_NEXT_ARG
	jz	ERROR_HANDLER

;
; HEX_STR_TO_HL
; THIS ROUTINE CONVERTS ASCII DIGITS INTO BINARY FOLLOWING
; A STANDARD HEX CONVERSION.  THE SCAN STOPS WHEN AN ASCII
; SPACE IS ENCOUNTERED.  PARAMETER ERRORS REPLACE THE ERROR
; CHARACTER ON THE SCREEN WITH A QUESTION MARK.
; Arguments:
;    DE - Pointer to string
; RETURNs:
;    Hex valued into H/L
HEX_STR_TO_HL: \
	lxi	H,0	;CLEAR H & L
-:	ldax	D	;GET CHARACTER
	cpi	20H	;IS IT A SPACE?
	rz		;if SO
	cpi	'/'
	rz
	cpi	':'
	rz

	; dad H adds HL to HL, thus shifting left one bit	
	; We shift left four bits.
	dad	H
	dad	H
	dad	H
	dad	H
	call	+	;DO THE CONVERSION
	jnc	ERROR_HANDLER	;NOT VALID HEXIDECIMAL VALUE
	add	L
	mov	L,A	;movE IT IN
	inx	D	;BUMP THE POINTER
	jmp	-
;
+:	SUI	48	;REmovE ASCII BIAS
	cpi	10
	RC		;if LESS THAN 9
	SUI	7	;IT'S A LETTER??
	cpi	10H
	ret		;WITH TEST in HAND
;
; GET_OPT_HEX_ARG
; THIS ROUTINE WILL SEE if A FIELD (OPERAND) IS PRESENT.
; if NOT, THEN HL WILL REMAIN AS THEY WERE ON ENTRY.
; if IT WAS PRESENT, THEN HL=THAT VALUE in HEX.
;
GET_OPT_HEX_ARG: \
	call	FIND_NEXT_ARG	;SEE if FIELD IS PRESENT
	rz		;RETURN LEAVING HL AS THEY WERE ON ENTRY
	call	HEX_STR_TO_HL	;FIELD IS THERE, GO GET IT
	ret		;HL= EITHER OPTIONAL FIELD (HEX), OR AS IT WAS
	
; ---Error Handler Subroutine ---
; Both of these labels are for handling a command syntax error.
; 
; ERROR_HANDLER_DE - de contains pointer to the syntax error
; ERROR_HANDLER_HL - hl contains pointer to the syntax error
;
; -------------------------------
ERROR_HANDLER:	\
	call	write_crlf
	mvi	B,'?'	;set UP THE ????
	call	SOUT	;INDICATE INPUT NOT VALID
	jmp	COMND	;NOW READY FOR NEXT INPUT




	include dump.asm
	include entr.asm
	include exec.asm
	include cassette.asm
	include set.asm
	include custom.asm
	if STRINGS=TRUE
	include help.asm
	endif
	ENdsECTION COMMAND

